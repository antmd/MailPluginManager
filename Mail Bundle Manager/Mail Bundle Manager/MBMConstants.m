//
//  MBMConstants.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MBMConstants.h"

//	Command line keys
NSString	*kMBMCommandLineUninstallKey = @"-uninstall";
NSString	*kMBMCommandLineUpdateKey = @"-update";
NSString	*kMBMCommandLineCheckCrashReportsKey = @"-send-crash-reports";
NSString	*kMBMCommandLineUpdateAndCrashReportsKey = @"-update-and-crash-reports";
NSString	*kMBMCommandLineValidateAllKey = @"-validate-all";

//	Extensions and commonly used values
NSString	*kMBMPlistExtension = @"plist";
NSString	*kMBMInstallerFileExtension = @"mbinstall";
NSString	*kMBMUninstallerFileExtension = @"mbremove";
NSString	*kMBMManifestName = @"mbm-manifest";
NSString	*kMBMMailFolderName = @"Mail";
NSString	*kMBMBundleFolderName = @"Bundles";
NSString	*kMBMAppSupportFolderName = @"Mail Bundle Support";
NSString	*kMBMGenericBundleIcon = @"GenericPlugin";

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
NSString	*kMBMUserCanChooseDomainKey = @"user-can-choose-domain";
//	Keys for the action items and sub objects
NSString	*kMBMConfirmationStepsKey = @"confirmation-steps";
NSString	*kMBMConfirmationTitleKey = @"title";
NSString	*kMBMConfirmationBulletTitleKey = @"bullet-title";
NSString	*kMBMConfirmationShouldAgreeToLicense = @"license-agreement-required";
NSString	*kMBMConfirmationTypeKey = @"type";

//	Keys for historical UUID plist
NSString	*kMBMUUIDTypeKey = @"type";
NSString	*kMBMUUIDEarliestVersionKey = @"earliest-version";
NSString	*kMBMUUIDLatestVersionKey = @"latest-version";
NSString	*kMBMUUIDLatestVersionTestKey = @"latest-version-comparator";
NSString	*kMBMUUIDTypeValueMail = @"mail";
NSString	*kMBMUUIDTypeValueMessage = @"message";
NSString	*kMBMHistoricalUUIDFileName = @"uuids";

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
//	Other info.plist keys and values
NSString	*kMBMBundleUsesMBMKey = @"PluginUsesMailBundleManager";
NSString	*kMBMCompanyNameKey = @"MBMCompanyName";
NSString	*kMBMCompanyURLKey = @"MBMCompanyURL";
NSString	*kMBMProductURLKey = @"MBMProductURL";
NSString	*kMBMUnknownCompanyValue = @"<MBMCompanyUnknown>";

//	Notifications
NSString	*kMBMMailBundleUninstalledNotification = @"MBMMailBundleUninstalledNotification";
NSString	*kMBMDoneLoadingSparkleNotification = @"MBMDoneLoadingSparkleNotification";
NSString	*kMBMMailStatusChangedNotification = @"MBMMailStatusChangedNotification";

NSString	*kMBMCompaniesInfoFileName = @"companies";

//	Names for objects in MBM
NSString	*kMBMAnimationBackgroundImageName = @"InstallAnimationBackground";



