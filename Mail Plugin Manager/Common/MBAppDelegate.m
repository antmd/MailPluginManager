//
//  MBAppDelegate.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 07/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MBAppDelegate.h"
#import "NSViewController+LKCollectionItemFix.h"
#import "MBMMailBundle.h"
#import "MBMCompanyList.h"
#import "MBMUUIDList.h"

//#import <Sparkle/Sparkle.h>
#import "SUBasicUpdateDriver.h"
#import "MPMSparkleAsyncOperation.h"

@interface MBAppDelegate ()

@property	(nonatomic, retain)	NSOperationQueue			*activityQueue;
@property	(atomic, assign)	NSInteger					activityCounter;
@property	(nonatomic, retain)	NSOperationQueue			*finalizeQueue;
@property	(atomic, assign)	NSInteger					finalizeCounter;

@property	(nonatomic, copy)	NSMutableArray				*bundleSparkleOperations;

//	App delegation
- (void)applicationChangeForNotification:(NSNotification *)note;

//	Maintenance Task Management
- (void)addOperation:(NSOperation *)operation forQueueNamed:(NSString *)aQueueName;
- (void)activityIsWaitingToHappen;
- (void)finalizeIsWaitingToHappen;

//	Bundle Updating
- (void)installAnyMailBundlesPending;
- (void)completeBundleUpdate:(NSNotification *)note;

@end


@implementation MBAppDelegate

@synthesize bundleUninstallObserver = _bundleUninstallObserver;

@synthesize window = _window;
@synthesize collectionItem = _collectionItem;
@synthesize bundleViewController = _bundleViewController;
@synthesize mailBundleList = _mailBundleList;
@synthesize currentController = _currentController;

@synthesize isMailRunning = _isMailRunning;
@synthesize counterQueue = _counterQueue;
@synthesize maintenanceQueue = _maintenanceQueue;
@synthesize maintenanceCounter = _maintenanceCounter;

@synthesize backgroundView = _backgroundView;
@synthesize scrollView = _scrollView;

@synthesize activityQueue = _activityQueue;
@synthesize activityCounter = _activityCounter;
@synthesize finalizeQueue = _finalizeQueue;
@synthesize finalizeCounter = _finalizeCounter;
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
		_maintenanceQueue.maxConcurrentOperationCount = 1;	//	Makes this serial queue, in effect
		_counterQueue = [[NSOperationQueue alloc] init];
		_counterQueue.maxConcurrentOperationCount = 1;	//	Makes this serial queue, in effect
		_activityQueue = [[NSOperationQueue alloc] init];
		_activityQueue.maxConcurrentOperationCount = 1;	//	Makes this serial queue, in effect
		_activityQueue.suspended = YES;
		_finalizeQueue = [[NSOperationQueue alloc] init];
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
	
	self.activityQueue = nil;
	self.finalizeQueue = nil;
	
	[super dealloc];
}



#pragma mark - Application Delegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	//	Set a key-value observation on the running apps for "Mail"
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationChangeForNotification:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationChangeForNotification:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	
	//	Set default for mail is running
	for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
		if ([[app bundleIdentifier] isEqualToString:kMBMMailBundleIdentifier]) {
			self.isMailRunning = YES;
		}
	}
	
	//	Load the process to put in place our uuids file
	[self addMaintenanceTask:^{
		[MBMUUIDList loadListFromCloud];
	}];
	
	//	Load the process to put in place our companies file
	[self addMaintenanceTask:^{
		[MBMCompanyList loadListFromCloud];
	}];

	//	Add this method to the finalize before the Sparkle Update for the Manager
	LKLog(@"Adding bundle installer cleanup to Finalize queue");
	[self addFinalizeTask:^{
		[self installAnyMailBundlesPending];
	}];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	
	if (!IsEmpty(self.mailBundleList)) {
		BOOL	restartMail = NO;
		//	Check to see if any of those need a mail restart
		for (MBMMailBundle *bundle in self.mailBundleList) {
			restartMail = restartMail || bundle.needsMailRestart;
		}
		
		//	If we need to restart, do it.
		if (restartMail) {
			[self askToRestartMailWithBlock:nil usingIcon:nil];
			return NSTerminateLater;
		}
	}
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
	if ([[[[note userInfo] valueForKey:NSWorkspaceApplicationKey] bundleIdentifier] isEqualToString:kMBMMailBundleIdentifier]) {
		//	See if it launched or terminated
		self.isMailRunning = [[note name] isEqualToString:NSWorkspaceDidLaunchApplicationNotification];
		//	Post a notification for other observers to have a simplified notification
		[[NSNotificationCenter defaultCenter] postNotificationName:kMBMMailStatusChangedNotification object:[NSNumber numberWithBool:self.isMailRunning]];
	}
}

/*
- (void)quittingNowIsReasonable {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		dispatch_queue_t	globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_source_t	timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, globalQueue);
		
		//	Create the timer and set it to repeat every half second
		dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 500ull*NSEC_PER_MSEC, 5000ull);
		dispatch_source_set_event_handler(timer, ^{
			if (([self.maintenanceQueue operationCount] == 0) && (self.maintenanceCounter == 0)) {
				dispatch_source_cancel(timer);
				dispatch_release(timer);
				[NSApp terminate:nil];
			}
		});
		//	Start it
		dispatch_resume(timer);
		
	});
}
*/

#pragma mark - Window Management

- (void)showCollectionWindowForBundles:(NSArray *)bundleList {
	
	//	Show a view for multiples
	self.bundleViewController = [[[NSViewController alloc] initWithNibName:@"MBMBundleView" bundle:nil] autorelease];
	[self.bundleViewController configureForCollectionItem:self.collectionItem];
	
	//	Set our bundle list, using the recommended sorting order
	self.mailBundleList = [bundleList sortedArrayUsingDescriptors:[MBMMailBundle bestBundleSortDescriptors]];
	
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
	[self releaseFinalizeQueue];
	[NSApp terminate:sender];
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
		if ([[app bundleIdentifier] isEqualToString:kMBMMailBundleIdentifier]) {
			mailApp = app;
		}
	}
	return [mailApp terminate];
}

- (BOOL)restartMailWithBlock:(void (^)(void))taskBlock {
	
	//	If it is not running return
	if (!self.isMailRunning) {
		//	Perform the task first
		if (taskBlock != nil) {
			taskBlock();
		}
		return YES;
	}
	
	//	Set up an observer for app termination watch
	__block id appDoneObserver;
	appDoneObserver = [[[NSWorkspace sharedWorkspace] notificationCenter] addObserverForName:NSWorkspaceDidTerminateApplicationNotification object:[NSWorkspace sharedWorkspace] queue:self.maintenanceQueue usingBlock:^(NSNotification *note) {
		
		if ([[[[note userInfo] valueForKey:NSWorkspaceApplicationKey] bundleIdentifier] isEqualToString:kMBMMailBundleIdentifier]) {
			
			//	If there is a block, run it first
			if (taskBlock != nil) {
				taskBlock();
			}
			
			//	Launch Mail again
			[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:kMBMMailBundleIdentifier options:(NSWorkspaceLaunchAsync | NSWorkspaceLaunchWithoutActivation) additionalEventParamDescriptor:nil launchIdentifier:NULL];
			//	indicate that the maintenance is done
			[self endMaintenance];
			
			//	Remove this observer
			[[NSNotificationCenter defaultCenter] removeObserver:appDoneObserver];
		}
	}];
	
	//	Quit it and if that was successful, try to restart it
	if ([self quitMail]) {
		
		//	Indicate that a maintenance task is running
		[self startMaintenance];
		
	}
	else {
		//	Otherwise just remove the observer
		[[NSNotificationCenter defaultCenter] removeObserver:appDoneObserver];
		return NO;
	}
	
	return YES;
}

- (BOOL)askToRestartMailWithBlock:(void (^)(void))taskBlock usingIcon:(NSImage *)iconImage {
	BOOL	mailWasRestartedOrNotRunning = YES;
	if (AppDel.isMailRunning) {
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
			[quitMailAlert setIcon:[[NSWorkspace sharedWorkspace] iconForFile:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:kMBMMailBundleIdentifier]]];
		}
		
		//	Throw this back onto the main queue
		__block NSUInteger	mailResult;
		dispatch_sync(dispatch_get_main_queue(), ^{
			mailResult = [quitMailAlert runModal];
		});
		
		//	If they said yes, restart
		if (mailResult == NSAlertDefaultReturn) {
			//	Otherwise restart mail and return
			[self restartMailWithBlock:taskBlock];
		}
		else {
			mailWasRestartedOrNotRunning = NO;
		}
	}
	return mailWasRestartedOrNotRunning;
}

- (id)changePluginManagerDefaultValue:(id)value forKey:(NSString *)key {
	
	id	currentValue = nil;
	
	NSMutableDictionary	*changeDefaults = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:kMBMMailPluginManagerBundleID] mutableCopy];
	currentValue = [changeDefaults valueForKey:key];
	if ((value == nil) || (value == [NSNull null])) {
		[changeDefaults removeObjectForKey:key];
	}
	else {
		[changeDefaults setValue:value forKey:key];
	}
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:changeDefaults forName:kMBMMailPluginManagerBundleID];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[changeDefaults release];
	
	return currentValue;
}



#pragma mark - Bundle Updating

- (void)updateMailBundle:(MBMMailBundle *)mailBundle {
	
	//	If the bundle doesn't support sparkle, just send a done notification and return
	if (![mailBundle supportsSparkleUpdates]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kMBMDoneUpdatingMailBundleNotification object:mailBundle];
		return;
	}
	
	//	Simply use the standard Sparkle behavior (with an instantiation via the bundle)
	SUUpdater	*updater = [SUUpdater updaterForBundle:mailBundle.bundle];
	if (updater) {
		
		//	Set a delegate
		MBMSparkleDelegate	*sparkleDelegate = [[[MBMSparkleDelegate alloc] initWithMailBundle:mailBundle] autorelease];
		[updater setDelegate:sparkleDelegate];
		
		//	Create our driver manually, so that we have a copy to store
		SUUpdateDriver		*updateDriver = [[[NSClassFromString(@"MBTScheduledUpdateDriver") alloc] initWithUpdater:updater] autorelease];
		
		//	Then create an operation to run the action
		MPMSparkleAsyncOperation	*sparkleOperation = [[[MPMSparkleAsyncOperation alloc] initWithUpdateDriver:updateDriver] autorelease];
		[self.bundleSparkleOperations addObject:[NSDictionary dictionaryWithObjectsAndKeys:updateDriver, @"driver", sparkleOperation, @"operation", sparkleDelegate, @"delegate", mailBundle, @"bundle", nil]];
		
		//	Set an observer for the bundle
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(completeBundleUpdate:) name:kMBMDoneUpdatingMailBundleNotification object:mailBundle];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(completeBundleUpdate:) name:kMBMSUUpdateDriverAbortNotification object:updateDriver];
		
		LKLog(@"Update Scheduled");
		[self addActivityOperation:sparkleOperation];
		
	}
}

- (void)installAnyMailBundlesPending {
	
	NSArray	*ops = [[self.bundleSparkleOperations retain] autorelease];
	self.bundleSparkleOperations = nil;
	MBMMailBundle	*lastBundle = nil;
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
	if ([[note name] isEqualToString:kMBMDoneUpdatingMailBundleNotification ]) {
		LKLog(@"Should be completing op for bundle '%@'", [[[note object] path] lastPathComponent]);
		for (NSDictionary *aDict in self.bundleSparkleOperations) {
			if ([[aDict valueForKey:@"bundle"] isEqual:[note object]]) {
				theDict = aDict;
				break;
			}
		}
	}
	else if ([[note name] isEqualToString:kMBMSUUpdateDriverAbortNotification]) {
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
		[[NSNotificationCenter defaultCenter] removeObserver:self name:kMBMSUUpdateDriverAbortNotification object:[note object]];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:kMBMDoneUpdatingMailBundleNotification object:[note object]];
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
	[self finalizeIsWaitingToHappen];
}

- (void)quittingNowIsReasonable {
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		dispatch_queue_t	globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_source_t	timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, globalQueue);
		
		//	Create the timer and set it to repeat every half second
		dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 500ull*NSEC_PER_MSEC, 5000ull);
		dispatch_source_set_event_handler(timer, ^{
			if ((([self.maintenanceQueue operationCount] == 0) && (self.maintenanceCounter == 0)) &&
				(![self.activityQueue isSuspended] && ([self.activityQueue operationCount] == 0) && (self.activityCounter == 0)) && 
				(([self.finalizeQueue operationCount] == 0) && (self.finalizeCounter == 0))) {
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
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		dispatch_queue_t	globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_source_t	timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, globalQueue);
		
		//	Create the timer and set it to repeat every half second
		dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 500ull*NSEC_PER_MSEC, 5000ull);
		dispatch_source_set_event_handler(timer, ^{
			if (([self.maintenanceQueue operationCount] == 0) && (self.maintenanceCounter == 0)) {
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
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		dispatch_queue_t	globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_source_t	timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, globalQueue);
		
		//	Create the timer and set it to repeat every half second
		dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 500ull*NSEC_PER_MSEC, 5000ull);
		dispatch_source_set_event_handler(timer, ^{
			if ((!self.finalizeQueueRequiresExplicitRelease || 
				 (self.finalizeQueueRequiresExplicitRelease && _finalizedQueueReleased)) && 
				![self.activityQueue isSuspended] &&
				(([self.activityQueue operationCount] == 0) && (self.activityCounter == 0))) {
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
	SEL	startSelector = NSSelectorFromString([NSString stringWithFormat:@"start%@", [aQueueName capitalizedString]]);
	SEL	endSelector = NSSelectorFromString([NSString stringWithFormat:@"end%@", [aQueueName capitalizedString]]);
	SEL	goSelector = NSSelectorFromString([NSString stringWithFormat:@"%@IsWaitingToHappen", [aQueueName lowercaseString]]);
	
	//	Ensure that we have a queue and both selectors
	if (![self respondsToSelector:queueSelector] || ![self respondsToSelector:startSelector] || ![self respondsToSelector:endSelector]) {
		LKErr(@"Found an invalid selector for the queue '%@' - queueSel:%s, startSel:%s, endSel:%s", aQueueName, queueSelector, startSelector, endSelector);
		return;
	}
	NSOperationQueue	*aQueue = [self performSelector:queueSelector];
	if (aQueue == nil) {
		LKErr(@"Queue not found for '%@'", aQueueName);
		return;
	}
	
	//	Create blocks for start and end
	NSBlockOperation	*start = [NSBlockOperation blockOperationWithBlock:^{[self performSelector:startSelector];}];
	NSBlockOperation	*end = [NSBlockOperation blockOperationWithBlock:^{[self performSelector:endSelector];}];
	
	//	Create the dependencies
	[operation addDependency:start];
	[end addDependency:operation];
	
	//	Then add the operations
	[aQueue addOperations:[NSArray arrayWithObjects:start, operation, end, nil] waitUntilFinished:NO];
	//	And indicate that the queue should be started when ready, if the selector exists
	if ([self respondsToSelector:goSelector]) {
		[self performSelector:goSelector];
	}
}


- (void)startMaintenance {
	__block MBAppDelegate *blockSelf = self;
	[self.counterQueue addOperationWithBlock:^{
		blockSelf.maintenanceCounter++;
	}];
}	

- (void)endMaintenance {
	__block MBAppDelegate *blockSelf = self;
	[self.counterQueue addOperationWithBlock:^{
		blockSelf.maintenanceCounter--;
	}];
}

- (void)startActivity {
	__block MBAppDelegate *blockSelf = self;
	[self.counterQueue addOperationWithBlock:^{
		blockSelf.activityCounter++;
	}];
}	

- (void)endActivity {
	__block MBAppDelegate *blockSelf = self;
	[self.counterQueue addOperationWithBlock:^{
		blockSelf.activityCounter--;
	}];
}

- (void)startFinalize {
	__block MBAppDelegate *blockSelf = self;
	[self.counterQueue addOperationWithBlock:^{
		blockSelf.finalizeCounter++;
	}];
}	

- (void)endFinalize {
	__block MBAppDelegate *blockSelf = self;
	[self.counterQueue addOperationWithBlock:^{
		blockSelf.finalizeCounter--;
	}];
}




@end
