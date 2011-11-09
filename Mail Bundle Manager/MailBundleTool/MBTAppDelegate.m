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

#define HOURS_AGO	(-1 * 60 * 60)

@interface MBTAppDelegate ()
- (void)validateAllBundles;
- (void)showUserInvalidBundles:(NSArray *)bundlesToTest;
- (BOOL)checkFrequency:(NSUInteger)frequency forActionKey:(NSString *)actionKey onBundle:(MBMMailBundle *)mailBundle;
@end

@implementation MBTAppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	//	Call our super
	[super applicationDidFinishLaunching:aNotification];
	
	//	Decide what actions to take
	//	Read in any command line parameters and set instance variables accordingly
	NSArray	*arguments = [[NSProcessInfo processInfo] arguments];
	
	//	See if there are more arguments
	NSString	*action = nil;
	NSString	*bundlePath = nil;
	NSInteger	frequencyInHours = 0;
	
	if ([arguments count] > 1) {
		action = [arguments objectAtIndex:1];
	}
	if ([arguments count] > 2) {
		bundlePath = [arguments objectAtIndex:2];
	}
	if ([arguments count] > 3) {
		if ([[arguments objectAtIndex:3] isEqualToString:kMBMCommandLineFrequencyOptionKey]) {
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
		[mailBundle uninstall];
	}
	else if ([kMBMCommandLineUpdateKey isEqualToString:action]) {
		//	Tell it to update itself, if frequency requirements met
		if ([self checkFrequency:frequencyInHours forActionKey:action onBundle:mailBundle]) {
			[mailBundle updateIfNecessary];
		}
	}
	else if ([kMBMCommandLineCheckCrashReportsKey isEqualToString:action]) {
		//	Tell it to check its crash reports, if frequency requirements met
		if ([self checkFrequency:frequencyInHours forActionKey:action onBundle:mailBundle]) {
			[mailBundle sendCrashReports];
		}
	}
	else if ([kMBMCommandLineUpdateAndCrashReportsKey isEqualToString:action]) {
		//	If frequency requirements met
		if ([self checkFrequency:frequencyInHours forActionKey:action onBundle:mailBundle]) {
			//	Tell it to check its crash reports
			[mailBundle sendCrashReports];
			//	And update itself
			[mailBundle updateIfNecessary];
		}
	}
	else if ([kMBMCommandLineSystemInfoKey isEqualToString:action]) {
		//	Then send the information
		NSDistributedNotificationCenter	*center = [NSDistributedNotificationCenter defaultCenter];
		NSDictionary	*infoDict = [NSDictionary dictionaryWithObjectsAndKeys:mailBundle.identifier, kMBMUUIDNotificationSenderKey, [MBMSystemInfo completeInfo], kMBMSysInfoKey, nil];
		[center postNotificationName:kMBMSystemInfoDistNotification object:[[NSBundle mainBundle] bundleIdentifier] userInfo:infoDict];
	}
	else if ([kMBMCommandLineUUIDListKey isEqualToString:action]) {
		[self performWhenMaintenanceIsFinishedUsingBlock:^{
			NSDistributedNotificationCenter	*center = [NSDistributedNotificationCenter defaultCenter];
			NSDictionary	*infoDict = [NSDictionary dictionaryWithObjectsAndKeys:mailBundle.identifier, kMBMUUIDNotificationSenderKey, [MBMUUIDList fullUUIDListFromBundle:mailBundle.bundle], kMBMUUIDAllUUIDListKey, nil];
			[center postNotificationName:kMBMUUIDListDistNotification object:[[NSBundle mainBundle] bundleIdentifier] userInfo:infoDict];
		}];
	}
	else if ([kMBMCommandLineValidateAllKey isEqualToString:action]) {
		[self validateAllBundles];
	}
}

- (void)dealloc {
	
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


