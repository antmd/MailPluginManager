//
//  MPTPluginMacros.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 10/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^MPTResultNotificationBlock)(NSDictionary *);

#pragma mark Dictionary Keys

//	Keys for historical UUID plist
#define	MPT_UUID_COMPLETE_LIST_KEY					@"all-uuids"
#define	MPT_UUID_LATEST_SUPPORTED_UUID_KEY			@"latest-supported-uuid-dict"
#define	MPT_UUID_FIRST_UNSUPPORTED_UUID_KEY			@"first-unsupported-uuid-dict"
#define	MPT_UUID_TYPE_KEY							@"type"
#define	MPT_UUID_EARLIEST_OS_VERSION_DISPLAY_KEY	@"earliest-os-version-display"
#define	MPT_UUID_LATEST_OS_VERSION_DISPLAY_KEY		@"latest-os-version-display"
#define	MPT_UUID_LATEST_VERSION_KEY					@"latest-version-comparator"
#define	MPT_UUID_TYPE_VALUE_MAIL					@"mail"
#define	MPT_UUID_TYPE_VALUE_MESSAGE					@"message"

//	Keys for System Information dictionary
#define	MPT_SYSINFO_SYSTEM_KEY						@"system"
#define	MPT_SYSINFO_MAIL_KEY						@"mail"
#define	MPT_SYSINFO_MESSAGE_KEY						@"message"
#define	MPT_SYSINFO_HARDWARE_KEY					@"hardware"
#define	MPT_SYSINFO_INSTALLED_PLUGINS_KEY			@"installed"
#define	MPT_SYSINFO_DISABLED_PLUGINS_KEY			@"disabled"
#define	MPT_SYSINFO_VERSION_KEY						@"version"
#define	MPT_SYSINFO_BUILD_KEY						@"build"
#define	MPT_SYSINFO_UUID_KEY						@"uuid"
#define MPT_SYSINFO_NAME_KEY						@"name"
#define MPT_SYSINFO_PATH_KEY						@"path"



#pragma mark Command List

#define MPT_SEND_MAIL_INFO_TEXT					@"send mail info plugin path"
#define MPT_SEND_UUID_LIST_TEXT					@"send uuid list plugin path"
#define MPT_UNINSTALL_TEXT						@"uninstall"
#define MPT_UPDATE_TEXT							@"update"
#define MPT_CRASH_REPORTS_TEXT					@"crash reports"
#define MPT_UPDATE_CRASH_REPORTS_TEXT			@"update and crash reports"

#pragma mark Internal Values

#define MPT_TELL_APPLICATION_OPEN				@"tell application \"%@\"\n"
#define MPT_TELL_APPLICATION_OPEN_0				@"tell application \"MailPluginTool\"\n"
#define MPT_SCRIPT_FORMAT						@" %@ \"%@\""
#define MPT_END_TELL							@"\nend tell"
#define MPT_FREQUENCY_FORMAT					@" frequency %@"
#define MPT_FREQUENCY_OPTION					@"-freq"

#define MPT_BUNDLE_UPDATE_STATUS_NOTIFICATION	@"com.littleknownsoftware.MPCBundleUpdateStatusDistNotification"
#define MPT_SYSTEM_INFO_NOTIFICATION			@"com.littleknownsoftware.MPTSystemInfoDistNotification"
#define MPT_UUID_LIST_NOTIFICATION				@"com.littleknownsoftware.MPTUUIDListDistNotification"
#define MPT_TOOL_NAME							@"MailPluginTool"
#define MPT_TOOL_IDENTIFIER						@"com.littleknownsoftware.MailPluginTool"
#define MPT_MANAGER_IDENTIFIER					@"com.littleknownsoftware.MailPluginManager"
#define MPT_APP_RESOURCES_PATH					@"Contents/Resources"
#define MPT_APP_CONTENTS_PATH					@"Contents/MacOS"
#define MPT_SENDER_ID_KEY						@"sender-id"


#pragma mark - Reused Macros

#define	MPTLaunchCommandForBundle(mptCommand, mptMailBundle, mptFrequency) \
{ \
	if (mptMailBundle != nil) { \
		NSString	*pluginManagerPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:MPT_MANAGER_IDENTIFIER]; \
		NSString	*pluginToolPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:MPT_TOOL_IDENTIFIER]; \
		if ((pluginToolPath == nil) || ((pluginManagerPath != nil) && ![pluginToolPath hasPrefix:pluginManagerPath])) { \
			/*	See if we can get the tool path inside the managerPath	*/ \
			NSString	*proposedPath = [pluginManagerPath stringByAppendingPathComponent:MPT_APP_RESOURCES_PATH]; \
			proposedPath = [proposedPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.app", MPT_TOOL_NAME]]; \
			if ((proposedPath != nil) && [[NSFileManager defaultManager] fileExistsAtPath:proposedPath]) { \
				pluginToolPath = proposedPath; \
			} \
		} \
		if (pluginToolPath != nil) { \
			/*	Then actually launch the app to get the information back	*/ \
			NSDictionary	*scriptErrors = nil; \
			NSMutableString	*appleScript = [NSMutableString stringWithFormat:MPT_TELL_APPLICATION_OPEN, pluginToolPath]; \
			[appleScript appendFormat:MPT_SCRIPT_FORMAT, mptCommand, [mptMailBundle bundlePath]]; \
			if (mptFrequency != nil) { \
				[appleScript appendFormat:MPT_FREQUENCY_FORMAT, mptFrequency]; \
			} \
			[appleScript appendString:MPT_END_TELL]; \
			NSAppleScript	*theScript = [[[NSAppleScript alloc] initWithSource:appleScript] autorelease]; \
			NSAppleEventDescriptor	*desc = [theScript executeAndReturnError:&scriptErrors]; \
			if (!desc) { \
				NSLog(@"Script (%@) to call MailBundleTool failed:%@", appleScript, scriptErrors); \
			} \
		} \
		else { \
			NSLog(@"ERROR in MPTLaunchCommandForBundle() Macro: MailPluginTool application wasn't found anywhere"); \
		} \
	} \
	else { \
		NSLog(@"ERROR in MPTLaunchCommandForBundle() Macro: Cannot pass a nil bundle"); \
	} \
}

#define	MPTCallToolCommandForBundleWithBlock(mptCommand, mptMailBundle, mptNotificationBlock) \
{ \
	if (mptMailBundle != nil) { \
NSLog(@"Notification block is:%@", mptNotificationBlock); \
		NSString	*mptNotificationName = [mptCommand isEqualToString:MPT_SEND_MAIL_INFO_TEXT]?MPT_SYSTEM_INFO_NOTIFICATION:MPT_UUID_LIST_NOTIFICATION; \
		/*	Set up the notification watch	*/ \
		NSOperationQueue	*mptQueue = [[[NSOperationQueue alloc] init] autorelease]; \
		__block id mptObserver; \
		mptObserver = [[NSDistributedNotificationCenter defaultCenter] addObserverForName:mptNotificationName object:nil queue:mptQueue usingBlock:^(NSNotification *note) { \
			/*	If this was aimed at us, then perform the block and remove the observer	*/ \
			if ([[note object] isEqualToString:[mptMailBundle bundleIdentifier]]) { \
				mptNotificationBlock([note userInfo]); \
				[[NSDistributedNotificationCenter defaultCenter] removeObserver:mptObserver]; \
			} \
		}]; \
		/*	Then actually launch the app to get the information back	*/ \
		MPTLaunchCommandForBundle(mptCommand, mptMailBundle, nil); \
	} \
	else { \
		NSLog(@"ERROR in MPTCallToolCommandForBundleWithBlock() Macro: Cannot pass a nil bundle"); \
	} \
}


#define	MPTPresentDialogWhenUpToDateUsingWindow(mptBundle, mptSheetWindow) \
{ \
	NSOperationQueue	*mptQueue = [[[NSOperationQueue alloc] init] autorelease]; \
	[mptQueue setName:@"com.littleknownsoftware.BundleUpdateStatusQueue"]; \
	__block id mptBundleObserver; \
	mptBundleObserver = [[NSDistributedNotificationCenter defaultCenter] addObserverForName:MPT_BUNDLE_UPDATE_STATUS_NOTIFICATION object:[mptBundle bundleIdentifier] queue:mptQueue usingBlock:^(NSNotification *note) { \
		/*	Test to see if the plugin is up to date	*/ \
		if ([[[note userInfo] valueForKey:@"uptodate"] boolValue]) { \
			NSString	*messageText = [NSString stringWithFormat:PluginLocalizedString(@"You have the most recent version of %@.", @"Text telling user the plugin is up to date"), [[mptBundle infoDictionary] valueForKey:(NSString *)kCFBundleNameKey]]; \
			NSAlert	*mptBundleUpToDateAlert = [NSAlert alertWithMessageText:messageText defaultButton:PluginLocalizedString(@"OK", @"Okay button") alternateButton:nil otherButton:nil informativeTextWithFormat:@""]; \
			[mptBundleUpToDateAlert setIcon:[[NSWorkspace sharedWorkspace] iconForFile:[mptBundle bundlePath]]]; \
			if (mptSheetWindow != nil) { \
				dispatch_async(dispatch_get_main_queue(), ^{ \
					[mptBundleUpToDateAlert beginSheetModalForWindow:mptSheetWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL]; \
				}); \
			} \
			else { \
				dispatch_sync(dispatch_get_main_queue(), ^{ \
					[mptBundleUpToDateAlert runModal]; \
				}); \
			} \
		} \
		/*	Always remove the observer	*/ \
		[[NSDistributedNotificationCenter defaultCenter] removeObserver:mptBundleObserver]; \
	}]; \
}


#pragma mark - Plugin Macros

#pragma mark UpToDate Dialog
#define MPTPresentModalDialogWhenUpToDate(mptBundle)							MPTPresentDialogWhenUpToDateUsingWindow(mptBundle, nil);

#pragma mark Launch and Forget

#define	MPTUninstallForBundle(mptMailBundle)									MPTLaunchCommandForBundle(MPT_UNINSTALL_TEXT, mptMailBundle, nil);
#define	MPTCheckForUpdatesForBundle(mptMailBundle)								MPTLaunchCommandForBundle(MPT_UPDATE_TEXT, mptMailBundle, nil);
#define	MPTCheckForUpdatesForBundleNow(mptMailBundle)							MPTLaunchCommandForBundle(MPT_UPDATE_TEXT, mptMailBundle, @"now");
#define	MPTSendCrashReportsForBundle(mptMailBundle)								MPTLaunchCommandForBundle(MPT_CRASH_REPORTS_TEXT, mptMailBundle, nil);
#define	MPTUpdateAndSendReportsForBundle(mptMailBundle)							MPTLaunchCommandForBundle(MPT_UPDATE_CRASH_REPORTS_TEXT, mptMailBundle, nil);
#define	MPTUpdateAndSendReportsForBundleNow(mptMailBundle)						MPTLaunchCommandForBundle(MPT_UPDATE_CRASH_REPORTS_TEXT, mptMailBundle, @"now");
#define	MPTCheckForUpdatesForBundleWithFrequency(mptMailBundle, mptFreq)		MPTLaunchCommandForBundle(MPT_UPDATE_TEXT, mptMailBundle, mptFreq);
#define	MPTSendCrashReportsForBundleWithFrequency(mptMailBundle, mptFreq)		MPTLaunchCommandForBundle(MPT_CRASH_REPORTS_TEXT, mptMailBundle, mptFreq);
#define	MPTUpdateAndSendReportsForBundleWithFrequency(mptMailBundle, mptFreq)	MPTLaunchCommandForBundle(MPT_UPDATE_CRASH_REPORTS_TEXT, mptMailBundle, mptFreq);

#pragma mark Notification Block

#define	MPTMailInformationForBundleWithBlock(mptMailBundle, mptNotificationBlock)		MPTCallToolCommandForBundleWithBlock(MPT_SEND_MAIL_INFO_TEXT, mptMailBundle, mptNotificationBlock);
#define	MPTUUIDListForBundleWithBlock(mptMailBundle, mptNotificationBlock)				MPTCallToolCommandForBundleWithBlock(MPT_SEND_UUID_LIST_TEXT, mptMailBundle, mptNotificationBlock);

