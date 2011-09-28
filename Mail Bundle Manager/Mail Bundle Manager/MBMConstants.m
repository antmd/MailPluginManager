//
//  MBMConstants.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MBMConstants.h"

//	Command line keys
NSString	*kMBMCommandLineInstallKey = @"-install";
NSString	*kMBMCommandLineUninstallKey = @"-uninstall";
NSString	*kMBMCommandLineUpdateKey = @"-update";
NSString	*kMBMCommandLineCheckCrashReportsKey = @"-check-crash-reports";
NSString	*kMBMCommandLineUpdateAndCrashReportsKey = @"-update-and-crash-reports";
NSString	*kMBMCommandLineValidateAllKey = @"-validate-all";

//	Extensions and commonly used values
NSString	*kMBMPlistExtension = @"plist";
NSString	*kMBMInstallerFileExtension = @"mbinstall";
NSString	*kMBMUninstallerFileExtension = @"mbremove";
NSString	*kMBMManifestName = @"mbm-manifest";
NSString	*kMBMMailFolderName = @"Mail";
NSString	*kMBMBundleFolderName = @"Bundles";
NSString	*kMBMBundleUsesMBMKey = @"PluginUsesMailBundleManager";

//	Keys for top level of manifest
NSString	*kMBMManifestTypeKey = @"manifest-type";
NSString	*kMBMManifestTypeInstallValue = @"install";
NSString	*kMBMManifestTypeUninstallValue = @"uninstall";
NSString	*kMBMBackgroundImagePathKey = @"background-image-path";
NSString	*kMBMDisplayNameKey = @"display-name";
NSString	*kMBMMinOSVersionKey = @"min-os-major-version";
NSString	*kMBMMaxOSVersionKey = @"max-os-major-version";
NSString	*kMBMMinMailVersionKey = @"min-mail-version";
NSString	*kMBMCanDeleteManagerIfNotUsedByOthersKey = @"can-delete-bundle-manager-if-no-other-plugins-use";
NSString	*kMBMCanDeleteManagerIfNoBundlesKey = @"can-delete-bundle-manager-if-no-plugins-left";
//	Keys for the action items and sub objects
NSString	*kMBMActionItemsKey = @"action-items";
NSString	*kMBMPathKey = @"path";
NSString	*kMBMNameKey = @"name";
NSString	*kMBMDestinationPathKey = @"destination-path";
NSString	*kMBMDescriptionKey = @"description";
NSString	*kMBMPermissionsKey = @"permissions-needed";
NSString	*kMBMIsBundleManagerKey = @"is-bundle-manager";
//	Keys for the action items and sub objects
NSString	*kMBMConfirmationStepsKey = @"confirmation-steps";
NSString	*kMBMConfirmationTitleKey = @"title";
NSString	*kMBMConfirmationBulletTitleKey = @"bullet-title";
NSString	*kMBMConfirmationShouldAgreeToLicense = @"license-agreement-required";
NSString	*kMBMConfirmationTypeKey = @"type";

//	Progress handling
NSString	*kMBMInstallationProgressNotification = @"MBMInstallationProgressNotification";
NSString	*kMBMInstallationProgressDescriptionKey = @"installation-description";
NSString	*kMBMInstallationProgressValueKey = @"progress-value";

//	Useful values based on Mail
NSString	*kMBMMessageBundlePath = @"Frameworks/Message.framework";
NSString	*kMBMMailBundleIdentifier = @"com.apple.mail";
NSString	*kMBMMailBundleExtension = @"mailbundle";
NSString	*kMBMMailBundleUUIDKey = @"PluginCompatibilityUUID";
NSString	*kMBMMailBundleUUIDListKey = @"SupportedPluginCompatibilityUUIDs";

//	Names for objects in MBM
NSString	*kMBMAnimationBackgroundImageName = @"InstallAnimationBackground";



#pragma mark - Global Functions

BOOL IsMailRunning(void) {
	BOOL mailIsRunning = NO;
	NSArray *launchedApps = [[NSWorkspace sharedWorkspace] launchedApplications];
	for (NSDictionary *app in launchedApps) {
		if ([[app objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:kMBMMailBundleIdentifier])
			mailIsRunning = YES;
	}
	return mailIsRunning;
}


BOOL QuitMail(void) {
	
	//	If it's not running, just return success
	if (!IsMailRunning()) {
		return YES;
	}
	
	NSString		*bundleID = kMBMMailBundleIdentifier;
	OSStatus		result = noErr;
	AEAddressDesc	target = {};
	AEInitializeDesc(&target);
	
	const char	*bundleIDString = [bundleID UTF8String];
	
	result = AECreateDesc(typeApplicationBundleID, bundleIDString, strlen(bundleIDString), &target);
	if (result == noErr) {
		AppleEvent	event = {};
		AEInitializeDesc(&event);
		
		result = AECreateAppleEvent( kCoreEventClass, kAEQuitApplication, &target, kAutoGenerateReturnID, kAnyTransactionID, &event );
		if (result == noErr) {
			AppleEvent	reply = {};
			AEInitializeDesc(&reply);
			
			// Send the Apple event and Wait 10 seconds for it to quit  (before timing out)	
			// if the wait is not here Bundle Manager quits and before Host Application does and the relaunch will relaunch an open application.
			// then the Apple event will be processed and quit the open application and so it will seem that the application will not relaunch.
			
			result = AESendMessage(&event, &reply, kAEWaitReply, 600);
			
			AEDisposeDesc(&event);
		}
		
		AEDisposeDesc(&target);
	}
	
	return (result == noErr);
}

BOOL IsValidPackageFile(NSString *packageFilePath) {
	
	//	The extension should be our extension
	if (![[packageFilePath pathExtension] isEqualToString:kMBMInstallerFileExtension]) {
		ALog(@"Installation file (%@) does not have a proper file extension (%@).", packageFilePath, kMBMInstallerFileExtension);
		return NO;
	}
	
	//	Also ensure that the path is a folder and exists
	BOOL	isFolder = NO;
	if (![[NSFileManager defaultManager] fileExistsAtPath:packageFilePath isDirectory:&isFolder] || !isFolder) {
		ALog(@"Installation file (%@) either doesn't exist or is not a folder.", packageFilePath);
		return NO;
	}
	
	//	Ensure that the filename is a package
	if (![[NSWorkspace sharedWorkspace] isFilePackageAtPath:packageFilePath]) {
		ALog(@"Installation file (%@) is not a package.", packageFilePath);
		return NO;
	}
	
	return YES;
}

