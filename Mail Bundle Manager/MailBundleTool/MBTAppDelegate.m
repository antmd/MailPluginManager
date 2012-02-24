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


#define HOURS_AGO	(-1 * 60 * 60)

@interface MBTAppDelegate ()
@property	(nonatomic, assign)	BOOL			savedAutomaticallyDownloadsUpdates;
@property	(nonatomic, assign)	BOOL			savedSendsSystemProfile;
@property	(nonatomic, retain)	NSInvocation	*updateInvocation;
- (void)validateAllBundles;
- (void)showUserInvalidBundles:(NSArray *)bundlesToTest;
- (BOOL)checkFrequency:(NSUInteger)frequency forActionKey:(NSString *)actionKey onBundle:(MBMMailBundle *)mailBundle;
@end

@implementation MBTAppDelegate

@synthesize savedAutomaticallyDownloadsUpdates = _savedAutomaticallyDownloadsUpdates;
@synthesize savedSendsSystemProfile = _savedSendsSystemProfile;
@synthesize updateInvocation = _updateInvocation;



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

- (BOOL)updaterShouldPromptForPermissionToCheckForUpdates:(SUUpdater *)updater {
	return NO;
}

- (NSString *)pathToRelaunchForUpdater:(SUUpdater *)updater {
	//	Prevents any relaunch after an update, since we are just going to wait until the app quits to do it.
	return @"/Users/scott/Public/SfI Installer/Mail Plugin Manager.app";
}

- (BOOL)updater:(SUUpdater *)updater shouldPostponeRelaunchForUpdate:(SUAppcastItem *)update untilInvoking:(NSInvocation *)invocation {
	self.updateInvocation = invocation;
	[self processArguments];
	return YES;
}

- (void)updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)update {
	[self resetSparkleValuesInHostForUpdater:updater];
}

- (void)updaterDidNotFindUpdate:(SUUpdater *)updater {
	[self resetSparkleValuesInHostForUpdater:updater];

	[self processArguments];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSLog(@"Inside the MailBundleTool");

	//	Call our super
	[super applicationDidFinishLaunching:aNotification];
	
	//	Get update for main application (MPM)
	NSBundle	*managerBundle = [NSBundle bundleWithPath:@"/Users/scott/Public/SfI Installer/Mail Plugin Manager.app"];
	SUUpdater	*managerUpdater = [SUUpdater updaterForBundle:managerBundle];
	[managerUpdater resetUpdateCycle];
	managerUpdater.delegate = self;
	//	May need to save the state of these two and restore afterward
	self.savedAutomaticallyDownloadsUpdates = managerUpdater.automaticallyDownloadsUpdates;
	self.savedSendsSystemProfile = managerUpdater.sendsSystemProfile;
	managerUpdater.automaticallyDownloadsUpdates = YES;
	managerUpdater.sendsSystemProfile = YES;
	
	//	Run a background thread to see if we need to update this app, using the basic updater directly.
	SUUpdateDriver	*theUpdateDriver = [[[SUBasicUpdateDriver alloc] initWithUpdater:managerUpdater] autorelease];
	[NSThread detachNewThreadSelector:NSSelectorFromString(@"checkForUpdatesInBgReachabilityCheckWithDriver:") toTarget:managerUpdater withObject:theUpdateDriver];
	
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	LKLog(@"Terminating with invoke:%@", self.updateInvocation);
	if (self.updateInvocation != nil) {
		NSInvocation	*localInvocation = self.updateInvocation;
		self.updateInvocation = nil;
		[localInvocation invoke];
		LKLog(@"Returning Cancel");
		return NSTerminateCancel;
	}
	LKLog(@"Returning Now");
	return NSTerminateNow;
}

- (void)dealloc {
	
	[super dealloc];
}


#pragma mark - Action Methods

- (void)doAction:(NSString *)action withArguments:(NSArray *)arguments {
	
	NSString	*bundlePath = nil;
	NSInteger	frequencyInHours = 0;
	
	if ([arguments count] > 0) {
		bundlePath = [arguments objectAtIndex:0];
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
		[AppDel quittingNowIsReasonable];
	}
	else if ([kMBMCommandLineUUIDListKey isEqualToString:action]) {
		[self performWhenMaintenanceIsFinishedUsingBlock:^{
			NSDistributedNotificationCenter	*center = [NSDistributedNotificationCenter defaultCenter];
			[center postNotificationName:kMBMUUIDListDistNotification object:mailBundle.identifier userInfo:[MBMUUIDList fullUUIDListFromBundle:mailBundle.bundle] deliverImmediately:YES];
			[AppDel quittingNowIsReasonable];
		}];
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


