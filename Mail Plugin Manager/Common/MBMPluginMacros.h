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

#define MBT_SEND_MAIL_INFO_TEXT					@"send mail info plugin path"
#define MBT_SEND_UUID_LIST_TEXT					@"send uuid list plugin path"
#define MBT_UNINSTALL_TEXT						@"uninstall"
#define MBT_UPDATE_TEXT							@"update"
#define MBT_CRASH_REPORTS_TEXT					@"crash reports"
#define MBT_UPDATE_CRASH_REPORTS_TEXT			@"update and crash reports"

#pragma mark Internal Values

#define MBT_TELL_APPLICATION_OPEN				@"tell application \"%@\"\n"
#define MBT_TELL_APPLICATION_OPEN_0				@"tell application \"MailPluginTool\"\n"
#define MBT_ACTIVATE_APP						@"activate\n"
#define MBT_SCRIPT_FORMAT						@" %@ \"%@\""
#define MBT_END_TELL							@"\nend tell"
#define MBT_FREQUENCY_FORMAT					@" frequency %@"
#define MBT_FREQUENCY_OPTION					@"-freq"

#define MBM_SYSTEM_INFO_NOTIFICATION			@"MBMSystemInfoDistNotification"
#define MBM_UUID_LIST_NOTIFICATION				@"MBMUUIDListDistNotification"
#define MBM_TOOL_NAME							@"MailPluginTool"
#define MBM_TOOL_IDENTIFIER						@"com.littleknownsoftware.MailPluginTool"
#define MBM_MANAGER_IDENTIFIER					@"com.littleknownsoftware.MailPluginManager"
#define MBM_APP_RESOURCES_PATH					@"Contents/Resources"
#define MBM_APP_CONTENTS_PATH					@"Contents/MacOS"
#define MBM_SENDER_ID_KEY						@"sender-id"


#pragma mark - Reused Macros

#define	MBMLaunchCommandForBundle(mbmCommand, mbmMailBundle, mbmNeedsActivate, mbmFrequency) \
{ \
	if (mbmMailBundle != nil) { \
		NSString	*pluginManagerPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:MBM_MANAGER_IDENTIFIER]; \
		NSString	*pluginToolPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:MBM_TOOL_IDENTIFIER]; \
		if ((pluginToolPath == nil) || ((pluginManagerPath != nil) && ![pluginToolPath hasPrefix:pluginManagerPath])) { \
			/*	See if we can get the tool path inside the managerPath	*/ \
			NSString	*proposedPath = [pluginManagerPath stringByAppendingPathComponent:MBM_APP_RESOURCES_PATH]; \
			proposedPath = [proposedPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.app", MBM_TOOL_NAME]]; \
			NSLog(@"ProposedPath is:%@", proposedPath); \
			if ((proposedPath != nil) && [[NSFileManager defaultManager] fileExistsAtPath:proposedPath]) { \
				pluginToolPath = proposedPath; \
			} \
		} \
		if (pluginToolPath != nil) { \
			/*	Then actually launch the app to get the information back	*/ \
			NSDictionary	*scriptErrors = nil; \
			NSLog(@"PluginToolPath is:%@", pluginToolPath); \
			NSMutableString	*appleScript = [NSMutableString stringWithFormat:MBT_TELL_APPLICATION_OPEN, pluginToolPath]; \
			NSLog(@"AppleScript class is:%@", [appleScript className]); \
			if (mbmNeedsActivate) { \
				[appleScript appendString:MBT_ACTIVATE_APP]; \
			} \
			[appleScript appendFormat:MBT_SCRIPT_FORMAT, mbmCommand, [mbmMailBundle bundlePath]]; \
			if (mbmFrequency != nil) { \
				[appleScript appendFormat:MBT_FREQUENCY_FORMAT, mbmFrequency]; \
			} \
			[appleScript appendString:MBT_END_TELL]; \
			NSAppleScript	*theScript = [[[NSAppleScript alloc] initWithSource:appleScript] autorelease]; \
			NSAppleEventDescriptor	*desc = [theScript executeAndReturnError:&scriptErrors]; \
			if (!desc) { \
				NSLog(@"Script (%@) to call MailBundleTool failed:%@", appleScript, scriptErrors); \
			} \
		} \
		else { \
			NSLog(@"ERROR in MBMLaunchCommandForBundle() Macro: MailPluginTool application wasn't found anywhere"); \
		} \
	} \
	else { \
		NSLog(@"ERROR in MBMLaunchCommandForBundle() Macro: Cannot pass a nil bundle"); \
	} \
}

#define	MBMCallToolCommandForBundleWithBlock(mbmCommand, mbmMailBundle, mbmNotificationBlock) \
{ \
	if (mbmMailBundle != nil) { \
		NSString	*mbmNotificationName = [mbmCommand isEqualToString:MBT_SEND_MAIL_INFO_TEXT]?MBM_SYSTEM_INFO_NOTIFICATION:MBM_UUID_LIST_NOTIFICATION; \
		/*	Set up the notification watch	*/ \
		NSOperationQueue	*mbmQueue = [[[NSOperationQueue alloc] init] autorelease]; \
		__block id mbmObserver; \
		mbmObserver = [[NSDistributedNotificationCenter defaultCenter] addObserverForName:mbmNotificationName object:nil queue:mbmQueue usingBlock:^(NSNotification *note) { \
			/*	If this was aimed at us, then perform the block and remove the observer	*/ \
			if ([[note object] isEqualToString:[mbmMailBundle bundleIdentifier]]) { \
				mbmNotificationBlock([note userInfo]); \
				[[NSDistributedNotificationCenter defaultCenter] removeObserver:mbmObserver]; \
			} \
		}]; \
		/*	Then actually launch the app to get the information back	*/ \
		MBMLaunchCommandForBundle(mbmCommand, mbmMailBundle, NO, nil); \
	} \
	else { \
		NSLog(@"ERROR in MBMCallToolCommandForBundleWithBlock() Macro: Cannot pass a nil bundle"); \
	} \
}

#pragma mark - Plugin Macros

#pragma mark Launch and Forget

#define	MBMUninstallForBundle(mbmMailBundle)									MBMLaunchCommandForBundle(MBT_UNINSTALL_TEXT, mbmMailBundle. YES, nil);
#define	MBMCheckForUpdatesForBundle(mbmMailBundle)								MBMLaunchCommandForBundle(MBT_UPDATE_TEXT, mbmMailBundle, YES, nil);
#define	MBMSendCrashReportsForBundle(mbmMailBundle)								MBMLaunchCommandForBundle(MBT_CRASH_REPORTS_TEXT, mbmMailBundle, NO, nil);
#define	MBMUpdateAndSendReportsForBundle(mbmMailBundle)							MBMLaunchCommandForBundle(MBT_UPDATE_CRASH_REPORTS_TEXT, mbmMailBundle, YES, nil);
#define	MBMCheckForUpdatesForBundleWithFrequency(mbmMailBundle, mbmFreq)		MBMLaunchCommandForBundle(MBT_UPDATE_TEXT, mbmMailBundle, YES, mbmFreq);
#define	MBMSendCrashReportsForBundleWithFrequency(mbmMailBundle, mbmFreq)		MBMLaunchCommandForBundle(MBT_CRASH_REPORTS_TEXT, mbmMailBundle, NO, mbmFreq);
#define	MBMUpdateAndSendReportsForBundleWithFrequency(mbmMailBundle, mbmFreq)	MBMLaunchCommandForBundle(MBT_UPDATE_CRASH_REPORTS_TEXT, mbmMailBundle, YES, mbmFreq);

#pragma mark Notification Block

#define	MBMMailInformationForBundleWithBlock(mbmMailBundle, mbmNotificationBlock)		MBMCallToolCommandForBundleWithBlock(MBT_SEND_MAIL_INFO_TEXT, mbmMailBundle, mbmNotificationBlock);
#define	MBMUUIDListForBundleWithBlock(mbmMailBundle, mbmNotificationBlock)				MBMCallToolCommandForBundleWithBlock(MBT_SEND_UUID_LIST_TEXT, mbmMailBundle, mbmNotificationBlock);

