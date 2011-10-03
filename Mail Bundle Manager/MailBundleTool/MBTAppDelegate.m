//
//  MBTAppDelegate.m
//  MailBundleTool
//
//  Created by Scott Little on 28/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBTAppDelegate.h"
#import "MBMMailBundle.h"

@implementation MBTAppDelegate

@synthesize window = _window;
@synthesize currentController = _currentController;
@synthesize canQuitAccordingToMaintenance;
@synthesize isMailRunning;


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"runningApplications"]) {
		//	See if mail is in the list
		NSRunningApplication	*mailApp = [[NSRunningApplication runningApplicationsWithBundleIdentifier:kMBMMailBundleIdentifier] lastObject];
		BOOL					wasMailRunningBefore = self.isMailRunning;
		self.isMailRunning = (mailApp != nil);
		
		//	If the state of mail changed, send a notification
		if (wasMailRunningBefore != self.isMailRunning) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MBMMailHasChangedStatusAndIsNowRunning" object:[NSNumber numberWithBool:self.isMailRunning]];
		}
	}
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	//	Set a key-value observation on the running apps for "Mail"
	[[NSWorkspace sharedWorkspace] addObserver:self forKeyPath:@"runningApplications" options:0 context:NULL];
	
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

- (void)validateAllBundles {
	
	//	Look through all of the bundles
	NSArray			*allBundles = [MBMMailBundle allMailBundles];
	NSMutableArray	*invalidBundles = [NSMutableArray array];
	for (MBMMailBundle *aBundle in allBundles) {
		//	Add any that are invalid
		if (![aBundle compatibleWithCurrentMail]) {
			[invalidBundles addObject:aBundle];
			//	Get that bundle to load up any update info
			[aBundle loadUpdateInformation];
		}
	}
	
	//	Process the invalid bundles
	//	If there is just one, special case to show a nicer presentation
	if ([invalidBundles count] == 1) {
		//	Show a view for a single item
	}
	else {
		for (MBMMailBundle *badBundle in invalidBundles) {
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
