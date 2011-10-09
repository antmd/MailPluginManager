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

@interface MBAppDelegate ()
- (void)applicationChangeForNotification:(NSNotification *)note;
@end

@implementation MBAppDelegate

@synthesize bundleUnistallObserver;

@synthesize window = _window;
@synthesize collectionItem = _collectionItem;
@synthesize bundleViewController = _bundleViewController;
@synthesize mailBundleList = _mailBundleList;
@synthesize currentController = _currentController;

@synthesize isMailRunning;
@synthesize maintenanceCounterQueue = _maintenanceCounterQueue;
@synthesize maintenanceQueue = _maintenanceQueue;
@synthesize canQuitAccordingToMaintenance;
@synthesize maintenanceCounter;

@synthesize backgroundView = _backgroundView;
@synthesize scrollView = _scrollView;


#pragma mark - Application Delegate

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

}

- (void)applicationWillTerminate:(NSNotification *)notification {
	if (self.bundleUnistallObserver != nil) {
		[[NSNotificationCenter defaultCenter] removeObserver:self.bundleUnistallObserver];
		self.bundleUnistallObserver = nil;
	}
}

- (void)dealloc {
	//	Remove the observations this class is doing.
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	//	Release our controller
	self.currentController = nil;
	self.mailBundleList = nil;
	self.bundleViewController = nil;
	
	[super dealloc];
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


#pragma mark - Window Management

- (void)showCollectionWindowForBundles:(NSArray *)bundleList {
	
	//	Show a view for multiples
	self.bundleViewController = [[[NSViewController alloc] initWithNibName:@"MBMBundleView" bundle:nil] autorelease];
	[self.bundleViewController configureForCollectionItem:self.collectionItem];
	
	//	Set our bundle list
	self.mailBundleList = bundleList;
	
	//	Adjust the view & window sizes, if there should only be a single row
	CGFloat	bundleHeightAdjust = (-1.0 * [[self.bundleViewController view] frame].size.height);
	if ([self.mailBundleList count] <= (NSUInteger)([self.scrollView frame].size.width / [[self.bundleViewController view] frame].size.width)) {
		//	Adjust the window, scrollview and background image size.
		[self.scrollView setFrame:LKRectByAdjustingHeight([self.scrollView frame], bundleHeightAdjust)];
		[self.backgroundView setFrame:LKRectByAdjustingHeight([self.backgroundView frame], bundleHeightAdjust)];
		[[self window] setFrame:LKRectByAdjustingHeight([[self window] frame], bundleHeightAdjust) display:NO];
	}
	
	[[self window] center];
	[[self window] makeKeyAndOrderFront:self];
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

- (IBAction)restartMail:(id)sender {
	
	//	If it is not running return
	if (!self.isMailRunning) {
		return;
	}
	
	//	Set up an observer for app termination watch
	__block id appDoneObserver;
	appDoneObserver = [[[NSWorkspace sharedWorkspace] notificationCenter] addObserverForName:NSWorkspaceDidTerminateApplicationNotification object:[NSWorkspace sharedWorkspace] queue:self.maintenanceQueue usingBlock:^(NSNotification *note) {
		
		if ([[[[note userInfo] valueForKey:NSWorkspaceApplicationKey] bundleIdentifier] isEqualToString:kMBMMailBundleIdentifier]) {
			
			//	Launch Mail again
			[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:kMBMMailBundleIdentifier options:NSWorkspaceLaunchWithoutActivation additionalEventParamDescriptor:nil launchIdentifier:NULL];
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
	}
}


#pragma mark - Maintenance Task Management

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


@end
