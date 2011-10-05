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
@synthesize canQuitAccordingToMaintenance;
@synthesize isMailRunning;
@synthesize observerHolder;


- (void)applicationChangeForNotification:(NSNotification *)note {
	//	If this is Mail
	if ([[[[note userInfo] valueForKey:NSWorkspaceApplicationKey] bundleIdentifier] isEqualToString:kMBMMailBundleIdentifier]) {
		//	See if it launched or terminated
		self.isMailRunning = [[note name] isEqualToString:NSWorkspaceDidLaunchApplicationNotification];
	}
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	//	Set default for mail is running
	self.isMailRunning = IsMailRunning();
	
	//	Set a key-value observation on the running apps for "Mail"
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationChangeForNotification:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationChangeForNotification:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
	
	//	Use a group to associate tasks that I am going to throw onto queues
	dispatch_group_t	maintenanceTaskGroup = dispatch_group_create();
	dispatch_queue_t	globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	
	//	Dispatch a task
	/*
	dispatch_group_async(maintenanceTaskGroup, globalQueue, ^(void) {
		//	My Code
	});
	*/
	
	//	Finally setup our cleanup code after all maintenance is completed
	dispatch_group_notify(maintenanceTaskGroup, globalQueue, ^(void) {
		//	What I want to do when all is complete
		self.canQuitAccordingToMaintenance = YES;
	});
	dispatch_release(maintenanceTaskGroup);
	
	
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
		if (aBundle.incompatibleWithCurrentMail || aBundle.incompatibleWithFutureMail) {// || aBundle.hasUpdate) {
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

- (void)quittingNowIsReasonable {
	if (self.canQuitAccordingToMaintenance) {
		[NSApp terminate:nil];
	}
	else {

		dispatch_queue_t	globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_source_t	timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, globalQueue);
		dispatch_time_t		now = dispatch_walltime(DISPATCH_TIME_NOW, 0);
		
		//	Create the timer and set it to repeat every second
		dispatch_source_set_timer(timer, now, 1ull*NSEC_PER_SEC, 5000ull);
		dispatch_source_set_event_handler(timer, ^{
			if (self.canQuitAccordingToMaintenance) {
				dispatch_suspend(timer);
				[NSApp terminate:nil];
				dispatch_release(timer);
			}
		});
	}
}


@end


