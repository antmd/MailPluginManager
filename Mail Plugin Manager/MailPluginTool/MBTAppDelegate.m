//
//  MBTAppDelegate.m
//  MailBundleTool
//
//  Created by Scott Little on 28/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBTAppDelegate.h"
#import "MBMMailBundle.h"
#import "MBMUUIDList.h"
#import "MBMSystemInfo.h"
#import "MBTSinglePluginController.h"
#import "LKCGStructs.h"
#import "NSUserDefaults+MBMShared.h"
#import <Sparkle/Sparkle.h>


#define HOURS_AGO	(-1 * 60 * 60)


@interface MBTAppDelegate ()
@property	(nonatomic, copy)	NSMutableDictionary			*savedSparkleState;
@property	(nonatomic, retain)	NSArray						*sparkleKeysValues;
@property	(nonatomic, assign) MBTSparkleAsyncOperation	*sparkleOperation;
@property	(nonatomic, retain) SUBasicUpdateDriver			*updateDriver;
@property	(nonatomic, copy)	NSMutableArray				*bundleSparkleOperations;

@property	(nonatomic, retain)	NSOperationQueue			*activityQueue;
@property	(atomic, assign)	NSInteger					activityCounter;
@property	(nonatomic, retain)	NSOperationQueue			*finalizeQueue;
@property	(atomic, assign)	NSInteger					finalizeCounter;


//	Actions
- (void)installAnyMailBundlesPending;
- (NSString *)pathToManagerContainer;
- (void)validateAllBundles;
- (void)showUserInvalidBundles:(NSArray *)bundlesToTest;
- (BOOL)checkFrequency:(NSUInteger)frequency forActionKey:(NSString *)actionKey onBundle:(MBMMailBundle *)mailBundle;

//	Queue management tasks
- (void)addActivityTask:(void (^)(void))block;
- (void)addActivityOperation:(NSOperation *)operation;
- (void)addFinalizeTask:(void (^)(void))block;
- (void)addFinalizeOperation:(NSOperation *)operation;
- (void)activityIsWaitingToHappen;
- (void)finalizeIsWaitingToHappen;


@end

@implementation MBTAppDelegate

@synthesize savedSparkleState = _savedSparkleState;
@synthesize sparkleKeysValues = _sparkleKeysValues;
@synthesize sparkleOperation = _sparkleOperation;
@synthesize updateDriver = _updateDriver;
@synthesize bundleSparkleOperations = _bundleSparkleOperations;

@synthesize activityQueue = _activityQueue;
@synthesize activityCounter = _activityCounter;
@synthesize finalizeQueue = _finalizeQueue;
@synthesize finalizeCounter = _finalizeCounter;



#pragma mark - Handler Methods

- (void)processArguments {
	
	//	Decide what actions to take
	//	Read in any command line parameters and set instance variables accordingly
	NSArray	*arguments = [[NSProcessInfo processInfo] arguments];
	
	//	See if there are more arguments
	NSString	*action = nil;
	
	if ([arguments count] > 1) {
		action = [arguments objectAtIndex:1];
	}
	if ([arguments count] > 2) {
		arguments = [arguments subarrayWithRange:NSMakeRange(2, [arguments count] - 2)];
	}
	[self doAction:action withArguments:arguments];
}


#pragma mark - Sparkle Delegate Methods

- (void)setupSparkleEnvironment {
	id	value = nil;
	[self.savedSparkleState removeAllObjects];
	for (NSDictionary *aDict in self.sparkleKeysValues) {
		value = [self changePluginManagerDefaultValue:[aDict valueForKey:@"value"] forKey:[aDict valueForKey:@"key"]];
		if (value == nil) {
			value = [NSNull null];
		}
		LKLog(@"Saving value '%@' for key '%@'",value, [aDict valueForKey:@"key"]);
		[self.savedSparkleState setValue:value forKey:[aDict valueForKey:@"key"]];
	}
}

- (void)resetSparkleEnvironment {
	for (NSDictionary *aDict in self.sparkleKeysValues) {
		LKLog(@"Trying to reset value '%@' for key '%@'",[self.savedSparkleState valueForKey:[aDict valueForKey:@"key"]], [aDict valueForKey:@"key"]);
		[self changePluginManagerDefaultValue:[self.savedSparkleState valueForKey:[aDict valueForKey:@"key"]] forKey:[aDict valueForKey:@"key"]];
	}
	[self.savedSparkleState removeAllObjects];
}

- (void)cleanupSparkle {
	[self resetSparkleEnvironment];
	[self.sparkleOperation finish];
}

- (BOOL)updaterShouldPromptForPermissionToCheckForUpdates:(SUUpdater *)updater {
	return NO;
}

- (BOOL)updater:(SUUpdater *)updater shouldPostponeRelaunchForUpdate:(SUAppcastItem *)update untilInvoking:(NSInvocation *)invocation {
	LKLog(@"Update found with invocation:%@", invocation);
	[self cleanupSparkle];
	//	Do the install, but avoid a relaunch
	[self.updateDriver installWithToolAndRelaunch:NO];
	//	Tell Sparkle we're handling it.
	return YES;
}

- (void)updaterDidNotFindUpdate:(SUUpdater *)updater {
	LKLog(@"No Update found");
	[self cleanupSparkle];
}

#pragma mark - Application Events

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	LKLog(@"Inside the MailBundleTool - Path is:'%@'", [[NSBundle mainBundle] bundlePath]);

	//	Call our super
	[super applicationDidFinishLaunching:aNotification];
	
	//	Add this method to the finalize before the Sparkle Update for the Manager
	LKLog(@"Adding bundle installer cleanup to Finalize queue");
	[self addFinalizeTask:^{
		[self installAnyMailBundlesPending];
	}];
	
	//	Get Path for the Mail Plugin Manager container
	NSString	*mpmPath = [self pathToManagerContainer];
	//	Currently don't support Sparkle updating for just the Tool, so only do this if contained with the Manager
	LKLog(@"mpmPath is:%@", mpmPath);
	if (mpmPath != nil) {
		//	Then find it's bundle
		NSURL		*bundleURL = [NSURL fileURLWithPath:mpmPath isDirectory:YES];
		NSBundle	*managerBundle = [NSBundle bundleWithURL:bundleURL];
		
		//	Test to see if this bundle is running
		for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
			if ([[app bundleURL] isEqual:bundleURL]) {
				//	If so, just call process and leave.
				[self processArguments];
				return;
			}
		}
		
		//	Test for an update quietly
		SUUpdater	*managerUpdater = [SUUpdater updaterForBundle:managerBundle];
		[managerUpdater resetUpdateCycle];
		managerUpdater.delegate = self;
		//	May need to save the state of this value and restore afterward
		[self setupSparkleEnvironment];
		
		//	Run a background thread to see if we need to update this app, using the basic updater directly.
		self.updateDriver = [[[SUBasicUpdateDriver alloc] initWithUpdater:managerUpdater] autorelease];
		self.sparkleOperation = [[[MBTSparkleAsyncOperation alloc] initWithUpdateDriver:self.updateDriver] autorelease];
		[self addFinalizeOperation:self.sparkleOperation];
	}
	
	//	Go ahead and process the arguments
	[self processArguments];

}

- (id)init {
	self = [super init];
	if (self) {
		_sparkleKeysValues = [[NSArray alloc] initWithObjects:
							  [NSDictionary dictionaryWithObjectsAndKeys:@"SUAutomaticallyUpdate", @"key", [NSNumber numberWithBool:YES], @"value", nil], 
							  [NSDictionary dictionaryWithObjectsAndKeys:@"SUEnableAutomaticChecks", @"key", [NSNumber numberWithBool:NO], @"value", nil], 
							  [NSDictionary dictionaryWithObjectsAndKeys:@"SUHasLaunchedBefore", @"key", [NSNumber numberWithBool:YES], @"value", nil], 
							  [NSDictionary dictionaryWithObjectsAndKeys:@"SUSendProfileInfo", @"key", [NSNumber numberWithBool:NO], @"value", nil], 
							  nil];
		_savedSparkleState = [[NSMutableDictionary alloc] initWithCapacity:[_sparkleKeysValues count]];
		_bundleSparkleOperations = [[NSMutableArray alloc] init];
		
		//	Create a new operation queues to use for maintenance tasks
		_activityQueue = [[NSOperationQueue alloc] init];
		_activityQueue.maxConcurrentOperationCount = 1;	//	Makes this serial queue, in effect
		_activityQueue.suspended = YES;
		_finalizeQueue = [[NSOperationQueue alloc] init];
		_finalizeQueue.maxConcurrentOperationCount = 1;	//	Makes this serial queue, in effect
		_finalizeQueue.suspended = YES;
		
	}
	return self;
}

- (void)dealloc {
	self.updateDriver = nil;
	self.savedSparkleState = nil;
	self.sparkleKeysValues = nil;
	self.bundleSparkleOperations = nil;
	
	self.activityQueue = nil;
	self.finalizeQueue = nil;

	[super dealloc];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	
	LKLog(@"Activity Count:%d  Finalize Count:%d", [self.activityQueue operationCount], [self.finalizeQueue operationCount]);
	NSApplicationTerminateReply	reply = NSTerminateNow;
	if (([self.activityQueue operationCount] > 0) || ([self.finalizeQueue operationCount] > 0)) {
		reply = NSTerminateCancel;
	}
	LKLog(@"Application is terminating: trace\n\n%@", [NSThread callStackSymbols]);
	return reply;
}



#pragma mark - Helper Methods

- (NSString *)pathToManagerContainer {
	
	//	Create our path one time
	static	NSString		*managerPath = nil;
	static	dispatch_once_t	once;
	dispatch_once(&once, ^{ 
		NSString	*testPath = [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
		BOOL		managerFound = NO;
		
		//	Get the plugin manager
		NSURL		*managerURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:kMBMMailPluginManagerBundleID];
		if (managerURL != nil) {
		
			NSString	*managerName = [managerURL lastPathComponent];
			NSString	*lastComponent = nil;
			for (NSString *pathItem in [[testPath pathComponents] reverseObjectEnumerator]) {
				if ([lastComponent isEqualToString:@"Contents"] && [[pathItem lastPathComponent] isEqualToString:managerName]) {
					managerFound = YES;
					break;
				}
				lastComponent = pathItem;
				testPath = [testPath stringByDeletingLastPathComponent];
			}
			
			managerPath = managerFound?testPath:nil;
		}
	});
	
	return managerPath;
}


#pragma mark - Action Methods

- (void)doAction:(NSString *)action withArguments:(NSArray *)arguments {
	
	NSString	*bundlePath = nil;
	NSInteger	frequencyInHours = 0;
	
	if ([arguments count] > 0) {
		bundlePath = [arguments objectAtIndex:0];
		if ([bundlePath isEqualToString:@"(null)"]) {
			bundlePath = nil;
		}
	}
	if ([arguments count] > 1) {
		if ([[arguments objectAtIndex:1] isEqualToString:kMBMCommandLineFrequencyOptionKey]) {
			NSString	*frequencyType = [arguments objectAtIndex:4];
			if ([frequencyType isEqualToString:@"daily"]) {
				frequencyInHours = 24;
			}
			else if ([frequencyType isEqualToString:@"weekly"]) {
				frequencyInHours = 24 * 7;
			}
			else if ([frequencyType isEqualToString:@"monthly"]) {
				frequencyInHours = 24 * 7 * 28;
			}
		}
	}
	
	//	Get the mail bundle, if there
	MBMMailBundle	*mailBundle = nil;
	if (bundlePath) {
		mailBundle = [[[MBMMailBundle alloc] initWithPath:bundlePath shouldLoadUpdateInfo:NO] autorelease];
	}
	
	//	If there is no bundle for one of the tasks that require it, just quit
	if ((bundlePath == nil) &&
		([kMBMCommandLineUninstallKey isEqualToString:action] || [kMBMCommandLineUpdateKey isEqualToString:action] ||
		 [kMBMCommandLineCheckCrashReportsKey isEqualToString:action] || [kMBMCommandLineUpdateAndCrashReportsKey isEqualToString:action])) {
			
			//	Release the Activity Queue
			[self activityIsWaitingToHappen];
	}
	else {
		//	Look at the first argument (after executable name) and test for one of our types
		if ([kMBMCommandLineUninstallKey isEqualToString:action]) {
			//	Tell it to uninstall itself
			[self addActivityTask:^{
				[mailBundle uninstall];
			}];
		}
		else if ([kMBMCommandLineUpdateKey isEqualToString:action]) {
			//	Tell it to update itself, if frequency requirements met
			if ([self checkFrequency:frequencyInHours forActionKey:action onBundle:mailBundle]) {
				LKLog(@"Adding an update for bundle:'%@' to the queue", [[mailBundle path] lastPathComponent]);
				[self updateMailBundle:mailBundle];
			}
		}
		else if ([kMBMCommandLineCheckCrashReportsKey isEqualToString:action]) {
			//	Tell it to check its crash reports, if frequency requirements met
			if ([self checkFrequency:frequencyInHours forActionKey:action onBundle:mailBundle]) {
				[self addActivityTask:^{
					[mailBundle sendCrashReports];
				}];
			}
		}
		else if ([kMBMCommandLineUpdateAndCrashReportsKey isEqualToString:action]) {
			//	If frequency requirements met
			if ([self checkFrequency:frequencyInHours forActionKey:action onBundle:mailBundle]) {
				[self addActivityTask:^{
					[mailBundle sendCrashReports];
				}];
				[self updateMailBundle:mailBundle];
			}
		}
		else if ([kMBMCommandLineSystemInfoKey isEqualToString:action]) {
			[self addActivityTask:^{
				//	Then send the information
				NSDistributedNotificationCenter	*center = [NSDistributedNotificationCenter defaultCenter];
				[center postNotificationName:kMBMSystemInfoDistNotification object:mailBundle.identifier userInfo:[MBMSystemInfo completeInfo] deliverImmediately:YES];
				LKLog(@"Sent notification");
				[AppDel quittingNowIsReasonable];
			}];
		}
		else if ([kMBMCommandLineUUIDListKey isEqualToString:action]) {
			[self addActivityTask:^{
				NSDistributedNotificationCenter	*center = [NSDistributedNotificationCenter defaultCenter];
				[center postNotificationName:kMBMUUIDListDistNotification object:mailBundle.identifier userInfo:[MBMUUIDList fullUUIDListFromBundle:mailBundle.bundle] deliverImmediately:YES];
				[AppDel quittingNowIsReasonable];
			}];
		}
		else if ([kMBMCommandLineValidateAllKey isEqualToString:action]) {
			[self addActivityTask:^{
				[self validateAllBundles];
			}];
		}
		else {
			//	Release the Activity Queue
			[self activityIsWaitingToHappen];
		}
	}

	//	Can always indicate that quitting is reasonable
	[AppDel quittingNowIsReasonable];
}

- (void)installAnyMailBundlesPending {
	
	NSArray	*ops = [[self.bundleSparkleOperations retain] autorelease];
	self.bundleSparkleOperations = nil;
	BOOL	shouldRestartMail = NO;
	LKLog(@"Finishing Installs");
	for (NSDictionary *opDict in ops) {
		SUBasicUpdateDriver	*ud = [opDict valueForKey:@"driver"];
		LKLog(@"Finishing Install for '%@'", [[[opDict valueForKey:@"bundle"] path] lastPathComponent]);
		[ud installWithToolAndRelaunch:NO];
		shouldRestartMail = YES;
	}
	
	//	Then do the Mail restart if necessary
	if (shouldRestartMail) {
		LKLog(@"Need to restart Mail");
		BOOL	installing = YES;
		//	Test to see if Mail is running
		if (AppDel.isMailRunning) {
			LKLog(@"Restarting Mail");
			//	If so, ask user to quit it
			NSString	*messageText = NSLocalizedString(@"I need to restart Mail to finish.", @"Description of why Mail needs to be quit.");
			NSString	*infoText = NSLocalizedString(@"Clicking 'Restart Mail' will complete this %@. Clicking 'Quit Mail Later' will let you delay this until later.", @"Details about how the buttons work.");
			infoText = [NSString stringWithFormat:infoText, installing?NSLocalizedString(@"installation", @"installation text"):NSLocalizedString(@"uninstallation", @"uninstallation text")];
			
			NSString	*defaultButton = NSLocalizedString(@"Restart Mail", @"Button text to quit mail");
			NSString	*altButton = NSLocalizedString(@"Quit Mail Later", @"Button text to quit myself");
			NSAlert		*quitMailAlert = [NSAlert alertWithMessageText:messageText defaultButton:defaultButton alternateButton:altButton otherButton:nil informativeTextWithFormat:infoText];
			
			//	Throw this back onto the main queue
			__block NSUInteger	mailResult;
			dispatch_sync(dispatch_get_main_queue(), ^{
				mailResult = [quitMailAlert runModal];
			});
			
			//	If they denied, set an error message
			if (mailResult == NSAlertDefaultReturn) {
			//	Otherwise restart mail and return
				[AppDel restartMail:nil];
			}
		}
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
		MBTSparkleAsyncOperation	*sparkleOperation = [[[MBTSparkleAsyncOperation alloc] initWithUpdateDriver:updateDriver] autorelease];
		[self.bundleSparkleOperations addObject:[NSDictionary dictionaryWithObjectsAndKeys:updateDriver, @"driver", sparkleOperation, @"operation", sparkleDelegate, @"delegate", mailBundle, @"bundle", nil]];
		
		//	Set an observer for the bundle
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(completeBundleUpdate:) name:kMBMDoneUpdatingMailBundleNotification object:mailBundle];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(completeBundleUpdate:) name:kMBMSUUpdateDriverAbortNotification object:updateDriver];
		
		LKLog(@"Update Scheduled");
		[self addActivityOperation:sparkleOperation];
		
	}
}


- (void)validateAllBundles {
	
	//	Separate all the bundles into those that can update and those that can't
	NSMutableArray	*updatingBundles = [NSMutableArray array];
	NSMutableArray	*otherBundles = [NSMutableArray array];
	for (MBMMailBundle *aBundle in [MBMMailBundle allMailBundles]) {
		if ([aBundle supportsSparkleUpdates]) {
			[updatingBundles addObject:aBundle];
		}
		else {
			[otherBundles addObject:aBundle];
		}
	}
	
	//	If there are no bundles updating, just call method with otherBundles
	if (IsEmpty(updatingBundles)) {
		[self showUserInvalidBundles:otherBundles];
	}
	else {
		//	Otherwise setup an observer to ensure that all updates happen before processing
		__block	NSUInteger	countDown = [updatingBundles count];
		__block	id			observerHolder;
		observerHolder = [[NSNotificationCenter defaultCenter] addObserverForName:kMBMDoneLoadingSparkleNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
			
			//	If the object is in our list decrement counter
			if ([updatingBundles containsObject:[note object]]) {
				countDown--;
			}
			
			//	Then test to see if our countDown is at zero
			if (countDown == 0) {
				//	Call our processing method first
				[self showUserInvalidBundles:[otherBundles arrayByAddingObjectsFromArray:updatingBundles]];
				
				//	Then, remove observer, set it to nil
				[[NSNotificationCenter defaultCenter] removeObserver:observerHolder];
			}
			
		}];
		
		//	After setting up the listener, have all of these bundles load thier info
		[updatingBundles makeObjectsPerformSelector:@selector(loadUpdateInformation)];
	}
}


- (void)showUserInvalidBundles:(NSArray *)bundlesToTest {
	
	//	If there are no items, just return after indicating we can quit
	if (IsEmpty(bundlesToTest)) {
		[AppDel quittingNowIsReasonable];
		return;
	}
	
	//	Build list of ones to show
	NSMutableArray	*badBundles = [NSMutableArray array];
	for (MBMMailBundle *aBundle in bundlesToTest) {
		if (aBundle.incompatibleWithCurrentMail || aBundle.incompatibleWithFutureMail || aBundle.hasUpdate) {
			[badBundles addObject:aBundle];
		}
	}
	
	//	If there is just one, special case to show a nicer presentation
	if ([badBundles count] == 1) {
		//	Show a view for a single item
		self.currentController = [[[MBTSinglePluginController alloc] initWithMailBundle:[badBundles lastObject]] autorelease];
		[[self.currentController window] center];
		[self.currentController showWindow:self];
	}
	else {
		
		//	Show the window
		[self showCollectionWindowForBundles:badBundles];
		
		//	Add a notification watcher to handle uninstalls
		self.bundleUninstallObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMBMMailBundleUninstalledNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
			if ([[note object] isKindOfClass:[MBMMailBundle class]]) {
				NSMutableArray	*change = [self.mailBundleList mutableCopy];
				[change removeObjectIdenticalTo:[note object]];
				self.mailBundleList = [NSArray arrayWithArray:change];
				[change release];
			}
		}];
	}
}

- (BOOL)checkFrequency:(NSUInteger)frequency forActionKey:(NSString *)actionKey onBundle:(MBMMailBundle *)mailBundle {
	
	//	Default is that we have passed the frequency
	BOOL	result = YES;
	
	//	Look in User Defaults to see when last run
	NSMutableDictionary	*bundleDict = [[NSUserDefaults standardUserDefaults] mutableDefaultsForMailBundle:mailBundle];
	NSDate				*bundleActionLastDate = [bundleDict valueForKey:actionKey];
	NSDate				*checkDate = [NSDate dateWithTimeIntervalSinceNow:(frequency * HOURS_AGO)];
	
	//	If we are within the freq, then return false
	if ([bundleActionLastDate laterDate:checkDate]) {
		result = NO;
	}
	else {
		//	Update user defaults with attempt date
		[bundleDict setObject:[NSDate date] forKey:actionKey];
		[[NSUserDefaults standardUserDefaults] setDefaults:bundleDict forMailBundle:mailBundle];
	}
	
	//	Look to see if we need to update our Agents asynchronously
	return result;
}



#pragma mark - Internal Queue Management

- (void)startActivity {
	__block MBTAppDelegate *blockSelf = self;
	[self.counterQueue addOperationWithBlock:^{
		blockSelf.activityCounter++;
	}];
}	

- (void)endActivity {
	__block MBTAppDelegate *blockSelf = self;
	[self.counterQueue addOperationWithBlock:^{
		blockSelf.activityCounter--;
	}];
}

- (void)startFinalize {
	__block MBTAppDelegate *blockSelf = self;
	[self.counterQueue addOperationWithBlock:^{
		blockSelf.finalizeCounter++;
	}];
}	

- (void)endFinalize {
	__block MBTAppDelegate *blockSelf = self;
	[self.counterQueue addOperationWithBlock:^{
		blockSelf.finalizeCounter--;
	}];
}



#pragma mark - Queue Management Methods

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
			if (![self.activityQueue isSuspended] &&
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



@end


