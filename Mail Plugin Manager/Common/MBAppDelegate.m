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

@interface MBAppDelegate ()
- (void)applicationChangeForNotification:(NSNotification *)note;
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
	self.counterQueue = [[[NSOperationQueue alloc] init] autorelease];
	[self.counterQueue setMaxConcurrentOperationCount:1];
	
	//	Load the process to put in place our uuids file
	[self addMaintenanceTask:^{
		[MBMUUIDList loadListFromCloud];
	}];
	
	//	Load the process to put in place our companies file
	[self addMaintenanceTask:^{
		[MBMCompanyList loadListFromCloud];
	}];

}

- (void)applicationWillTerminate:(NSNotification *)notification {
	if (self.bundleUninstallObserver != nil) {
		[[NSNotificationCenter defaultCenter] removeObserver:self.bundleUninstallObserver];
		self.bundleUninstallObserver = nil;
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

- (IBAction)restartMail:(id)sender {
	[self restartMailWithBlock:nil];
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




#pragma mark - Maintenance Task Management

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


- (void)addMaintenanceTask:(void (^)(void))block {

	NSBlockOperation	*main = [NSBlockOperation blockOperationWithBlock:block];
	[self addMaintenanceOperation:main];
}

- (void)addMaintenanceOperation:(NSOperation *)operation {
	[self addOperation:operation forQueueNamed:@"Maintenance"];
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


@end
