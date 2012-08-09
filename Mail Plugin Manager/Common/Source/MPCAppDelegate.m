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

#import "MPTPluginMacros.h"

#define LAUNCH_CONTROL_PATH			@"/bin/launchctl"
#define LAUNCH_AGENT_FOLDER_NAME	@"LaunchAgents"


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

//	launchd management
- (NSDictionary *)launchdConfigurations;
- (NSDictionary *)launchdConfigurationsWithPrefix:(NSString *)prefix;
- (BOOL)addLaunchDDictionary:(NSDictionary *)launchDict forLabel:(NSString *)label replace:(BOOL)replace;
- (BOOL)unloadLaunchControlAtPath:(NSString *)filePath;
- (BOOL)loadLaunchControlAtPath:(NSString *)filePath;
- (NSString *)likelyPluginToolPath;

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



#pragma mark - Launchd Methods

- (NSString *)likelyPluginToolPath {
	MPTGetLikelyToolPath();
	
	//	Add on our complete path to the executable
	mptPluginToolPath = [[mptPluginToolPath stringByAppendingPathComponent:MPT_APP_CODE_PATH] stringByAppendingPathComponent:MPT_TOOL_NAME];
	//	Validate that it exists
	if (IsEmpty(mptPluginToolPath) || ![mptManager fileExistsAtPath:mptPluginToolPath]) {
		LKErr(@"Cannot find the %@ app to create launchd config.", MPT_TOOL_NAME);
		return nil;
	}
	
	return mptPluginToolPath;
}

- (NSDictionary *)launchdConfigurations {
	return [self launchdConfigurationsWithPrefix:MPT_LKS_BUNDLE_START];
}

- (NSDictionary *)launchdConfigurationsWithPrefix:(NSString *)prefix {
	
	NSFileManager	*manager = [NSFileManager defaultManager];
	NSString		*shellPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension:@".sh"]];
	if (![manager fileExistsAtPath:shellPath]) {
		NSString	*grepCommand = [NSString stringWithFormat:@"#/bin/sh\n%@ list | grep %@\n", LAUNCH_CONTROL_PATH, prefix];
		NSError		*error;
		if (![grepCommand writeToFile:shellPath atomically:NO encoding:NSUTF8StringEncoding error:&error]) {
			LKLog(@"Error writing shell command to tempfile:%@", shellPath);
		}
	}
	else {
		return nil;
	}
	
	//	Get the list of my configs
	NSTask	*launchControlListTask = [[NSTask alloc] init];
	[launchControlListTask setLaunchPath:@"/bin/sh"];
	[launchControlListTask setArguments:@[shellPath]];
	
	NSPipe	*pipe = [NSPipe pipe];
	[launchControlListTask setStandardOutput:pipe];
	NSFileHandle *file = [pipe fileHandleForReading];
	
	//	Run launchctl and give it a bit to run, since it doesn't seem to finish until we kill the task
	[launchControlListTask launch];
	[launchControlListTask waitUntilExit];
	
	NSString	*tempString = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
	NSArray		*launchLines = [tempString componentsSeparatedByString:@"\n"];

	[launchControlListTask release];
	[tempString release];
	
	//	Strip out the labels of any of thre desired configs within it (for verification)
	NSMutableArray	*myLists = [NSMutableArray array];
	for (NSString *aLine in launchLines) {
		NSRange	myDomainRange = [aLine rangeOfString:prefix];
		if (myDomainRange.location != NSNotFound) {
			[myLists addObject:[aLine substringFromIndex:myDomainRange.location]];
		}
	}
	
	LKLog(@"Found lists are:%@", myLists);
	
	//	For each of those, get the xml plist data and turn it into a dict
	NSMutableDictionary	*myConfigs = [NSMutableDictionary dictionaryWithCapacity:[myLists count]];
	for (NSString *myAgent in myLists) {
		
		NSTask	*launchControlConfigTask = [[NSTask alloc] init];
		[launchControlConfigTask setLaunchPath:LAUNCH_CONTROL_PATH];
		[launchControlConfigTask setArguments:@[@"list", @"-x", myAgent]];
		
		NSPipe	*pipeOut = [NSPipe pipe];
		NSPipe	*pipeError = [NSPipe pipe];
		[launchControlConfigTask setStandardOutput:pipeOut];
		[launchControlConfigTask setStandardError:pipeError];
		NSFileHandle *fileOut = [pipeOut fileHandleForReading];
		NSFileHandle *fileError = [pipeError fileHandleForReading];
		
		//	Run launchctl and give it a bit to run, since it doesn't seem to finish until we kill the task
		[launchControlConfigTask launch];
		
		//	Try to get the data from the standard out, but for some reason (at least on Lion) it is returned in standard error
		//	Allow for either, preferring the out - in case th ebug gets fixed
		tempString = [[NSString alloc] initWithData:[fileOut readDataToEndOfFile] encoding:NSUTF8StringEncoding];
		if (IsEmpty(tempString)) {
			[tempString release];
			tempString = [[NSString alloc] initWithData:[fileError readDataToEndOfFile] encoding:NSUTF8StringEncoding];
		}
		id propList = nil;
		@try {
			propList = [tempString propertyList];
		}
		@catch (NSException *exception) {
			//	Should be an NSParseErrorException
			//	Just set it to an empty dictionary
			propList = [NSDictionary dictionary];
		}
		[myConfigs setObject:propList forKey:myAgent];
		
		[launchControlConfigTask release];
		[tempString release];
	}
	
	LKLog(@"Found configs are:%@", myConfigs);
	
	return [NSDictionary dictionaryWithDictionary:myConfigs];
}

- (BOOL)runLaunchControlWithCommand:(NSString *)command andPath:(NSString *)filePath {
	
	//	Then call launchctl to load it
	//	Get the list of my configs
	NSTask	*launchControlTask = [[NSTask alloc] init];
	[launchControlTask setLaunchPath:LAUNCH_CONTROL_PATH];
	[launchControlTask setArguments:@[command, filePath]];
	
	NSPipe	*pipeOut = [NSPipe pipe];
	NSPipe	*pipeError = [NSPipe pipe];
	[launchControlTask setStandardOutput:pipeOut];
	[launchControlTask setStandardError:pipeError];
	NSFileHandle *fileOut = [pipeOut fileHandleForReading];
	NSFileHandle *fileError = [pipeError fileHandleForReading];
	
	//	Run launchctl and ensure that there were no errors
	BOOL	result = NO;
	[launchControlTask launch];
	[launchControlTask waitUntilExit];
	NSData	*outData = [fileOut readDataToEndOfFile];
	NSData	*errorData = [fileError readDataToEndOfFile];
	if (IsEmpty(outData) && IsEmpty(errorData)) {
		result = YES;
	}
	else {
		NSString	*tempString = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
		LKErr(@"Error out on %@ is:'%@'", command, tempString);
		[tempString release];
		tempString = [[NSString alloc] initWithData:outData encoding:NSUTF8StringEncoding];
		LKErr(@"Standard out on %@ is:'%@'", command, tempString);
		[tempString release];
	}
	[launchControlTask release];
	
	return result;
}

- (BOOL)loadLaunchControlAtPath:(NSString *)filePath {
	
	//	Ensure that the file exists at the given path
	if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		return NO;
	}
	
	//	Get label from lastPathComponent
	NSString		*label = [[filePath lastPathComponent] stringByDeletingPathExtension];
	
	//	Get configs
	NSDictionary	*configs = [self launchdConfigurationsWithPrefix:label];
	
	//	If it is already loaded, unload it
	if ([[configs allKeys] containsObject:label]) {
		[self unloadLaunchControlAtPath:filePath];
	}
	
	//	Then call launchctl to load it and return the results
	return [self runLaunchControlWithCommand:@"load" andPath:filePath];
}

- (BOOL)unloadLaunchControlAtPath:(NSString *)filePath {
	
	//	Ensure that the file exists at the given path
	if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
		return NO;
	}
	
	//	Get label from lastPathComponent
	NSString		*label = [[filePath lastPathComponent] stringByDeletingPathExtension];
	
	//	Get configs
	NSDictionary	*configs = [self launchdConfigurationsWithPrefix:label];
	
	//	If it is not already loaded, nothing to do
	if (![[configs allKeys] containsObject:label]) {
		return YES;
	}
	
	//	Then call launchctl to unload it and return the results
	return [self runLaunchControlWithCommand:@"unload" andPath:filePath];
}

- (BOOL)addLaunchDDictionary:(NSDictionary *)launchDict forLabel:(NSString *)label replace:(BOOL)replace {
	
	//	If the dict is empty, nothing to do
	if (IsEmpty(launchDict)) {
		return NO;
	}
	
	//	Get values
	NSFileManager	*manager = [NSFileManager defaultManager];
	NSString		*fullPath = [[[[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:LAUNCH_AGENT_FOLDER_NAME] stringByAppendingPathComponent:label] stringByAppendingPathExtension:kMPCPlistExtension];
	
	//	See if that label is already active we are done
	if (!IsEmpty([self launchdConfigurationsWithPrefix:label])) {
		//	Try to unload the configuration
		if (replace) {
			if ([self unloadLaunchControlAtPath:fullPath]) {
				LKLog(@"Launchd config for %@ has been unloaded successfully", label);
			}
			else {
				LKLog(@"Launchd config for %@ is already loaded and I can't unload it", label);
				return YES;
			}
		}
		else {
			LKLog(@"Launchd config for %@ is already loaded - not replacing", label);
			return YES;
		}
	}
	
	//	If the path exists already, move it to the trash
	if ([manager fileExistsAtPath:fullPath]) {
		NSError		*removeError;
		if (![manager removeItemAtPath:fullPath error:&removeError]) {
			LKErr(@"Cannot delete existing launch agent file (%@) - Error:%@.", [fullPath lastPathComponent], removeError);
			return NO;
		}
	}
	
	//	If the file still exists, just leave
	if ([manager fileExistsAtPath:fullPath]) {
		return NO;
	}
	
	//	Use the dictionary to write the file out using the constructed path
	[launchDict writeToFile:fullPath atomically:YES];
	
	//	Ensure that the file was successful
	if (![manager fileExistsAtPath:fullPath]) {
		LKErr(@"Couldn't write the launchd plist file for label:%@", label);
		return NO;
	}
	
	//	Run launch control to load the file
	return [self loadLaunchControlAtPath:fullPath];
	
}

- (BOOL)installStartupLaunchdConfigReplacingIfNeeded:(BOOL)replace {
	
	NSString	*label = [MPT_LKS_BUNDLE_START stringByAppendingString:[NSString stringWithFormat:@"%@-Startup", MPT_TOOL_NAME]];
	NSString	*pluginToolPath = [self likelyPluginToolPath];
	
	if (pluginToolPath == nil) {
		return NO;
	}
	
	//	Build the dictionary
	NSDictionary	*watchDict = @{ @"Label" : label, @"KeepAlive" : @NO, @"ProgramArguments" : @[ pluginToolPath, kMPCCommandLineValidateAllKey ], @"RunAtLoad" : @YES };
	LKLog(@"dict:%@", watchDict);
	return [self addLaunchDDictionary:watchDict forLabel:label replace:replace];
}

- (BOOL)installToolWatchLaunchdConfigReplacingIfNeeded:(BOOL)replace {
	
	NSString	*label = [MPT_LKS_BUNDLE_START stringByAppendingString:[NSString stringWithFormat:@"%@-Watcher", MPT_TOOL_NAME]];
	NSString	*pluginToolPath = [self likelyPluginToolPath];
	
	if (pluginToolPath == nil) {
		return NO;
	}
	
	//	Build the dictionary
	NSDictionary	*watchDict = @{ @"Label" : label, @"KeepAlive" : @NO, @"ProgramArguments" : @[ pluginToolPath, kMPCCommandLineFileLoadKey ], @"QueueDirectories" : @[ MPTPerformFolderPath() ] };
	LKLog(@"dict:%@", watchDict);
	return [self addLaunchDDictionary:watchDict forLabel:label replace:replace];
}

- (BOOL)installLaunchAgentForConfig:(NSDictionary *)agentConfig replacingIfNeeded:(BOOL)replace {
	NSString		*label = [agentConfig valueForKey:@"Label"];
	return [self addLaunchDDictionary:agentConfig forLabel:label replace:replace];
}

- (BOOL)removeLaunchAgentForLabel:(NSString *)label {
	//	Get values
	NSFileManager	*manager = [NSFileManager defaultManager];
	NSString		*fullPath = [[[[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:LAUNCH_AGENT_FOLDER_NAME] stringByAppendingPathComponent:label] stringByAppendingPathExtension:kMPCPlistExtension];

	if (![manager fileExistsAtPath:fullPath]) {
		return NO;
	}
	BOOL	result = [self unloadLaunchControlAtPath:fullPath];
	
	//	Also delete the file as well
	NSError	*error;
	if (![manager removeItemAtPath:fullPath error:&error]) {
		LKLog(@"Error removing file:%@", error);
	}
	
	return result;
	
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-security"
			
			NSAlert		*quitMailAlert = [NSAlert alertWithMessageText:messageText defaultButton:defaultButton alternateButton:altButton otherButton:nil informativeTextWithFormat:infoText];

#pragma clang diagnostic pop
			
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
				//	Send a notification to indicate what was selected
				[[NSNotificationCenter defaultCenter] postNotificationName:kMPCRestartMailNowNotification object:nil];
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


#pragma mark - Migrate Bundle Prefs

#define DAY_INTERVAL					(60 * 60 * 24)

- (BOOL)bestGuessIfWeShouldMigrateFromPath:(NSString *)fromPath toPath:(NSString *)toPath {
	
	//	if there is a migrated flag set to yse in the toPath, we should not
	LKLog(@"Migrate flag in toPath:%@", [self migratedFlagFromPrefsAtPath:toPath]);
	if ([[self migratedFlagFromPrefsAtPath:toPath] isEqualToString:@"1"]) {
		return NO;
	}
	
	NSFileManager	*manager = [NSFileManager defaultManager];
	NSDictionary	*fromAttributes = [manager attributesOfItemAtPath:fromPath error:NULL];
	NSDictionary	*toAttributes = [manager attributesOfItemAtPath:toPath error:NULL];
	NSInteger		ranking = 0;
	
	LKLog(@"FromAttr:%@", fromAttributes);
	LKLog(@"ToAttr:%@", toAttributes);
	
	//	Compare file creation dates (if from is older than to by 30 days or more  +1)
	//	Old ones were created at least a month before the newer ones
	if ([[[fromAttributes fileCreationDate] dateByAddingTimeInterval:(30 * DAY_INTERVAL)] isLessThan:[toAttributes fileCreationDate]]) {
		ranking++;
		LKLog(@"Added for 1");
	}
	
	//	Compare file modification dates (if from is older than to by 15 days or more  -1)
	//	The new prefs have been modified over 2 weeks after the old, so the new ones are probably more up to date
	if ([[[fromAttributes fileModificationDate] dateByAddingTimeInterval:(15 * DAY_INTERVAL)] isLessThan:[toAttributes fileModificationDate]]) {
		ranking--;
		LKLog(@"Subtracted for 2");
	}
	
	//	Compare modified of from to creation of to (if from mod happened within the 3 days before the to creation  +1)
	//	Last change to old ones are close to creation of new ones
	if (([[toAttributes fileCreationDate] isLessThan:[[fromAttributes fileModificationDate] dateByAddingTimeInterval:(3 * DAY_INTERVAL)]]) &&
		([[fromAttributes fileModificationDate] isLessThan:[toAttributes fileCreationDate]])) {
		ranking++;
		LKLog(@"Added for 3");
	}
	
	//	Compare size of files (if from is greater than to +1, if more than double +1)
	//	Bigger is *most likely* newer,much bigger even more so
	NSInteger	fromSize = (NSInteger)[fromAttributes fileSize];
	NSInteger	toSize = (NSInteger)[toAttributes fileSize];
	if (fromSize > toSize) {
		ranking++;
	}
	if (fromSize > (2 * toSize)) {
		ranking++;
		LKLog(@"Added for 4");
	}
	
	//	Compare creation and modified of to (if less than 1 hour apart +1)
	//	The new ones haven't been changed long after creation
	if ([[toAttributes fileModificationDate] isLessThan:[[toAttributes fileCreationDate] dateByAddingTimeInterval:(60 * 60)]]) {
		ranking++;
		LKLog(@"Added for 5");
	}
	
	//	Compare creation to (if less than 6 hours ago  +1)
	//	The new ones were created today
	if ([[NSDate date] isLessThan:[[toAttributes fileCreationDate] dateByAddingTimeInterval:(6 * 60 * 60)]]) {
		ranking++;
		LKLog(@"Added for 6");
	}
	
	LKLog(@"The Ranking is:%@", [NSNumber numberWithInteger:ranking]);
	//	If ranking > 2, best guess is yes.
	return (ranking > 2);
}

- (NSString *)migratedFlagFromPrefsAtPath:(NSString *)prefsPath {
	
	//	Ensure that the path exists
	if (![[NSFileManager defaultManager] fileExistsAtPath:prefsPath]) {
		return nil;
	}
	
	//	remove the extension
	if ([prefsPath hasSuffix:kMPCPlistExtension]) {
		prefsPath = [prefsPath stringByDeletingPathExtension];
	}
	
	NSTask *enabledTask = [[NSTask alloc] init];
	[enabledTask setLaunchPath:@"/usr/bin/defaults"];
	[enabledTask setArguments:@[@"read", prefsPath, kMPCPrefsMigratedToSandboxPrefKey]];
	
	NSPipe *pipe = [NSPipe pipe];
	[enabledTask setStandardOutput:pipe];
	NSFileHandle *file = [pipe fileHandleForReading];
	
	[enabledTask launch];
	[enabledTask waitUntilExit];
	
	NSString *tempString = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];
	NSString *enabledString = [tempString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (![enabledString isEqualToString:@"0"] || ![enabledString isEqualToString:@"1"]) {
		enabledString = nil;
	}
	
	[enabledTask release];
	[tempString release];
	
	return enabledString;
}

- (void)addMigratedFlagToPrefsAtPath:(NSString *)prefsPath migrated:(BOOL)migrated {
	
	LKLog(@"Adding flag for path %@", prefsPath);
	//	Don't write over the prefs that were migrated already with a false value
	if (!migrated && [[self migratedFlagFromPrefsAtPath:prefsPath] isEqualToString:@"1"]) {
		LKInfo(@"Avoiding resetting migration flag from YES to NO");
		return;
	}
	
	NSMutableDictionary	*prefs = [[NSDictionary dictionaryWithContentsOfFile:prefsPath] mutableCopy];
	[prefs setObject:[NSNumber numberWithBool:migrated] forKey:kMPCPrefsMigratedToSandboxPrefKey];
	
	NSString	*errorDesc;
	NSData		*plistData = [NSPropertyListSerialization dataFromPropertyList:prefs format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errorDesc];
	
	if (plistData != nil) {
		[plistData writeToFile:prefsPath atomically:YES];
	}
	else {
		LKErr(@"Error trying to add migration flag:%@", errorDesc);
	}
	[prefs release];
	
}

- (void)migratePrefsIntoSandboxIfRequiredForMailBundle:(MPCMailBundle *)mailBundle {
	NSString		*libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
	NSString		*plistName = [mailBundle.identifier stringByAppendingPathExtension:kMPCPlistExtension];
	NSString		*sandboxPrefsPath = [[[libraryPath stringByAppendingPathComponent:[NSString stringWithFormat:kMPCContainersPathFormat, kMPCMailBundleIdentifier]] stringByAppendingPathComponent:kMPCPreferencesFolderName] stringByAppendingPathComponent:plistName];
	NSString		*prefsPath = [[libraryPath stringByAppendingPathComponent:kMPCPreferencesFolderName] stringByAppendingPathComponent:plistName];
	NSFileManager	*manager = [[[NSFileManager alloc] init] autorelease];
	
	//	First check to see if we should even bother, by seeing if the sandbox exists
	if (![manager fileExistsAtPath:[sandboxPrefsPath stringByDeletingLastPathComponent]]) {
		return;
	}
	
	//	Also test to see if we have old prefs that would need to be migrated
	//	If not found, nothing to do
	if (![manager fileExistsAtPath:prefsPath]) {
		LKLog(@"No normal prefs found");
		return;
	}
	
	//	If we have a sandbox file...
	if ([manager fileExistsAtPath:sandboxPrefsPath]) {
		NSString	*migrateFlag = [self migratedFlagFromPrefsAtPath:sandboxPrefsPath];
		LKLog(@"Has a sandboxed prefs - migrate flag in prefs:%@", migrateFlag);
		//	If there is no setting in the sandbox prefs, look at the default prefs
		if (migrateFlag == nil) {
			migrateFlag = [self migratedFlagFromPrefsAtPath:prefsPath];
			LKLog(@"Loaded migrate flag in basic prefs:%@", migrateFlag);
		}
		//	If we have migrated, then return done
		if ([migrateFlag isEqualToString:@"1"]) {
			return;
		}
		
		//	Otherwise if we don't know if migration has occurred, see if we can somehow guess that we need to migrate or not
		if ((migrateFlag == nil) && ![self bestGuessIfWeShouldMigrateFromPath:prefsPath toPath:sandboxPrefsPath]) {
			return;
		}
	}
	
	//	Then move any existing file in the sandbox aside as a backup in case
	NSError	*error;
	NSDateFormatter	*formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"ddMMyyyy-HHmm"];
	NSString		*backupName = [[[sandboxPrefsPath stringByDeletingPathExtension] stringByAppendingFormat:@".Backup-%@", [formatter stringFromDate:[NSDate date]]] stringByAppendingPathExtension:kMPCPlistExtension];
	[formatter release];
	if ([manager fileExistsAtPath:sandboxPrefsPath] && ![manager moveItemAtPath:sandboxPrefsPath toPath:backupName error:&error]) {
		//	If failed, just log and leave
		LKErr(@"Couldn't rename the sandboxed prefs file for %@ to %@ during migration:%@", mailBundle.identifier, [backupName lastPathComponent], error);
	}
	else {
		//	Otherwise try to copy our new file into the sandbox
		LKLog(@"Trying to copy '%@' to sandbox '%@'", prefsPath, sandboxPrefsPath);
		if ([manager copyItemAtPath:prefsPath toPath:sandboxPrefsPath error:&error]) {
			//	Then add a migration flag to both of those migrated prefs
			[self addMigratedFlagToPrefsAtPath:prefsPath migrated:YES];
			[self addMigratedFlagToPrefsAtPath:sandboxPrefsPath migrated:YES];
			//	Try to move the original to a migrated file (that way further tests don't use it
			[manager moveItemAtPath:prefsPath toPath:[[[prefsPath stringByDeletingPathExtension] stringByAppendingString:@".migrated"] stringByAppendingPathExtension:kMPCPlistExtension] error:NULL];
		}
		else {
			LKErr(@"Couldn't copy the prefs into the sandbox for %@ during migration: %@", mailBundle.identifier, error);
		}
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
