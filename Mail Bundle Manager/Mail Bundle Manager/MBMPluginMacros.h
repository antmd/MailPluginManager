//
//  MBMPluginMacros.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 10/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^MBMResultNotificationBlock)(NSDictionary *);

#pragma mark Dictionary Keys

#define	MBM_UUID_COMPLETE_LIST_KEY				@"all-known-uuids"

#pragma mark Command List

#define MBM_UNINSTALL_COMMAND					@"-uninstall"
#define MBM_CHECK_FOR_UPDATES_COMMAND			@"-update"
#define MBM_SEND_CRASH_REPORTS_COMMAND			@"-send-crash-reports"
#define MBM_UPDATE_AND_CRASH_REPORTS_COMMAND	@"-update-and-crash-reports"
#define MBM_SYSTEM_INFO_COMMAND					@"-system-info"
#define MBM_UUID_LIST_COMMAND					@"-uuid-list"
#define	MBM_FREQUENCY_OPTION					@"-freq"

#pragma mark Internal Values

#define MBM_SYSTEM_INFO_NOTIFICATION			@"MBMSystemInfoNotification"
#define MBM_UUID_LIST_NOTIFICATION				@"MBMUUIDListNotification"
#define MBM_TOOL_IDENTIFIER						@"com.littleknownsoftware.MailBundleTool"
#define MBM_SENDER_ID_KEY						@"sender-id"


#pragma mark - Reused Macros

#define	MBMLaunchCommandForBundle(mbmCommand, mbmMailBundle, mbmFrequency) \
{ \
	/*	Then actually launch the app to get the information back	*/ \
	NSString	*mbmToolPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:MBM_TOOL_IDENTIFIER]; \
	NSString	*mbmFreqFlag = (mbmFrequency != 0)?[NSString stringWithFormat:@"%@ %d", MBM_FREQUENCY_OPTION, mbmFrequency]:nil; \
	NSArray		*mbmToolArguments = [NSArray arrayWithObjects:mbmCommand, [mbmMailBundle bundlePath], mbmFreqFlag, nil]; \
	[NSTask launchedTaskWithLaunchPath:mbmToolPath arguments:mbmToolArguments]; \
}


#define	MBMCallToolCommandForBundleWithBlock(mbmCommand, mbmMailBundle, mbmNotificationBlock) \
{ \
	NSString	*mbmNotificationName = [mbmCommand isEqualToString:MBM_SYSTEM_INFO_COMMAND]?MBM_SYSTEM_INFO_NOTIFICATION:MBM_UUID_LIST_NOTIFICATION; \
	/*	Set up the notification watch	*/ \
	NSOperationQueue	*mbmQueue = [[[NSOperationQueue alloc] init] autorelease]; \
	id mbmObserver = [[NSDistributedNotificationCenter defaultCenter] addObserverForName:mbmNotificationName object:nil queue:mbmQueue usingBlock:^(NSNotification *note) { \
		/*	If this was aimed at us, then perform the block and remove the observer	*/ \
		if ([[[note userInfo] valueForKey:MBM_SENDER_ID_KEY] isEqualToString:[mbmMailBundle bundleIdentifier]]) { \
			mbmNotificationBlock([note object]); \
			[[NSDistributedNotificationCenter defaultCenter] removeObserver:mbmObserver]; \
		} \
	}]; \
	/*	Then actually launch the app to get the information back	*/ \
	MBMLaunchCommandForBundle(mbmCommand, mbmMailBundle); \
}

#pragma mark - Plugin Macros

#pragma mark Launch and Forget

#define	MBMUninstallForBundle(mbmMailBundle)									MBMLaunchCommandForBundle(MBM_UNINSTALL_COMMAND, mbmMailBundle, 0);
#define	MBMCheckForUpdatesForBundle(mbmMailBundle)								MBMLaunchCommandForBundle(MBM_CHECK_FOR_UPDATES_COMMAND, mbmMailBundle, 0);
#define	MBMSendCrashReportsForBundle(mbmMailBundle)								MBMLaunchCommandForBundle(MBM_SEND_CRASH_REPORTS_COMMAND, mbmMailBundle, 0);
#define	MBMUpdateAndSendReportsForBundle(mbmMailBundle)							MBMLaunchCommandForBundle(MBM_UPDATE_AND_CRASH_REPORTS_COMMAND, mbmMailBundle, 0);
#define	MBMCheckForUpdatesForBundleWithFrequency(mbmMailBundle, mbmFreq)		MBMLaunchCommandForBundle(MBM_CHECK_FOR_UPDATES_COMMAND, mbmMailBundle, mbmFreq);
#define	MBMUpdateAndSendReportsForBundleWithFrequency(mbmMailBundle, mbmFreq)	MBMLaunchCommandForBundle(MBM_UPDATE_AND_CRASH_REPORTS_COMMAND, mbmMailBundle, mbmFreq);

#pragma mark Notification Block

#define	MBMMailInformationForBundleWithBlock(mbmMailBundle, mbmNotificationBlock)		MBMCallToolCommandForBundleWithBlock(MBM_SYSTEM_INFO_COMMAND, mbmMailBundle, mbmNotificationBlock);
#define	MBMUUIDListForBundleWithBlock(mbmMailBundle, mbmNotificationBlock)				MBMCallToolCommandForBundleWithBlock(MBM_UUID_LIST_COMMAND, mbmMailBundle, mbmNotificationBlock);

