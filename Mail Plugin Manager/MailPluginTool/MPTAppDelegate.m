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
//#import "MPTCrashReporter.h"
#import "MPTReporterAsyncOperation.h"


#define HOURS_AGO	(-1 * 60 * 60)


@interface MPTAppDelegate ()
@property	(nonatomic, copy)	NSMutableDictionary			*savedSparkleState;
@property	(nonatomic, retain)	NSArray						*sparkleKeysValues;
@property	(nonatomic, assign) MPCSparkleAsyncOperation	*sparkleOperation;
@property	(nonatomic, retain) SUBasicUpdateDriver			*updateDriver;


//	Actions
- (NSString *)pathToManagerContainer;
- (void)validateAllBundles;
- (void)showUserInvalidBundles:(NSArray *)bundlesToTest;
- (BOOL)checkFrequency:(NSUInteger)frequency forActionKey:(NSString *)actionKey onBundle:(MPCMailBundle *)mailBundle;

- (void)managerSparkleCompleted:(NSNotification *)note;

@end

@implementation MPTAppDelegate

@synthesize savedSparkleState = _savedSparkleState;
@synthesize sparkleKeysValues = _sparkleKeysValues;
@synthesize sparkleOperation = _sparkleOperation;
@synthesize updateDriver = _updateDriver;


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
	
	self.finalizeQueueRequiresExplicitRelease = NO;

	//	Get Path for the Mail Plugin Manager container
	NSString	*mpmPath = [self pathToManagerContainer];
	//	Currently don't support Sparkle updating for just the Tool, so only do this if contained with the Manager and if that is writable by the user.
	LKLog(@"mpmPath is:%@", mpmPath);
	if ((mpmPath != nil) && [mpmPath userHasAccessRights]) {
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
		self.sparkleOperation = [[[MPCSparkleAsyncOperation alloc] initWithUpdateDriver:self.updateDriver] autorelease];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managerSparkleCompleted:) name:kMPCSUUpdateDriverAbortNotification object:self.updateDriver];
		[self addFinalizeOperation:self.sparkleOperation];
	}
	
	//	Go ahead and process the arguments
	[self processArguments];

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


#pragma mark - Action Methods

- (void)doAction:(NSString *)action withArguments:(NSArray *)arguments {
	
	NSString	*bundlePath = nil;
	NSInteger	frequencyInHours = 0;
	BOOL		forceUpdate = NO;
	
	if ([arguments count] > 0) {
		bundlePath = [arguments objectAtIndex:0];
		if ([bundlePath isEqualToString:@"(null)"]) {
			bundlePath = nil;
		}
	}
	if ([arguments count] > 1) {
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
	if ((bundlePath == nil) &&
		([kMPCCommandLineUninstallKey isEqualToString:action] || [kMPCCommandLineUpdateKey isEqualToString:action] ||
		 [kMPCCommandLineCheckCrashReportsKey isEqualToString:action] || [kMPCCommandLineUpdateAndCrashReportsKey isEqualToString:action])) {
			
			//	Release the Activity Queue
			[self releaseActivityQueue];
	}
	else {
		//	Look at the first argument (after executable name) and test for one of our types
		if ([kMPCCommandLineUninstallKey isEqualToString:action]) {
			//	Tell it to uninstall itself
			[self addActivityTask:^{
				if ([mailBundle uninstall]) {
					[self askToRestartMailWithBlock:nil usingIcon:[mailBundle icon]];
				}
			}];
		}
		else if ([kMPCCommandLineUpdateKey isEqualToString:action]) {
			//	Tell it to update itself, if frequency requirements met
			if ([self checkFrequency:frequencyInHours forActionKey:action onBundle:mailBundle]) {
				LKLog(@"Adding an update for bundle:'%@' to the queue", [[mailBundle path] lastPathComponent]);
				[self updateMailBundle:mailBundle force:forceUpdate];
			}
		}
		else if ([kMPCCommandLineCheckCrashReportsKey isEqualToString:action]) {
			//	Tell it to check its crash reports, if frequency requirements met
			if ([self checkFrequency:frequencyInHours forActionKey:action onBundle:mailBundle]) {
				LKLog(@"Sending crash reports");
				[self addActivityOperation:[[[MPTReporterAsyncOperation alloc] initWithMailBundle:mailBundle] autorelease]];
			}
		}
		else if ([kMPCCommandLineUpdateAndCrashReportsKey isEqualToString:action]) {
			//	If frequency requirements met
			if ([self checkFrequency:frequencyInHours forActionKey:action onBundle:mailBundle]) {
				[self addActivityOperation:[[[MPTReporterAsyncOperation alloc] initWithMailBundle:mailBundle] autorelease]];
				[self updateMailBundle:mailBundle force:forceUpdate];
			}
		}
		else if ([kMPCCommandLineSystemInfoKey isEqualToString:action]) {
			[self addActivityTask:^{
				//	Then send the information
				NSDistributedNotificationCenter	*center = [NSDistributedNotificationCenter defaultCenter];
				[center postNotificationName:kMPTSystemInfoDistNotification object:mailBundle.identifier userInfo:[MPCSystemInfo completeInfo] deliverImmediately:YES];
				LKLog(@"Sent notification");
				[self quittingNowIsReasonable];
			}];
		}
		else if ([kMPCCommandLineUUIDListKey isEqualToString:action]) {
			[self addActivityTask:^{
				NSDistributedNotificationCenter	*center = [NSDistributedNotificationCenter defaultCenter];
				[center postNotificationName:kMPTUUIDListDistNotification object:mailBundle.identifier userInfo:[MPCUUIDList fullUUIDListFromBundle:mailBundle.bundle] deliverImmediately:YES];
				[self quittingNowIsReasonable];
			}];
		}
		else if ([kMPCCommandLineValidateAllKey isEqualToString:action]) {
			//	Note that this does NOT get added to the Activity queue, since it will run as an event driven interface
			[self validateAllBundles];
		}
		else {
			//	Release the Activity Queue
			[self releaseActivityQueue];
		}
	}

	//	Can always indicate that quitting is reasonable
	LKLog(@"Reached the end of doAction - calling quittingNow...");
	[self quittingNowIsReasonable];
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

- (BOOL)checkFrequency:(NSUInteger)frequency forActionKey:(NSString *)actionKey onBundle:(MPCMailBundle *)mailBundle {
	
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


