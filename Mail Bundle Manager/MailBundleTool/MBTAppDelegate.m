//
//  MBTAppDelegate.m
//  MailBundleTool
//
//  Created by Scott Little on 28/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBTAppDelegate.h"
#import "MBMMailBundle.h"
#import "MBTSinglePluginController.h"


@interface MBTAppDelegate ()
@property (nonatomic, retain)	id					observerHolder;
- (void)showUserInvalidBundles:(NSArray *)bundlesToTest;
- (void)validateAllBundles;
@end

@implementation MBTAppDelegate

@synthesize window = _window;
@synthesize currentController = _currentController;
@synthesize isMailRunning;
@synthesize observerHolder;

@synthesize maintenanceCounterQueue = _maintenanceCounterQueue;
@synthesize maintenanceQueue = _maintenanceQueue;
@synthesize canQuitAccordingToMaintenance;
@synthesize maintenanceCounter;


- (void)applicationChangeForNotification:(NSNotification *)note {
	//	If this is Mail
	if ([[[[note userInfo] valueForKey:NSWorkspaceApplicationKey] bundleIdentifier] isEqualToString:kMBMMailBundleIdentifier]) {
		//	See if it launched or terminated
		self.isMailRunning = [[note name] isEqualToString:NSWorkspaceDidLaunchApplicationNotification];
	}
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	//	Set default for mail is running
	for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
		if ([[app bundleIdentifier] isEqualToString:kMBMMailBundleIdentifier]) {
			self.isMailRunning = YES;
		}
	}
	
	//	Set a key-value observation on the running apps for "Mail"
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationChangeForNotification:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationChangeForNotification:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	
	//	Create a new operation queues to use for maintenance tasks
	self.maintenanceQueue = [[[NSOperationQueue alloc] init] autorelease];
	[self.maintenanceQueue setMaxConcurrentOperationCount:1];	//	Makes this serial queue, in effect
	self.maintenanceCounterQueue = [[[NSOperationQueue alloc] init] autorelease];
	
	//	Decide what actions to take
	//	Read in any command line parameters and set instance variables accordingly
	NSArray	*arguments = [[NSProcessInfo processInfo] arguments];
	
	//	See if there are more arguments
	NSString	*action = nil;
	NSString	*bundlePath = nil;
	
	if ([arguments count] > 1) {
		action = [arguments objectAtIndex:1];
	}
	if ([arguments count] > 2) {
		bundlePath = [arguments objectAtIndex:2];
	}
	
	//	Get the mail bundle, if there
	MBMMailBundle	*mailBundle = nil;
	if (bundlePath) {
		mailBundle = [[[MBMMailBundle alloc] initWithPath:bundlePath shouldLoadUpdateInfo:NO] autorelease];
	}

	//	Look at the first argument (after executable name) and test for one of our types
	if ([kMBMCommandLineUninstallKey isEqualToString:action]) {
		//	Tell it to uninstall itself
		[mailBundle uninstall];
	}
	else if ([kMBMCommandLineUpdateKey isEqualToString:action]) {
		//	Tell it to update itself
		[mailBundle updateIfNecessary];
	}
	else if ([kMBMCommandLineCheckCrashReportsKey isEqualToString:action]) {
		//	Tell it to check its crash reports
		[mailBundle sendCrashReports];
	}
	else if ([kMBMCommandLineUpdateAndCrashReportsKey isEqualToString:action]) {
		//	Tell it to check its crash reports
		[mailBundle sendCrashReports];
		//	And update itself
		[mailBundle updateIfNecessary];
	}
	else if ([kMBMCommandLineValidateAllKey isEqualToString:action]) {
		[self validateAllBundles];
	}
}

- (void)dealloc {
	//	Remove the observations this class is doing.
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	//	Release our controller
	self.currentController = nil;
	
	[super dealloc];
}


#pragma mark - Action Methods


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
		self.observerHolder = [[NSNotificationCenter defaultCenter] addObserverForName:kMBMDoneLoadingSparkleNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
			
			//	If the object is in our list decrement counter
			if ([updatingBundles containsObject:[note object]]) {
				countDown--;
			}
			
			//	Then test to see if our countDown is at zero
			if (countDown == 0) {
				//	Call our processing method first
				[self showUserInvalidBundles:[otherBundles arrayByAddingObjectsFromArray:updatingBundles]];
				
				//	Then, remove observer, set it to nil
				[[NSNotificationCenter defaultCenter] removeObserver:self.observerHolder];
				self.observerHolder = nil;
			}
			
		}];
		
		//	After setting up the listener, have all of these bundles load thier info
		[updatingBundles makeObjectsPerformSelector:@selector(loadUpdateInformation)];
	}
}


#pragma mark - Support Methods

- (void)showUserInvalidBundles:(NSArray *)bundlesToTest {
	
	//	If there are no items, just return
	if (IsEmpty(bundlesToTest)) {
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
		for (MBMMailBundle *aBadBundle in badBundles) {
			//	Show a view for multiples
		}
	}
	
}

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

- (void)restartMail {
	
	//	If it is not running return
	if (!self.isMailRunning) {
		return;
	}
	
	//	Set up an observer for app termination watch
	__block id thingy = [[[NSWorkspace sharedWorkspace] notificationCenter] addObserverForName:NSWorkspaceDidTerminateApplicationNotification object:[NSWorkspace sharedWorkspace] queue:self.maintenanceQueue usingBlock:^(NSNotification *note) {
		
		if ([[[[note userInfo] valueForKey:NSWorkspaceApplicationKey] bundleIdentifier] isEqualToString:kMBMMailBundleIdentifier]) {
			
			//	Launch Mail again
			[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:kMBMMailBundleIdentifier options:NSWorkspaceLaunchWithoutActivation additionalEventParamDescriptor:nil launchIdentifier:NULL];
			//	indicate that the maintenance is done
			[self endMaintenance];
			
			//	Remove this observer
			[[NSNotificationCenter defaultCenter] removeObserver:thingy];
		}
	}];

	//	Quit it and if that was successful, try to restart it
	if ([self quitMail]) {
		
		//	Indicate that a maintenance task is running
		[self startMaintenance];
		
	}
	else {
		//	Otherwise just remove the observer
		[[NSNotificationCenter defaultCenter] removeObserver:thingy];
	}
}

- (void)addMaintenanceTask:(void (^)(void))block {
	
	//	Quickly start our maintenance
	[self startMaintenance];

	//	Create blocks for main and end
	NSBlockOperation	*end = [NSBlockOperation blockOperationWithBlock:^{[self endMaintenance];}];
	NSBlockOperation	*main = [NSBlockOperation blockOperationWithBlock:block];
	
	//	Create the dependencies
	[end addDependency:main];
	
	//	Then add the operations
	[self.maintenanceQueue addOperations:[NSArray arrayWithObjects:main, end, nil] waitUntilFinished:NO];
}

- (void)startMaintenance {
	[self.maintenanceCounterQueue addOperationWithBlock:^{
		self.maintenanceCounter++;
	}];
}	

- (void)endMaintenance {
	[self.maintenanceCounterQueue addOperationWithBlock:^{
		self.maintenanceCounter--;
	}];
}

- (void)quittingNowIsReasonable {
	if (([self.maintenanceCounterQueue operationCount] == 0) && (self.maintenanceCounter == 0)) {
		[NSApp terminate:nil];
	}
	else {

		dispatch_queue_t	globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_source_t	timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, globalQueue);
		
		//	Create the timer and set it to repeat every second
		dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1ull*NSEC_PER_SEC, 5000ull);
		dispatch_source_set_event_handler(timer, ^{
			if (([self.maintenanceCounterQueue operationCount] == 0) && (self.maintenanceCounter == 0)) {
				dispatch_source_cancel(timer);
				dispatch_release(timer);
				[NSApp terminate:nil];
			}
		});
		//	Start it
		dispatch_resume(timer);
	}
}


@end


