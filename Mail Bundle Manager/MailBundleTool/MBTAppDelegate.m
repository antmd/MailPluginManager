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

#import "SUBasicUpdateDriver.h"

#import "MBTSparkleAsyncOperation.h"

#define HOURS_AGO	(-1 * 60 * 60)

@interface MBTAppDelegate () 
@property	(nonatomic, assign)	BOOL						savedAutomaticallyDownloadsUpdates;
@property	(nonatomic, assign)	BOOL						savedSendsSystemProfile;
@property	(nonatomic, assign)	BOOL						installUpdateOnQuit;
@property	(nonatomic, assign) MBTSparkleAsyncOperation	*sparkleOperation;
@property	(nonatomic, retain) SUBasicUpdateDriver			*updateDriver;
- (NSString *)pathToManagerContainer;
- (void)validateAllBundles;
- (void)showUserInvalidBundles:(NSArray *)bundlesToTest;
- (BOOL)checkFrequency:(NSUInteger)frequency forActionKey:(NSString *)actionKey onBundle:(MBMMailBundle *)mailBundle;
@end

@implementation MBTAppDelegate

@synthesize savedAutomaticallyDownloadsUpdates = _savedAutomaticallyDownloadsUpdates;
@synthesize savedSendsSystemProfile = _savedSendsSystemProfile;
@synthesize installUpdateOnQuit = _installUpdateOnQuit;
@synthesize sparkleOperation = _sparkleOperation;
@synthesize updateDriver = _updateDriver;


#pragma mark - Handler Methods

- (void)resetSparkleValuesInHostForUpdater:(SUUpdater *)updater {
	//	Restore any changed values for the app
	updater.automaticallyDownloadsUpdates = self.savedAutomaticallyDownloadsUpdates;
	updater.sendsSystemProfile = self.savedSendsSystemProfile;
}

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

- (void)cleanupWithUpdater:(SUUpdater *)updater install:(BOOL)shouldInstall {
	self.installUpdateOnQuit = shouldInstall;
	[self resetSparkleValuesInHostForUpdater:updater];
	[self processArguments];
	[self.sparkleOperation finish];
}

- (BOOL)updaterShouldPromptForPermissionToCheckForUpdates:(SUUpdater *)updater {
	return NO;
}

- (BOOL)updater:(SUUpdater *)updater shouldPostponeRelaunchForUpdate:(SUAppcastItem *)update untilInvoking:(NSInvocation *)invocation {
	LKLog(@"Update found with invocation:%@", invocation);
	[self cleanupWithUpdater:updater install:YES];
	return YES;
}

- (void)updaterDidNotFindUpdate:(SUUpdater *)updater {
	LKLog(@"No Update found");
	[self cleanupWithUpdater:updater install:NO];
}

#pragma mark - Application Events

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	LKLog(@"Inside the MailBundleTool - Path is:'%@'", [[NSBundle mainBundle] bundlePath]);

	//	Call our super
	[super applicationDidFinishLaunching:aNotification];
	
	//	Get Path for the Mail Plugin Manager container
	NSString	*mpmPath = [self pathToManagerContainer];
	//	Currently don't support Sparkle updating for just the Tool, so if it is not contained with the Manager, just do the action and return
	LKLog(@"mpmPath is:%@", mpmPath);
	if (mpmPath == nil) {
		[self processArguments];
		return;
	}
	
	//	Then find it's bundle
	NSURL		*bundleURL = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@", mpmPath]];
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
	//	May need to save the state of these two and restore afterward
	self.savedAutomaticallyDownloadsUpdates = managerUpdater.automaticallyDownloadsUpdates;
	self.savedSendsSystemProfile = managerUpdater.sendsSystemProfile;
	managerUpdater.automaticallyDownloadsUpdates = YES;
	managerUpdater.sendsSystemProfile = YES;
	
	//	Run a background thread to see if we need to update this app, using the basic updater directly.
	self.updateDriver = [[[SUBasicUpdateDriver alloc] initWithUpdater:managerUpdater] autorelease];
	self.sparkleOperation = [[[MBTSparkleAsyncOperation alloc] initWithUpdateDriver:self.updateDriver] autorelease];
	[self addMaintenanceOperation:self.sparkleOperation];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	if (self.installUpdateOnQuit) {
		self.installUpdateOnQuit = NO;
		[self.updateDriver installWithToolAndRelaunch:NO];
		return NSTerminateCancel;
	}
	return NSTerminateNow;
}

- (void)dealloc {
	self.updateDriver = nil;
	
	[super dealloc];
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
		
			NSString	*managerName = [[managerURL absoluteString] lastPathComponent];
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
			
			[AppDel quittingNowIsReasonable];
			return;
	}
	
	//	Look at the first argument (after executable name) and test for one of our types
	if ([kMBMCommandLineUninstallKey isEqualToString:action]) {
		//	Tell it to uninstall itself
		[self quitAfterReceivingNotificationNames:[NSArray arrayWithObjects:kMBMMailBundleUninstalledNotification, kMBMMailBundleDisabledNotification, kMBMMailBundleNoActionTakenNotification, nil] onObject:mailBundle testType:MBMAnyNotificationReceived];
		[mailBundle uninstall];
	}
	else if ([kMBMCommandLineUpdateKey isEqualToString:action]) {
		//	Tell it to update itself, if frequency requirements met
		if ([self checkFrequency:frequencyInHours forActionKey:action onBundle:mailBundle]) {
			[self quitAfterReceivingNotifications:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:kMBMDoneUpdatingMailBundleNotification, kMBMNotificationWaitNote, mailBundle, kMBMNotificationWaitObject, nil], [NSDictionary dictionaryWithObjectsAndKeys:kMBMSUUpdateDriverDoneNotification, kMBMNotificationWaitNote, nil], nil] testType:MBMAnyNotificationReceived];
			[mailBundle updateIfNecessary];
		}
	}
	else if ([kMBMCommandLineCheckCrashReportsKey isEqualToString:action]) {
		//	Tell it to check its crash reports, if frequency requirements met
		if ([self checkFrequency:frequencyInHours forActionKey:action onBundle:mailBundle]) {
			[self quitAfterReceivingNotificationNames:[NSArray arrayWithObject:kMBMDoneSendingCrashReportsMailBundleNotification] onObject:mailBundle testType:MBMAnyNotificationReceived];
			[mailBundle sendCrashReports];
		}
	}
	else if ([kMBMCommandLineUpdateAndCrashReportsKey isEqualToString:action]) {
		//	If frequency requirements met
		if ([self checkFrequency:frequencyInHours forActionKey:action onBundle:mailBundle]) {
			[self quitAfterReceivingNotifications:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:kMBMDoneSendingCrashReportsMailBundleNotification, kMBMNotificationWaitNote, mailBundle, kMBMNotificationWaitObject, nil], [NSDictionary dictionaryWithObjectsAndKeys:kMBMDoneUpdatingMailBundleNotification, kMBMNotificationWaitNote, mailBundle, kMBMNotificationWaitObject, nil], [NSDictionary dictionaryWithObjectsAndKeys:kMBMSUUpdateDriverDoneNotification, kMBMNotificationWaitNote, nil], nil] testType:MBMAnyTwoNotificationsReceived];
			//	Tell it to check its crash reports
			[mailBundle sendCrashReports];
			//	And update itself
			[mailBundle updateIfNecessary];
		}
	}
	else if ([kMBMCommandLineSystemInfoKey isEqualToString:action]) {
		//	Then send the information
		NSDistributedNotificationCenter	*center = [NSDistributedNotificationCenter defaultCenter];
		[center postNotificationName:kMBMSystemInfoDistNotification object:mailBundle.identifier userInfo:[MBMSystemInfo completeInfo] deliverImmediately:YES];
		LKLog(@"Sent notification");
		[AppDel quittingNowIsReasonable];
	}
	else if ([kMBMCommandLineUUIDListKey isEqualToString:action]) {
		NSDistributedNotificationCenter	*center = [NSDistributedNotificationCenter defaultCenter];
		[center postNotificationName:kMBMUUIDListDistNotification object:mailBundle.identifier userInfo:[MBMUUIDList fullUUIDListFromBundle:mailBundle.bundle] deliverImmediately:YES];
		[AppDel quittingNowIsReasonable];
	}
	else if ([kMBMCommandLineValidateAllKey isEqualToString:action]) {
		[self validateAllBundles];
	}
	else {
		[AppDel quittingNowIsReasonable];
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
		self.bundleUnistallObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMBMMailBundleUninstalledNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
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


@end


