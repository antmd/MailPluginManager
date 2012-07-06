//
//  MBAppDelegate.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 07/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MPCAppDelegate.h"
#import "NSViewController+LKCollectionItemFix.h"
#import "MPCMailBundle.h"
#import "MPCCompanyList.h"
#import "MPCUUIDList.h"

#import "SUBasicUpdateDriver.h"
#import "MPCSparkleAsyncOperation.h"
#import "MPCScheduledUpdateDriver.h"
#import "MPCPluginUpdater.h"

@interface MPCAppDelegate ()

@property	(nonatomic, retain)	NSOperationQueue		*counterQueue;
@property	(nonatomic, retain)	NSOperationQueue		*maintenanceQueue;
@property	(nonatomic, retain)	NSOperationQueue		*activityQueue;
@property	(nonatomic, retain)	NSOperationQueue		*finalizeQueue;

@property	(nonatomic, copy)	NSMutableArray			*bundleSparkleOperations;

@property	(nonatomic, assign, readonly)	BOOL		collectInstalls;

//	App delegation
- (void)applicationChangeForNotification:(NSNotification *)note;

//	Maintenance Task Management
- (void)addOperation:(NSOperation *)operation forQueueNamed:(NSString *)aQueueName;
- (void)activityIsWaitingToHappen;
- (void)finalizeIsWaitingToHappen;

//	Bundle Updating
- (BOOL)testForMailBundleChanges;
- (void)installAnyMailBundlesPending;
- (void)completeBundleUpdate:(NSNotification *)note;

@end


@implementation MPCAppDelegate

@synthesize bundleUninstallObserver = _bundleUninstallObserver;

@synthesize window = _window;
@synthesize collectionItem = _collectionItem;
@synthesize bundleViewController = _bundleViewController;
@synthesize mailBundleList = _mailBundleList;
@synthesize currentController = _currentController;

@synthesize isMailRunning = _isMailRunning;

@synthesize backgroundView = _backgroundView;
@synthesize scrollView = _scrollView;
@synthesize quitButton = _quitButton;
@synthesize quittingIndicator = _quitingIndicator;
@synthesize quittingNotice = _quittingNotice;

@synthesize counterQueue = _counterQueue;
@synthesize maintenanceQueue = _maintenanceQueue;
@synthesize activityQueue = _activityQueue;
@synthesize finalizeQueue = _finalizeQueue;
@synthesize finalizeQueueRequiresExplicitRelease = _finalizeQueueRequiresExplicitRelease;

@synthesize bundleSparkleOperations = _bundleSparkleOperations;


#pragma mark - Memory Management

- (id)init {
	self = [super init];
	if (self) {
		
		//	operation array
		_bundleSparkleOperations = [[NSMutableArray alloc] init];

		//	Create new operation queues to use for task types
		_maintenanceQueue = [[NSOperationQueue alloc] init];
		[_maintenanceQueue setName:@"com.littleknownsoftware.MPCMaintenanceQueue"];
		_maintenanceQueue.maxConcurrentOperationCount = 1;	//	Makes this serial queue, in effect
		_counterQueue = [[NSOperationQueue alloc] init];
		[_counterQueue setName:@"com.littleknownsoftware.MPCCounterQueue"];
		_counterQueue.maxConcurrentOperationCount = 1;	//	Makes this serial queue, in effect
		_activityQueue = [[NSOperationQueue alloc] init];
		[_activityQueue setName:@"com.littleknownsoftware.MPCActivityQueue"];
		_activityQueue.maxConcurrentOperationCount = 1;	//	Makes this serial queue, in effect
		_activityQueue.suspended = YES;
		_finalizeQueue = [[NSOperationQueue alloc] init];
		[_finalizeQueue setName:@"com.littleknownsoftware.MPCFinalizeQueue"];
		_finalizeQueue.maxConcurrentOperationCount = 1;	//	Makes this serial queue, in effect
		_finalizeQueue.suspended = YES;
		
		_finalizeQueueRequiresExplicitRelease = YES;
		_finalizedQueueReleased = NO;
		
	}
	
	return self;
}

- (void)dealloc {
	//	Remove the observations this class is doing.
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.bundleSparkleOperations = nil;
	
	//	Release our controller
	self.currentController = nil;
	self.mailBundleList = nil;
	self.bundleViewController = nil;
	
	self.maintenanceQueue = nil;
	self.counterQueue = nil;
	self.activityQueue = nil;
	self.finalizeQueue = nil;
	
	[super dealloc];
}



#pragma mark - Accessors

- (BOOL)collectInstalls {
	return NO;
}


#pragma mark - Application Delegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	//	Set a key-value observation on the running apps for "Mail"
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationChangeForNotification:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationChangeForNotification:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	
	//	Set default for mail is running
	for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
		if ([[app bundleIdentifier] isEqualToString:kMPCMailBundleIdentifier]) {
			self.isMailRunning = YES;
		}
	}
	
	//	Load the process to put in place our uuids file
	[self addMaintenanceTask:^{
		[MPCUUIDList loadListFromCloud];
	}];
	
	//	Load the process to put in place our companies file
	[self addMaintenanceTask:^{
		[MPCCompanyList loadListFromCloud];
	}];

	//	Add this method to the finalize before the Sparkle Update for the Manager
	LKLog(@"Adding bundle installer cleanup to Finalize queue");
	[self addFinalizeTask:^{
		[self installAnyMailBundlesPending];
	}];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	LKLog(@"Activity Count:%d  Finalize Count:%d", [self.activityQueue operationCount], [self.finalizeQueue operationCount]);
	if (([self.activityQueue operationCount] > 0) || ([self.finalizeQueue operationCount] > 0)) {
		return NSTerminateCancel;
	}
	return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	if (self.bundleUninstallObserver != nil) {
		[[NSNotificationCenter defaultCenter] removeObserver:self.bundleUninstallObserver];
		self.bundleUninstallObserver = nil;
	}
}

- (void)applicationChangeForNotification:(NSNotification *)note {
	//	If this is Mail
	if ([[[[note userInfo] valueForKey:NSWorkspaceApplicationKey] bundleIdentifier] isEqualToString:kMPCMailBundleIdentifier]) {
		//	See if it launched or terminated
		self.isMailRunning = [[note name] isEqualToString:NSWorkspaceDidLaunchApplicationNotification];
		//	Post a notification for other observers to have a simplified notification
		[[NSNotificationCenter defaultCenter] postNotificationName:kMPCMailStatusChangedNotification object:[NSNumber numberWithBool:self.isMailRunning]];
	}
}


#pragma mark - Window Management

- (void)showCollectionWindowForBundles:(NSArray *)bundleList {
	
	//	Show a view for multiples
	self.bundleViewController = [[[NSViewController alloc] initWithNibName:@"MPCBundleView" bundle:nil] autorelease];
	[self.bundleViewController configureForCollectionItem:self.collectionItem];
	
	//	Set our bundle list, using the recommended sorting order
	self.mailBundleList = [bundleList sortedArrayUsingDescriptors:[MPCMailBundle bestBundleSortDescriptors]];
	
	//	Adjust the view & window sizes, if there should only be a single row
	[self adjustWindowSizeForBundleList:bundleList animate:NO];
	
	[[self window] center];
	[[self window] makeKeyAndOrderFront:self];
	
	//	Add notification to quit when the window is closed
	[[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:[self window] queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		[self quittingNowIsReasonable];
	}];
}

- (void)adjustWindowSizeForBundleList:(NSArray *)bundleList animate:(BOOL)animate {
	
	//	If the size is already equivalent to one controller height, just leave (test that it is less than 1.5 of a controller)
	if ([self.scrollView frame].size.height < (1.5f * [[self.bundleViewController view] frame].size.height)) {
		return;
	}
	
	//	Adjust the view & window sizes, if there should only be a single row
	CGFloat	bundleHeightAdjust = (-1.0 * [[self.bundleViewController view] frame].size.height);
	if ([self.mailBundleList count] <= (NSUInteger)([self.scrollView frame].size.width / [[self.bundleViewController view] frame].size.width)) {
		//	Adjust the window, scrollview and background image size.
		NSRect	windowFrame = LKRectByAdjustingHeight([[self window] frame], bundleHeightAdjust);
		if (animate) {
			[NSAnimationContext beginGrouping];
			[[NSAnimationContext currentContext] setDuration:0.3f];
			windowFrame = LKRectByOffsettingY(windowFrame, (-1.0f * (bundleHeightAdjust / 2.f)));
		}
		[(animate?[[self window] animator]:[self window]) setFrame:windowFrame display:NO];
		[(animate?[self.scrollView animator]:self.scrollView) setFrame:LKRectByAdjustingHeight([self.scrollView frame], bundleHeightAdjust)];
		[(animate?[self.backgroundView animator]:self.backgroundView) setFrame:LKRectByAdjustingHeight([self.backgroundView frame], bundleHeightAdjust)];
		if (animate) {
			[NSAnimationContext endGrouping];
		}
	}
	
}


#pragma mark - Actions

- (IBAction)showURL:(id)sender {
	if ([sender respondsToSelector:@selector(toolTip)]) {
		NSURL	*aURL = [NSURL URLWithString:[sender toolTip]];
		if (aURL) {
			[[NSWorkspace sharedWorkspace] openURL:aURL];
		}
	}
}

- (IBAction)finishApplication:(id)sender {
	self.quitButton.enabled = NO;
	self.quittingIndicator.hidden = NO;
	[self.quittingIndicator startAnimation:self];
	[self.quittingNotice setStringValue:NSLocalizedString(@"Cleaning up and moving files into place before quitting.", @"Text indicating to user that we are cleaning up before quitting")];
	self.quittingNotice.hidden = NO;

	//	Indicate that we can quit, *then* release the activity && finalize queues
	[self quittingNowIsReasonable];
	[self releaseActivityQueue];
	[self releaseFinalizeQueue];
	
}



#pragma mark - Support Methods

- (BOOL)quitMail {
	
	//	If it's not running, just return success
	if (!self.isMailRunning) {
		return YES;
	}
	
	//	Using the workspace, doesn't work for a restart
	NSRunningApplication	*mailApp = nil;
	for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
		if ([[app bundleIdentifier] isEqualToString:kMPCMailBundleIdentifier]) {
			mailApp = app;
		}
	}
	return [mailApp terminate];
}

- (void)restartMailExecutingBlock:(MPCAsyncRestartBlock)taskBlock {
	
	//	If it is not running return
	if (!self.isMailRunning) {
		//	Perform the task first
		if (taskBlock != nil) {
			[self addActivityTask:^{
				taskBlock();
			}];
		}
	}
	else {
		MPCRestartAsyncOperation	*operation = [[[MPCRestartAsyncOperation alloc] initWithTaskBlock:taskBlock] autorelease];
		[self addFinalizeOperation:operation];
	}
}


- (BOOL)askToRestartMailWithBlock:(void (^)(void))taskBlock usingIcon:(NSImage *)iconImage {
	__block BOOL	mailWasRestartedOrNotRunning = NO;
	if (AppDel.isMailRunning) {
		static dispatch_once_t onceTokenMailRestart;
		dispatch_once(&onceTokenMailRestart, ^{
			LKLog(@"Restarting Mail");
			//	If so, ask user to quit it
			NSString	*messageText = NSLocalizedString(@"I need to restart Mail to finish.", @"Description of why Mail needs to be quit.");
			NSString	*infoText = NSLocalizedString(@"Clicking 'Restart Mail' will complete this action. Clicking 'Quit Mail Later' will let you delay this until later.", @"Details about how the buttons work.");
			
			NSString	*defaultButton = NSLocalizedString(@"Restart Mail", @"Button text to quit mail");
			NSString	*altButton = NSLocalizedString(@"Quit Mail Later", @"Button text to quit myself");
			NSAlert		*quitMailAlert = [NSAlert alertWithMessageText:messageText defaultButton:defaultButton alternateButton:altButton otherButton:nil informativeTextWithFormat:infoText];
			if (iconImage != nil) {
				[quitMailAlert setIcon:iconImage];
			}
			else {
				[quitMailAlert setIcon:[[NSWorkspace sharedWorkspace] iconForFile:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:kMPCMailBundleIdentifier]]];
			}
			LKLog(@"Alert built");
			
			//	Throw this back onto the main queue
			__block NSUInteger	mailResult;
			dispatch_sync(dispatch_get_main_queue(), ^{
				mailResult = [quitMailAlert runModal];
			});
			
			//	If they said yes, restart
			if (mailResult == NSAlertDefaultReturn) {
				//	Otherwise restart mail and return as a finalize task
				[self restartMailExecutingBlock:taskBlock];
				mailWasRestartedOrNotRunning = YES;
			}
		});
	}
	return mailWasRestartedOrNotRunning;
}

- (id)changePluginManagerDefaultValue:(id)value forKey:(NSString *)key {
	
	id	currentValue = nil;
	
	NSMutableDictionary	*changeDefaults = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:kMPCMailPluginManagerBundleID] mutableCopy];
	currentValue = [changeDefaults valueForKey:key];
	if ((value == nil) || (value == [NSNull null])) {
		[changeDefaults removeObjectForKey:key];
	}
	else {
		[changeDefaults setValue:value forKey:key];
	}
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:changeDefaults forName:kMPCMailPluginManagerBundleID];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[changeDefaults release];
	
	return currentValue;
}



#pragma mark - Bundle Updating

- (void)updateMailBundle:(MPCMailBundle *)mailBundle force:(BOOL)flag {
	
	//	If the bundle doesn't support sparkle, just send a done notification and return
	if (![mailBundle supportsSparkleUpdates]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kMPCDoneUpdatingMailBundleNotification object:mailBundle];
		return;
	}
	
	//	Simply use the standard Sparkle behavior (with an instantiation via the bundle)
	SUUpdater	*updater = [MPCPluginUpdater updaterForBundle:mailBundle.bundle];
	if (updater) {
		
		//	Create our driver manually, so that we have a copy to store
		MPCScheduledUpdateDriver	*updateDriver = [[[MPCScheduledUpdateDriver alloc] initWithUpdater:updater] autorelease];
		updateDriver.shouldCollectInstalls = self.collectInstalls;
		
		//	Set a delegate
		MPCSparkleDelegate	*sparkleDelegate = [[[MPCSparkleDelegate alloc] initWithMailBundle:mailBundle] autorelease];
		mailBundle.sparkleDelegate = sparkleDelegate;
		[updater setDelegate:sparkleDelegate];
		
		//	Only start the update if the schedule requires it
		if (flag || [updateDriver isPastSchedule]) {
			//	Then create an operation to run the action
			MPCSparkleAsyncOperation	*sparkleOperation = [[[MPCSparkleAsyncOperation alloc] initWithUpdateDriver:updateDriver updater:updater] autorelease];
			[self.bundleSparkleOperations addObject:[NSDictionary dictionaryWithObjectsAndKeys:updateDriver, @"driver", sparkleOperation, @"operation", sparkleDelegate, @"delegate", mailBundle, @"bundle", nil]];
			
			//	Set an observer for the bundle
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(completeBundleUpdate:) name:kMPCDoneUpdatingMailBundleNotification object:mailBundle];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(completeBundleUpdate:) name:kMPCSUUpdateDriverAbortNotification object:updateDriver];
			
			LKLog(@"Update Scheduled");
			[self addActivityOperation:sparkleOperation];
		}
		else {
			[self addActivityTask:^{
				//	A simple task to ensure that the activity queue is sparked to run
				LKLog(@"Running the dummy activity task");
			}];
		}
	}
}

- (BOOL)testForMailBundleChanges {
	if (!IsEmpty(self.mailBundleList)) {
		BOOL	restartMail = NO;
		//	Check to see if any of those need a mail restart
		for (MPCMailBundle *bundle in self.mailBundleList) {
			restartMail = restartMail || bundle.needsMailRestart;
		}
		
		//	If we need to restart, do it.
		if (restartMail) {
			return [self askToRestartMailWithBlock:nil usingIcon:nil];
		}
	}
	return NO;
}


- (void)installAnyMailBundlesPending {
	
	NSArray	*ops = [[self.bundleSparkleOperations retain] autorelease];
	self.bundleSparkleOperations = nil;
	MPCMailBundle	*lastBundle = nil;
	LKLog(@"Finishing Installs");
	for (NSDictionary *opDict in ops) {
		SUBasicUpdateDriver	*ud = [opDict valueForKey:@"driver"];
		LKLog(@"Finishing Install for '%@'", [[[opDict valueForKey:@"bundle"] path] lastPathComponent]);
		[ud installWithToolAndRelaunch:NO];
		lastBundle = [opDict valueForKey:@"bundle"];
	}
	
	//	Then do the Mail restart if necessary
	if (lastBundle != nil) {
		LKLog(@"Need to restart Mail");
		//	Test to see if Mail is running
		NSImage	*iconImage = [[NSWorkspace sharedWorkspace] iconForFile:lastBundle.path];
		[self askToRestartMailWithBlock:nil usingIcon:iconImage];
	}
}

- (void)completeBundleUpdate:(NSNotification *)note {
	NSDictionary	*theDict = nil;
	if ([[note name] isEqualToString:kMPCDoneUpdatingMailBundleNotification ]) {
		LKLog(@"Should be completing op for bundle '%@'", [[[note object] path] lastPathComponent]);
		for (NSDictionary *aDict in self.bundleSparkleOperations) {
			if ([[aDict valueForKey:@"bundle"] isEqual:[note object]]) {
				theDict = aDict;
				((MPCMailBundle *)[note object]).updateWaiting = YES;
				break;
			}
		}
	}
	else if ([[note name] isEqualToString:kMPCSUUpdateDriverAbortNotification]) {
		//	Find which updater we're working with
		for (NSDictionary *aDict in self.bundleSparkleOperations) {
			if ([[aDict valueForKey:@"driver"] isEqual:[note object]]) {
				theDict = aDict;
				break;
			}
		}
		//	Then remove it from the list
		if (theDict != nil) {
			theDict = [[theDict retain] autorelease];
			[self.bundleSparkleOperations removeObject:theDict];
		}
	}
	//	Remove observers
	if (theDict != nil) {
		[[theDict valueForKey:@"operation"] finish];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:kMPCSUUpdateDriverAbortNotification object:[note object]];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:kMPCDoneUpdatingMailBundleNotification object:[note object]];
	}
}




#pragma mark - Queue Management

#pragma mark Add Operations

- (void)addMaintenanceTask:(void (^)(void))block {
	
	NSBlockOperation	*main = [NSBlockOperation blockOperationWithBlock:block];
	[self addMaintenanceOperation:main];
}

- (void)addMaintenanceOperation:(NSOperation *)operation {
	[self addOperation:operation forQueueNamed:@"Maintenance"];
}

- (void)addActivityTask:(void (^)(void))block {
	
	NSBlockOperation	*main = [NSBlockOperation blockOperationWithBlock:block];
	[self addActivityOperation:main];
}

- (void)addActivityOperation:(NSOperation *)operation {
	[self addOperation:operation forQueueNamed:@"Activity"];
}

- (void)addFinalizeTask:(void (^)(void))block {
	
	NSBlockOperation	*main = [NSBlockOperation blockOperationWithBlock:block];
	[self addFinalizeOperation:main];
}

- (void)addFinalizeOperation:(NSOperation *)operation {
	[self addOperation:operation forQueueNamed:@"Finalize"];
}


#pragma mark Indicate Actions Waiting


- (void)releaseActivityQueue {
	[self activityIsWaitingToHappen];
}

- (void)releaseFinalizeQueue {
	@synchronized (_finalizeQueue) {
		_finalizedQueueReleased = YES;
	}
}

- (void)quittingNowIsReasonable {
	
	static dispatch_once_t onceTokenQuitting;
	dispatch_once(&onceTokenQuitting, ^{
		
		dispatch_queue_t	globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_source_t	timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, globalQueue);
		
		LKLog(@"quitting timer being set");

		//	Create the timer and set it to repeat every half second
		dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 200ull*NSEC_PER_MSEC, 5000ull);
		dispatch_source_set_event_handler(timer, ^{
			LKLog(@"Testing quit:MaintQ:%d, ActQ:%d,  FinalQ:%d", [self.maintenanceQueue operationCount], [self.activityQueue operationCount], [self.finalizeQueue operationCount]);
			if (([self.maintenanceQueue operationCount] == 0) &&
				(![self.activityQueue isSuspended] && ([self.activityQueue operationCount] == 0)) && 
				(![self.finalizeQueue isSuspended] && ([self.finalizeQueue operationCount] == 0))) {

				LKLog(@"Calling testForMailBundleChanges");
				if ([self testForMailBundleChanges]) {
					//	User is restarting mail, let that happen
					return;
				}
				dispatch_source_cancel(timer);
				dispatch_release(timer);
				LKLog(@"Quitting from the NowReasonable method");
				[NSApp terminate:nil];
			}
		});
		//	Start it
		dispatch_resume(timer);
		
	});
}

- (void)activityIsWaitingToHappen {
	
	static dispatch_once_t onceTokenActivity;
	dispatch_once(&onceTokenActivity, ^{
		
		dispatch_queue_t	globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_source_t	timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, globalQueue);
		
		//	Create the timer and set it to repeat every half second
		dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 500ull*NSEC_PER_MSEC, 5000ull);
		dispatch_source_set_event_handler(timer, ^{
			if ([self.maintenanceQueue operationCount] == 0) {
				dispatch_source_cancel(timer);
				dispatch_release(timer);
				self.activityQueue.suspended = NO;
				LKLog(@"Activities Unsuspended");
			}
		});
		//	Start it
		dispatch_resume(timer);
		
	});
}

- (void)finalizeIsWaitingToHappen {
	
	static dispatch_once_t onceTokenFinalize;
	dispatch_once(&onceTokenFinalize, ^{
		
		dispatch_queue_t	globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_source_t	timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, globalQueue);
		
		//	Create the timer and set it to repeat every half second
		dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 500ull*NSEC_PER_MSEC, 5000ull);
		dispatch_source_set_event_handler(timer, ^{
			if ((!self.finalizeQueueRequiresExplicitRelease || 
				 (self.finalizeQueueRequiresExplicitRelease && _finalizedQueueReleased)) && 
				(![self.activityQueue isSuspended] &&
				 ([self.activityQueue operationCount] == 0))) {
				dispatch_source_cancel(timer);
				dispatch_release(timer);
				self.finalizeQueue.suspended = NO;
				LKLog(@"Finalize Unsuspended");
			}
		});
		//	Start it
		dispatch_resume(timer);
		
	});
}



#pragma mark - Internal Queue Management

- (void)addOperation:(NSOperation *)operation forQueueNamed:(NSString *)aQueueName {
	
	//	Make the values for the queue
	SEL	queueSelector = NSSelectorFromString([NSString stringWithFormat:@"%@Queue", [aQueueName lowercaseString]]);
	SEL	goSelector = NSSelectorFromString([NSString stringWithFormat:@"%@IsWaitingToHappen", [aQueueName lowercaseString]]);
	
	//	Ensure that we have a queue
	if (![self respondsToSelector:queueSelector]) {
		LKErr(@"Found an invalid selector for the queue '%@' - queueSel:%s", aQueueName, queueSelector);
		return;
	}
	NSOperationQueue	*aQueue = [self performSelector:queueSelector];
	if (aQueue == nil) {
		LKErr(@"Queue not found for '%@'", aQueueName);
		return;
	}
	
	//	Then add the operation
	[aQueue addOperations:[NSArray arrayWithObjects:operation, nil] waitUntilFinished:NO];
	//	And indicate that the queue should be started when ready, if the selector exists
	if ([self respondsToSelector:goSelector]) {
		LKLog(@"Calling selector %s", goSelector);
		[self performSelector:goSelector];
	}
}


@end
