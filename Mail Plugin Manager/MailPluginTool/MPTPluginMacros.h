//
//  MPTPluginMacros.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 10/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_feature(objc_arc)
#define	MPT_MACRO_RELEASE(x)	while (0) {}
#else
#define	MPT_MACRO_RELEASE(x)	[x release];
#endif

typedef void(^MPTResultNotificationBlock)(NSDictionary *);
typedef void(^MPTUpdateTestingCompleteBlock)(void);

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
#define MPT_SYSINFO_ANONYMOUS_ID_KEY				@"anonymous-id"
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

#define MPT_SEND_MAIL_INFO_TEXT					@"-mail-info"
#define MPT_SEND_UUID_LIST_TEXT					@"-uuid-list"
#define MPT_UNINSTALL_TEXT						@"-uninstall"
#define MPT_UPDATE_TEXT							@"-update"
#define MPT_CRASH_REPORTS_TEXT					@"-send-crash-reports"
#define MPT_UPDATE_CRASH_REPORTS_TEXT			@"-update-and-crash-reports"
#define MPT_FREQUENCY_OPTION					@"-freq"

#pragma mark Internal Values

#define MPT_LKS_BUNDLE_START					@"com.littleknownsoftware."
#define MPT_BUNDLE_UPDATE_STATUS_NOTIFICATION	[MPT_LKS_BUNDLE_START stringByAppendingString:@"MPCBundleUpdateStatusDistNotification"]
#define MPT_BUNDLE_WILL_INSTALL_NOTIFICATION	[MPT_LKS_BUNDLE_START stringByAppendingString:@"MPCBundleWillInstallDistNotification"]
#define MPT_SYSTEM_INFO_NOTIFICATION			[MPT_LKS_BUNDLE_START stringByAppendingString:@"MPTSystemInfoDistNotification"]
#define MPT_UUID_LIST_NOTIFICATION				[MPT_LKS_BUNDLE_START stringByAppendingString:@"MPTUUIDListDistNotification"]
#define MPT_TOOL_NAME							@"MailPluginTool"
#define MPT_TOOL_IDENTIFIER						[MPT_LKS_BUNDLE_START stringByAppendingString:MPT_TOOL_NAME]
#define MPT_MANAGER_IDENTIFIER					[MPT_LKS_BUNDLE_START stringByAppendingString:@"MailPluginManager"]
#define MPT_APP_RESOURCES_PATH					@"Contents/Resources"
#define MPT_APP_CODE_PATH						@"Contents/MacOS"

#define MPT_MANAGER_APP_NAME					@"Mail Plugin Manager.app"
#define MPT_MAIL_MPT_FOLDER_PATH				@"Mail/MPT"
#define MPT_PERFORM_ACTION_EXTENSION			@"mtperform"
#define MPT_ACTION_KEY							@"action"
#define MPT_PLUGIN_PATH_KEY						@"plugin-path"
#define MPT_FREQUENCY_KEY						@"frequency"


#pragma mark - Reused Macros

#define MPTPerformFolderPath() \
	[[[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:MPT_MAIL_MPT_FOLDER_PATH] stringByExpandingTildeInPath]

#define MPTGetLikelyToolPath() \
	NSFileManager	*manager = [NSFileManager defaultManager]; \
	NSString		*pluginManagerPath = [[NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSLocalDomainMask, YES) lastObject] stringByAppendingPathComponent:MPT_MANAGER_APP_NAME]; \
	if (![manager fileExistsAtPath:pluginManagerPath]) { \
		pluginManagerPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:MPT_MANAGER_IDENTIFIER]; \
	} \
	NSString		*pluginToolPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:MPT_TOOL_IDENTIFIER]; \
	if ((pluginToolPath == nil) || ((pluginManagerPath != nil) && ![pluginToolPath hasPrefix:pluginManagerPath])) { \
		/*	See if we can get the tool path inside the managerPath	*/ \
		NSString	*proposedPath = [pluginManagerPath stringByAppendingPathComponent:MPT_APP_RESOURCES_PATH]; \
		proposedPath = [proposedPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.app", MPT_TOOL_NAME]]; \
		if ((proposedPath != nil) && [[NSFileManager defaultManager] fileExistsAtPath:proposedPath]) { \
			pluginToolPath = proposedPath; \
		} \
	} \

#define	MPTLaunchCommandForBundle(mptCommand, mptMailBundle, mptFrequency) \
{ \
	if (mptMailBundle != nil) { \
		MPTGetLikelyToolPath(); \
		if (pluginToolPath != nil) { \
			NSMutableDictionary	*performDict = [NSMutableDictionary dictionaryWithCapacity:3]; \
			[performDict setObject:mptCommand forKey:MPT_ACTION_KEY]; \
			[performDict setObject:[mptMailBundle bundlePath] forKey:MPT_PLUGIN_PATH_KEY]; \
			if ((mptFrequency != nil) && ![mptFrequency isEqualToString:@""]) { \
				[performDict setObject:mptFrequency forKey:MPT_FREQUENCY_KEY]; \
			} \
			NSString		*plistPath = MPTPerformFolderPath(); \
			BOOL			isDir = NO; \
			/*	Ensure that we have a directory	*/ \
			if (![manager fileExistsAtPath:plistPath isDirectory:&isDir] || !isDir) { \
				if ([manager createDirectoryAtPath:plistPath withIntermediateDirectories:NO attributes:nil error:NULL]) { \
					isDir = YES; \
				} \
			} \
			/*	If we do, then try to create our file	*/ \
			NSString	*fullFilePath = nil; \
			if (isDir) { \
				NSString	*tempfileName = [[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension:MPT_PERFORM_ACTION_EXTENSION]; \
				if ([performDict writeToFile:[plistPath stringByAppendingPathComponent:tempfileName] atomically:NO]) { \
					fullFilePath = [plistPath stringByAppendingPathComponent:tempfileName]; \
				} \
			} \
			else { \
				NSLog(@"Unable to create the action file, since the required folder doesn't exist and I can't create it"); \
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
		NSString	*mptNotificationName = [mptCommand isEqualToString:MPT_SEND_MAIL_INFO_TEXT]?MPT_SYSTEM_INFO_NOTIFICATION:MPT_UUID_LIST_NOTIFICATION; \
		/*	Set up the notification watch	*/ \
		NSOperationQueue	*mptQueue = [[NSOperationQueue alloc] init]; \
		__block id mptObserver; \
		mptObserver = [[NSDistributedNotificationCenter defaultCenter] addObserverForName:mptNotificationName object:nil queue:mptQueue usingBlock:^(NSNotification *note) { \
			/*	If this was aimed at us, then perform the block and remove the observer	*/ \
			if ([[note object] isEqualToString:[mptMailBundle bundleIdentifier]]) { \
				mptNotificationBlock([note userInfo]); \
				[[NSDistributedNotificationCenter defaultCenter] removeObserver:mptObserver]; \
			} \
		}]; \
		/*	Then actually launch the app to get the information back	*/ \
		MPTLaunchCommandForBundle(mptCommand, mptMailBundle, @""); \
		MPT_MACRO_RELEASE(mptQueue); \
	} \
	else { \
		NSLog(@"ERROR in MPTCallToolCommandForBundleWithBlock() Macro: Cannot pass a nil bundle"); \
	} \
}


#define MPTClosePrefsWindowIfInstalling(mptBundle) \
{ \
	NSOperationQueue	*mptQueue = [[NSOperationQueue alloc] init]; \
	[mptQueue setName:[MPT_LKS_BUNDLE_START stringByAppendingString:@"BundleWillInstallQueue"]]; \
	__block id mptBundleObserver; \
	mptBundleObserver = [[NSDistributedNotificationCenter defaultCenter] addObserverForName:MPT_BUNDLE_WILL_INSTALL_NOTIFICATION object:[mptBundle bundleIdentifier] queue:mptQueue usingBlock:^(NSNotification *note) { \
		/*	If the preferences are open then close them	*/ \
		NSPreferences	*prefs = [NSPreferences sharedPreferences]; \
		BOOL	panelIsVisible = [[prefs valueForKey:@"preferencesPanel"] isVisible]; \
		if (panelIsVisible && (prefs != nil)) { \
			dispatch_async(dispatch_get_main_queue(), ^{ \
				[prefs performSelector:@selector(cancel:) withObject:self]; \
			}); \
		} \
		/*	Always remove the observer	*/ \
		[[NSDistributedNotificationCenter defaultCenter] removeObserver:mptBundleObserver]; \
	}]; \
	MPT_MACRO_RELEASE(mptQueue); \
}


#define	MPTPresentDialogWhenUpToDateUsingWindow(mptBundle, mptSheetWindow, mptFinishBlock) \
{ \
	NSOperationQueue	*mptQueue = [[NSOperationQueue alloc] init]; \
	[mptQueue setName:[MPT_LKS_BUNDLE_START stringByAppendingString:@"BundleUpdateStatusQueue"]]; \
	__block id mptBundleObserver; \
	mptBundleObserver = [[NSDistributedNotificationCenter defaultCenter] addObserverForName:MPT_BUNDLE_UPDATE_STATUS_NOTIFICATION object:[mptBundle bundleIdentifier] queue:mptQueue usingBlock:^(NSNotification *note) { \
		/*	Test to see if the plugin is up to date	*/ \
		if ([[[note userInfo] valueForKey:@"uptodate"] boolValue]) { \
			NSString	*messageText = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"You have the most recent version of %@.", nil, mptBundle, @"Text telling user the plugin is up to date"), [[mptBundle infoDictionary] valueForKey:(NSString *)kCFBundleNameKey]]; \
			NSAlert	*mptBundleUpToDateAlert = [NSAlert alertWithMessageText:messageText defaultButton:NSLocalizedStringFromTableInBundle(@"OK", nil, mptBundle, @"Okay button") alternateButton:nil otherButton:nil informativeTextWithFormat:@""]; \
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
		if (mptFinishBlock != nil) { \
			mptFinishBlock(); \
		} \
		/*	Always remove the observer	*/ \
		[[NSDistributedNotificationCenter defaultCenter] removeObserver:mptBundleObserver]; \
	}]; \
	MPT_MACRO_RELEASE(mptQueue); \
}


#pragma mark - Plugin Macros

#pragma mark UpToDate Dialog

#define MPTPresentModalDialogWhenUpToDate(mptBundle)							MPTPresentDialogWhenUpToDateUsingWindow(mptBundle, nil, nil);
#define MPTPresentModalDialogWhenUpToDateWithBlock(mptBundle, mptFinishBlock)	MPTPresentDialogWhenUpToDateUsingWindow(mptBundle, nil, mptFinishBlock);

#pragma mark Launch and Forget

#define	MPTUninstallForBundle(mptMailBundle)									MPTLaunchCommandForBundle(MPT_UNINSTALL_TEXT, mptMailBundle, @"");
#define	MPTCheckForUpdatesForBundle(mptMailBundle)								MPTLaunchCommandForBundle(MPT_UPDATE_TEXT, mptMailBundle, @"");
#define	MPTCheckForUpdatesForBundleNow(mptMailBundle)							MPTLaunchCommandForBundle(MPT_UPDATE_TEXT, mptMailBundle, @"now");
#define	MPTSendCrashReportsForBundle(mptMailBundle)								MPTLaunchCommandForBundle(MPT_CRASH_REPORTS_TEXT, mptMailBundle, @"");
#define	MPTUpdateAndSendReportsForBundle(mptMailBundle)							MPTLaunchCommandForBundle(MPT_UPDATE_CRASH_REPORTS_TEXT, mptMailBundle, @"");
#define	MPTUpdateAndSendReportsForBundleNow(mptMailBundle)						MPTLaunchCommandForBundle(MPT_UPDATE_CRASH_REPORTS_TEXT, mptMailBundle, @"now");
#define	MPTCheckForUpdatesForBundleWithFrequency(mptMailBundle, mptFreq)		MPTLaunchCommandForBundle(MPT_UPDATE_TEXT, mptMailBundle, mptFreq);
#define	MPTSendCrashReportsForBundleWithFrequency(mptMailBundle, mptFreq)		MPTLaunchCommandForBundle(MPT_CRASH_REPORTS_TEXT, mptMailBundle, mptFreq);
#define	MPTUpdateAndSendReportsForBundleWithFrequency(mptMailBundle, mptFreq)	MPTLaunchCommandForBundle(MPT_UPDATE_CRASH_REPORTS_TEXT, mptMailBundle, mptFreq);

#pragma mark Notification Block

#define	MPTMailInformationForBundleWithBlock(mptMailBundle, mptNotificationBlock)		MPTCallToolCommandForBundleWithBlock(MPT_SEND_MAIL_INFO_TEXT, mptMailBundle, mptNotificationBlock);
#define	MPTUUIDListForBundleWithBlock(mptMailBundle, mptNotificationBlock)				MPTCallToolCommandForBundleWithBlock(MPT_SEND_UUID_LIST_TEXT, mptMailBundle, mptNotificationBlock);

