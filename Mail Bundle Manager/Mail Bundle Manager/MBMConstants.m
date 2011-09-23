//
//  MBMConstants.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MBMConstants.h"

NSString	*kMBMCommandLineInstallKey = @"-install";
NSString	*kMBMCommandLineUninstallKey = @"-uninstall";
NSString	*kMBMCommandLineUpdateKey = @"-update";
NSString	*kMBMCommandLineCheckCrashReportsKey = @"-check-crash-reports";
NSString	*kMBMCommandLineUpdateAndCrashReportsKey = @"-update-and-crash-reports";
NSString	*kMBMCommandLineValidateAllKey = @"-validate-all";

NSString	*kMBMPlistExtension = @"plist";
NSString	*kMBMInstallManifestName = @"install-manifest";
NSString	*kMBMMailFolderName = @"Mail";
NSString	*kMBMBundleFolderName = @"Bundles";
NSString	*kMBMDisabledBundleFolderPrefix = @"Bundles (";

NSString	*kMBMInstallerFileExtension = @"mbinstall";
NSString	*kMBMInstallBGImagePathKey = @"install-background-image-path";
NSString	*kMBMInstallDisplayNameKey = @"install-display-name";
NSString	*kMBMInstallItemsKey = @"install-items";
NSString	*kMBMNameKey = @"name";
NSString	*kMBMDescriptionKey = @"description";
NSString	*kMBMPermissionsKey = @"permissions-needed";
NSString	*kMBMPathKey = @"path";
NSString	*kMBMPathIsHTMLKey = @"path-is-html";
NSString	*kMBMDestinationPathKey = @"destination-path";
NSString	*kMBMMinOSVersionKey = @"min-os-major-version";
NSString	*kMBMMaxOSVersionKey = @"max-os-major-version";
NSString	*kMBMMinMailVersionKey = @"min-mail-version";
NSString	*kMBMIsBundleManagerKey = @"is-bundle-manager";

NSString	*kMBMConfirmationStepsKey = @"confirmation-steps";
NSString	*kMBMConfirmationTitleKey = @"title";
NSString	*kMBMConfirmationBulletTitleKey = @"bullet-title";
NSString	*kMBMConfirmationShouldAgreeToLicense = @"license-agreement-required";
NSString	*kMBMConfirmationTypeKey = @"type";

NSString	*kMBMInstallationProgressNotification = @"MBMInstallationProgressNotification";
NSString	*kMBMInstallationProgressDescriptionKey = @"installation-description";
NSString	*kMBMInstallationProgressValueKey = @"progress-value";


NSString	*kMBMMailBundleIdentifier = @"com.apple.mail";
NSString	*kMBMMailBundleExtension = @"mailbundle";
NSString	*kMBMMailBundleUUIDKey = @"PluginCompatibilityUUID";
NSString	*kMBMMailBundleUUIDListKey = @"SupportedPluginCompatibilityUUIDs";
NSString	*kMBMMessageBundlePath = @"Frameworks/Message.framework";


NSString	*kMBMAnimationBackgroundImageName = @"InstallAnimationBackground";
