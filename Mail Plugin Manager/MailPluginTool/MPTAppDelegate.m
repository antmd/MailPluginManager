//
//  MBTAppDelegate.m
//  MailBundleTool
//
//  Created by Scott Little on 28/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MPTAppDelegate.h"
#import "MPCMailBundle.h"
#import "MPCUUIDList.h"
#import "MPCSystemInfo.h"
#import "MPTSinglePluginController.h"
#import "LKCGStructs.h"
#import "NSString+LKHelper.h"
#import "NSUserDefaults+MPCShared.h"
#import "MPTReporterAsyncOperation.h"

#import "MPTPluginMacros.h"

#define HOURS_AGO	(-1 * 60 * 60)



@interface MPTAppDelegate ()
@property	(nonatomic, copy)	NSMutableDictionary			*savedSparkleState;
@property	(nonatomic, retain)	NSArray						*sparkleKeysValues;
@property	(nonatomic, assign) MPCSparkleAsyncOperation	*sparkleOperation;
@property	(nonatomic, retain) SUBasicUpdateDriver			*updateDriver;
@property	(nonatomic, retain)	NSDictionary				*performDictionary;


//	Actions
- (NSString *)pathToManagerContainer;
- (void)validateAllBundles;
- (void)showUserInvalidBundles:(NSArray *)bundlesToTest;
- (BOOL)checkFrequency:(NSUInteger)frequency forActionType:(MPTActionType)action onBundle:(MPCMailBundle *)mailBundle;

- (void)managerSparkleCompleted:(NSNotification *)note;

@end

@implementation MPTAppDelegate

@synthesize savedSparkleState = _savedSparkleState;
@synthesize sparkleKeysValues = _sparkleKeysValues;
@synthesize sparkleOperation = _sparkleOperation;
@synthesize updateDriver = _updateDriver;
@synthesize performDictionary = _performDictionary;


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
	[self doAction:[self actionTypeForString:action] withArguments:arguments shouldFinish:YES];
}


#pragma mark - Memory Management

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
		
	}
	return self;
}

- (void)dealloc {
	self.updateDriver = nil;
	self.savedSparkleState = nil;
	self.sparkleKeysValues = nil;
	
	[super dealloc];
}



#pragma mark - Application Events

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	LKLog(@"Inside the MailBundleTool - Path is:'%@'", [[NSBundle mainBundle] bundlePath]);

	//	Call our super
	[super applicationDidFinishLaunching:aNotification];
	
	//	Install the launchd tool, if it hasn't been done
	[self addFinalizeTask:^{
		[self installToolWatchLaunchdConfigReplacingIfNeeded:NO];
	}];
	
	self.finalizeQueueRequiresExplicitRelease = NO;

	//	Get Path for the Mail Plugin Manager container
	NSString	*mpmPath = [self pathToManagerContainer];
	
	//	Report crashes for the tool app
	[self addFinalizeOperation:[[[MPTReporterAsyncOperation alloc] initWithBundle:[NSBundle mainBundle]] autorelease]];
	
	//	See if we just need to get ourselves registered.
	BOOL	finishInstallRun = NO;
	BOOL	needToLoadFile = NO;
	NSArray	*arguments = [[NSProcessInfo processInfo] arguments];
	LKLog(@"########## Arguments passed into MPT are:%@", arguments);
	if ([arguments count] > 0) {
		for (NSString *anArg in arguments) {
			if ([anArg isEqualToString:kMPCCommandLineFinishInstallKey]) {
				finishInstallRun = YES;
				break;
			}
			else if ([anArg isEqualToString:kMPCCommandLineFileLoadKey]) {
				LKLog(@"Should load files");
				needToLoadFile = YES;
				break;
			}
		}
	}
	
	//	Currently don't support Sparkle updating for just the Tool, so only do this if contained with the Manager and if that is writable by the user.
	LKLog(@"mpmPath is:%@", mpmPath);
	if (!finishInstallRun && (mpmPath != nil) && [mpmPath userHasAccessRights]) {
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
		
		LKLog(@"About to call Sparkle stuff");
		
		//	Ensure that the bundle gives a non-nil bundle id
		if ([managerBundle bundleIdentifier] != nil) {
			//	Test for an update quietly
			SUUpdater	*managerUpdater = [SUUpdater updaterForBundle:managerBundle];
			[managerUpdater resetUpdateCycle];
			managerUpdater.delegate = self;
			//	May need to save the state of this value and restore afterward
			[self setupSparkleEnvironment];
			
			//	Report crashes for the manager app
			[self addFinalizeOperation:[[[MPTReporterAsyncOperation alloc] initWithBundle:[NSBundle bundleWithPath:mpmPath]] autorelease]];

			//	Run a background thread to see if we need to update this app, using the basic updater directly.
			self.updateDriver = [[[SUBasicUpdateDriver alloc] initWithUpdater:managerUpdater] autorelease];
			self.sparkleOperation = [[[MPCSparkleAsyncOperation alloc] initWithUpdateDriver:self.updateDriver updater:managerUpdater] autorelease];
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerSparkleCompleted:) name:kMPCSUUpdateDriverAbortNotification object:self.updateDriver];
			[self addFinalizeOperation:self.sparkleOperation];
		}
	}
	
	//	Find a file in the path and load it
	if (needToLoadFile) {

		NSFileManager	*manager = [NSFileManager defaultManager];
		NSString		*basePath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:MPT_MAIL_MPT_FOLDER_PATH];
		for (NSString *filename in [manager contentsOfDirectoryAtPath:basePath error:NULL]) {
			LKLog(@"Open file with name:%@", filename);
			NSString	*extension = [filename pathExtension];
			if ([extension isEqualToString:MPT_PERFORM_ACTION_EXTENSION]) {
				NSString	*fullPath = [basePath stringByAppendingPathComponent:filename];
				self.performDictionary = [NSDictionary dictionaryWithContentsOfFile:fullPath];
				[manager removeItemAtPath:fullPath error:NULL];

				NSString		*action = [self.performDictionary objectForKey:MPT_ACTION_KEY];
				NSMutableArray	*args = [NSMutableArray arrayWithCapacity:3];
				if (!IsEmpty(action) && !IsEmpty([self.performDictionary objectForKey:MPT_PLUGIN_PATH_KEY])) {
					[args addObject:[self.performDictionary objectForKey:MPT_PLUGIN_PATH_KEY]];
					if ([self.performDictionary objectForKey:MPT_FREQUENCY_KEY] != nil) {
						[args addObject:kMPCCommandLineFrequencyOptionKey];
						[args addObject:[self.performDictionary objectForKey:MPT_FREQUENCY_KEY]];
					}
					if ([self.performDictionary objectForKey:MPT_OTHER_VALUES_KEY] != nil) {
						[args addObject:[self.performDictionary objectForKey:MPT_OTHER_VALUES_KEY]];
					}
					[self doAction:[self actionTypeForString:action] withArguments:args shouldFinish:NO];
				}
				
			}
		}
		[self quittingNowIsReasonable];
	
	}
	else {
		[self processArguments];
	}

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
		NSURL		*managerURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:kMPCMailPluginManagerBundleID];
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

- (MPTActionType)actionTypeForString:(NSString *)action {
	MPTActionType	type = MPTActionNone;
	
	if ([kMPCCommandLineUninstallKey isEqualToString:action]) {
		type = MPTActionUninstall;
	}
	else if ([kMPCCommandLineUpdateKey isEqualToString:action]) {
		type = MPTActionUpdate;
	}
	else if ([kMPCCommandLineCheckCrashReportsKey isEqualToString:action]) {
		type = MPTActionCheckCrashReports;
	}
	else if ([kMPCCommandLineUpdateAndCrashReportsKey isEqualToString:action]) {
		type = MPTActionUpdateAndCrashReports;
	}
	else if ([kMPCCommandLineSystemInfoKey isEqualToString:action]) {
		type = MPTActionSystemInfo;
	}
	else if ([kMPCCommandLineUUIDListKey isEqualToString:action]) {
		type = MPTActionUUIDList;
	}
	else if ([kMPCCommandLineValidateAllKey isEqualToString:action]) {
		type = MPTActionValidateAll;
	}
	else if ([kMPCCommandLineInstallLaunchAgentKey isEqualToString:action]) {
		type = MPTActionInstallLaunchAgent;
	}
	else if ([kMPCCommandLineRemoveLaunchAgentKey isEqualToString:action]) {
		type = MPTActionRemoveLaunchAgent;
	}
	else if ([kMPCCommandLineInstallScriptKey isEqualToString:action]) {
		type = MPTActionInstallScriptAgent;
	}
	else if ([kMPCCommandLineRemoveScriptKey isEqualToString:action]) {
		type = MPTActionRemoveScriptAgent;
	}
	
	return type;
}


#pragma mark - Action Methods

- (void)handleLaunchAgentForBundle:(NSBundle *)bundle withArgs:(NSArray *)arguments block:(BOOL (^)(NSDictionary *otherValues))actionBlock {
	
	NSError		*error = nil;
	if ([arguments count] > 1) {
		NSDictionary	*otherValues = [arguments objectAtIndex:1];
		if (!actionBlock(otherValues)) {
			error = [NSError errorWithDomain:MPT_LAUNCHD_ERROR_DOMAIN_NAME code:MPT_LAUNCHD_INSTALL_FAILED_ERROR_CODE userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Could not configure a launch agent properly for plugin with id '%@'", @"Error message indicating that a launch agent couldn't be configured for the plugin"), [bundle bundleIdentifier]] }];
		}
	}
	else {
		error = [NSError errorWithDomain:MPT_LAUNCHD_ERROR_DOMAIN_NAME code:MPT_LAUNCHD_BAD_ARGUMENTS_ERROR_CODE userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:NSLocalizedString(@"Invalid arguments passed to configure a launch agent: %@", @"Error message telling the caller that the arguments for the configure launch agent were not correct"), [bundle bundleIdentifier]] }];
	}
	NSDistributedNotificationCenter	*center = [NSDistributedNotificationCenter defaultCenter];
	NSDictionary	*infoDict = nil;
	if (error != nil) {
		infoDict = @{ MPT_LAUNCH_ERROR_KEY : error };
	}
	[center postNotificationName:MPT_LAUNCHD_DONE_NOTIFICATION object:[bundle bundleIdentifier] userInfo:infoDict deliverImmediately:YES];

}

- (void)handleScriptWithArgs:(NSArray *)arguments shouldInstall:(BOOL)shouldInstall {

	NSDictionary	*otherValues = [arguments objectAtIndex:1];
	NSString		*sourceScriptPath = [otherValues valueForKey:MPT_SCRIPT_KEY];
	BOOL			shouldRun = [[otherValues valueForKey:MPT_RUN_SCRIPT_KEY] boolValue];
	//	Optional values
	NSString		*destinationScriptPath = [otherValues valueForKey:MPT_SCRIPT_DESTINATION_KEY];

	if (destinationScriptPath == nil) {
		NSString	*appScriptsFolder = [[[[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"Application Scripts"] stringByAppendingPathComponent:kMPCMailBundleIdentifier] stringByExpandingTildeInPath];
		NSString	*appScriptsSubFolderName = [otherValues valueForKey:MPT_SCRIPT_FOLDER_NAME_KEY];
		if (appScriptsSubFolderName != nil) {
			appScriptsFolder = [appScriptsFolder stringByAppendingPathComponent:appScriptsSubFolderName];
		}
		destinationScriptPath = [appScriptsFolder stringByAppendingPathComponent:[sourceScriptPath lastPathComponent]];
	}

	NSFileManager	*fileManager = [[[NSFileManager alloc] init] autorelease];
	NSError			*error;
	if (shouldInstall) {
		BOOL			scriptDestinationFolderIsFolder = NO;
		NSString		*destinationFolder = [destinationScriptPath stringByDeletingLastPathComponent];
		//	Ensure that we have the destination directory
		if (![fileManager fileExistsAtPath:destinationFolder isDirectory:&scriptDestinationFolderIsFolder] || !scriptDestinationFolderIsFolder) {
			LKLog(@"Script destination folder not found - will try to create");
			if ([fileManager createDirectoryAtPath:destinationFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
				scriptDestinationFolderIsFolder = YES;
			}
		}
		if (!scriptDestinationFolderIsFolder) {
			LKErr(@"There was an error trying to create the Destination Script folder, could not proceed.\n%@", error);
			return;
		}
		
		LKLog(@"Should have correct paths");
		//	Copy my script to Application Scripts folder
		if (![fileManager copyItemAtPath:sourceScriptPath toPath:destinationScriptPath error:&error]) {
			//	Handle error
			LKErr(@"Error copying the rename script to its destination:%@", error);
			return;
		}

		//	Run it with correct values
		if (shouldRun) {
			[NSTask launchedTaskWithLaunchPath:@"/usr/bin/osascript" arguments:@[destinationScriptPath]];
		}
	}
	else {
		//	Ensure that we have the destination script to remove
		if ([fileManager fileExistsAtPath:sourceScriptPath]) {
			LKLog(@"Script found to remove - will try to do so");
			if (![fileManager removeItemAtPath:sourceScriptPath error:&error]) {
				LKErr(@"Error removing script '%@':%@", [sourceScriptPath lastPathComponent], error);
			}
		}
	}
	
}


- (void)doAction:(MPTActionType)action withArguments:(NSArray *)arguments shouldFinish:(BOOL)shouldFinish {
	
	NSString	*bundlePath = nil;
	NSInteger	frequencyInHours = 0;
	BOOL		forceUpdate = NO;
	
	
	LKLog(@"Arguments are:%@", arguments);
	if ([arguments count] > 0) {
		bundlePath = [arguments objectAtIndex:0];
		if ([bundlePath isEqualToString:@"(null)"]) {
			bundlePath = nil;
		}
	}
	if ((action < MPTActionInstallLaunchAgent) && ([arguments count] > 1)) {
		if ([[arguments objectAtIndex:1] isEqualToString:kMPCCommandLineFrequencyOptionKey]) {
			NSString	*frequencyType = [arguments objectAtIndex:2];
			if ([frequencyType isEqualToString:@"daily"]) {
				frequencyInHours = 24;
			}
			else if ([frequencyType isEqualToString:@"weekly"]) {
				frequencyInHours = 24 * 7;
			}
			else if ([frequencyType isEqualToString:@"monthly"]) {
				frequencyInHours = 24 * 7 * 28;
			}
			else if ([frequencyType isEqualToString:@"now"]) {
				forceUpdate = YES;
			}
		}
	}
	
	//	Get the mail bundle, if there
	MPCMailBundle	*mailBundle = nil;
	if (bundlePath) {
		mailBundle = [[[MPCMailBundle alloc] initWithPath:bundlePath shouldLoadUpdateInfo:NO] autorelease];
	}
	
	//	If there is no bundle for one of the tasks that require it, just quit
	if ((bundlePath == nil) && ((action == MPTActionUninstall) || (action == MPTActionUpdate) || (action == MPTActionCheckCrashReports) || (action == MPTActionUpdateAndCrashReports))) {
			//	Release the Activity Queue
			[self releaseActivityQueue];
	}
	else {
		LKLog(@"Valid bundlePath");
		switch (action) {
			case MPTActionUninstall:
				//	Tell it to uninstall itself
				[self addActivityTask:^{
					if ([mailBundle uninstall]) {
						[self askToRestartMailWithBlock:nil usingIcon:[mailBundle icon]];
					}
				}];
				break;
				
			case MPTActionUpdate:
				LKLog(@"update found");
				//	Tell it to update itself, if frequency requirements met
				if ([self checkFrequency:frequencyInHours forActionType:action onBundle:mailBundle]) {
					LKLog(@"Adding an update for bundle:'%@' to the queue", [[mailBundle path] lastPathComponent]);
					[self updateMailBundle:mailBundle force:forceUpdate];
				}
				break;
				
			case MPTActionCheckCrashReports:
				//	Tell it to check its crash reports, if frequency requirements met
				if ([self checkFrequency:frequencyInHours forActionType:action onBundle:mailBundle]) {
					LKLog(@"Sending crash reports");
					[self addActivityOperation:[[[MPTReporterAsyncOperation alloc] initWithMailBundle:mailBundle] autorelease]];
				}
				break;
				
			case MPTActionUpdateAndCrashReports:
				//	If frequency requirements met
				if ([self checkFrequency:frequencyInHours forActionType:action onBundle:mailBundle]) {
					[self addActivityOperation:[[[MPTReporterAsyncOperation alloc] initWithMailBundle:mailBundle] autorelease]];
					[self updateMailBundle:mailBundle force:forceUpdate];
				}
				break;
				
			case MPTActionSystemInfo:
				[self addActivityTask:^{
					//	Then send the information
					NSDistributedNotificationCenter	*center = [NSDistributedNotificationCenter defaultCenter];
					[center postNotificationName:kMPTSystemInfoDistNotification object:mailBundle.identifier userInfo:[MPCSystemInfo completeInfo] deliverImmediately:YES];
					LKLog(@"Sent notification");
					if (shouldFinish) {
						[self quittingNowIsReasonable];
					}
				}];
				break;
				
			case MPTActionUUIDList:
				[self addActivityTask:^{
					NSDistributedNotificationCenter	*center = [NSDistributedNotificationCenter defaultCenter];
					[center postNotificationName:kMPTUUIDListDistNotification object:mailBundle.identifier userInfo:[MPCUUIDList fullUUIDListFromBundle:mailBundle.bundle] deliverImmediately:YES];
					if (shouldFinish) {
						[self quittingNowIsReasonable];
					}
				}];
				break;
				
			case MPTActionInstallLaunchAgent:
				[self addActivityTask:^{
					
					[self handleLaunchAgentForBundle:mailBundle.bundle withArgs:arguments block:^BOOL(NSDictionary *otherValues) {
						NSDictionary	*agentDict = [otherValues valueForKey:MPT_LAUNCHD_CONFIG_DICT_KEY];
						BOOL			replaceAgent = [[otherValues valueForKey:MPT_REPLACE_LAUNCHD_KEY] boolValue];
						return [self installLaunchAgentForConfig:agentDict replacingIfNeeded:replaceAgent];
					}];
					
					if (shouldFinish) {
						[self quittingNowIsReasonable];
					}
				}];
				break;
				
			case MPTActionRemoveLaunchAgent:
				[self addActivityTask:^{
					
					[self handleLaunchAgentForBundle:mailBundle.bundle withArgs:arguments block:^BOOL(NSDictionary *otherValues) {
						NSString		*label = [otherValues valueForKey:MPT_LAUNCHD_LABEL_KEY];
						return [self removeLaunchAgentForLabel:label];
					}];
					
					if (shouldFinish) {
						[self quittingNowIsReasonable];
					}
				}];
				break;
				
			case MPTActionInstallScriptAgent:
			case MPTActionRemoveScriptAgent:
				[self addActivityTask:^{
					
					[self handleScriptWithArgs:arguments shouldInstall:(action == MPTActionInstallScriptAgent)];
					
					if (shouldFinish) {
						[self quittingNowIsReasonable];
					}
				}];
				break;
				
			case MPTActionValidateAll:
				//	Note that this does NOT get added to the Activity queue, since it will run as an event driven interface
				[self validateAllBundles];
				break;
				
			default:
				//	Release the Activity Queue
				[self releaseActivityQueue];
				break;
		}
	}
	
	//	Can always indicate that quitting is reasonable
	if (shouldFinish) {
		LKLog(@"Reached the end of doAction - calling quittingNow...");
		[self quittingNowIsReasonable];
	}
}


- (void)validateAllBundles {
	
	//	Indicate that we need an explicit release of the finalize queue
	self.finalizeQueueRequiresExplicitRelease = YES;
	
	//	Separate all the bundles into those that can update and those that can't
	NSMutableArray	*updatingBundles = [NSMutableArray array];
	NSMutableArray	*otherBundles = [NSMutableArray array];
	for (MPCMailBundle *aBundle in [MPCMailBundle allMailBundles]) {
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
		observerHolder = [[NSNotificationCenter defaultCenter] addObserverForName:kMPCDoneLoadingSparkleNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
			
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
		[self releaseFinalizeQueue];
		[self quittingNowIsReasonable];
		return;
	}
	
	//	Build list of ones to show
	NSMutableArray	*badBundles = [NSMutableArray array];
	for (MPCMailBundle *aBundle in bundlesToTest) {
		if (aBundle.incompatibleWithCurrentMail || aBundle.incompatibleWithFutureMail || aBundle.hasUpdate) {
			[badBundles addObject:aBundle];
		}
	}
	
	//	If there is just one, special case to show a nicer presentation
	if ([badBundles count] == 1) {
		//	Show a view for a single item
		self.currentController = [[[MPTSinglePluginController alloc] initWithMailBundle:[badBundles lastObject]] autorelease];
		[[self.currentController window] center];
		[self.currentController showWindow:self];
	}
	else {
		
		//	Show the window
		[self showCollectionWindowForBundles:badBundles];
		
		//	Add a notification watcher to handle uninstalls
		self.bundleUninstallObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMPCMailBundleUninstalledNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
			if ([[note object] isKindOfClass:[MPCMailBundle class]]) {
				NSMutableArray	*change = [self.mailBundleList mutableCopy];
				[change removeObjectIdenticalTo:[note object]];
				self.mailBundleList = [NSArray arrayWithArray:change];
				[change release];
			}
		}];
	}
}

- (BOOL)checkFrequency:(NSUInteger)frequency forActionType:(MPTActionType)action onBundle:(MPCMailBundle *)mailBundle {
	
	//	If frequency is now, just return yes
	if (frequency == 0) {
		return YES;
	}
	
	//	Default is that we have passed the frequency
	BOOL		result = YES;
	NSString	*actionKey = [@"action-" stringByAppendingString:[[NSNumber numberWithInt:action] stringValue]];
	
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


#pragma mark - Plugin Manager Sparkle Delegation

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

- (BOOL)updaterShouldPromptForPermissionToCheckForUpdates:(SUUpdater *)updater {
	return NO;
}

- (BOOL)updater:(SUUpdater *)updater shouldPostponeRelaunchForUpdate:(SUAppcastItem *)update untilInvoking:(NSInvocation *)invocation {
	LKLog(@"Update found with invocation:%@", invocation);
	[self resetSparkleEnvironment];
	//	Do the install, but avoid a relaunch
	[self.updateDriver installWithToolAndRelaunch:NO];
	//	Finish our operation
	[self.sparkleOperation finish];
	//	Tell Sparkle we're handling it.
	return YES;
}

- (void)managerSparkleCompleted:(NSNotification *)note {
	LKLog(@"Manager sparkle completed");
	[self resetSparkleEnvironment];
	[self.sparkleOperation finish];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:[note name] object:[note object]];
}


@end


