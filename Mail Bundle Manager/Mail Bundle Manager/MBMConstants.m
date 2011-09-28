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

//	Keys for top level of manifest
NSString	*kMBMBackgroundImagePathKey = @"background-image-path";
NSString	*kMBMDisplayNameKey = @"display-name";
NSString	*kMBMMinOSVersionKey = @"min-os-major-version";
NSString	*kMBMMaxOSVersionKey = @"max-os-major-version";
NSString	*kMBMMinMailVersionKey = @"min-mail-version";
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

