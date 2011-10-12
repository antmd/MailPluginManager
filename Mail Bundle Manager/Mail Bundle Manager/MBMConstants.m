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
NSString	*kMBMCommandLineSystemInfoKey = @"-system-info";
NSString	*kMBMCommandLineUUIDListKey = @"-uuid-list";
NSString	*kMBMCommandLineValidateAllKey = @"-validate-all";

//	Extensions and commonly used values
NSString	*kMBMPlistExtension = @"plist";
NSString	*kMBMInstallerFileExtension = @"mbinstall";
NSString	*kMBMUninstallerFileExtension = @"mbremove";
NSString	*kMBMManifestName = @"mbm-manifest";
NSString	*kMBMMailFolderName = @"Mail";
NSString	*kMBMBundleFolderName = @"Bundles";
NSString	*kMBMAppSupportFolderName = @"Mail Bundle Support";
NSString	*kMBMUserDefaultSharedDomainName = @"com.littleknownsoftware.MailBundleShared";
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
NSString	*kMBMVersionKey = @"version";
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
NSString	*kMBMUUIDEarliestOSVersionDisplayKey = @"earliest-os-version-display";
NSString	*kMBMUUIDEarliestOSVersionKey = @"earliest-os-version";
NSString	*kMBMUUIDLatestOSVersionDisplayKey = @"latest-os-version-display";
NSString	*kMBMUUIDLatestOSVersionKey = @"latest-os-version";
NSString	*kMBMUUIDMailMessageVersionKey = @"types-version";
NSString	*kMBMUUIDMailMessageVersionDisplayKey = @"types-version-display";
NSString	*kMBMUUIDLatestVersionTestKey = @"latest-version-comparator";
NSString	*kMBMUUIDTypeValueMail = @"mail";
NSString	*kMBMUUIDTypeValueMessage = @"message";
NSString	*kMBMUUIDListFileName = @"uuids";
NSString	*kMBMUUIDAllUUIDListKey = @"all-uuids";
NSString	*kMBMUUIDLatestUUIDDictKey = @"latest-supported-uuid-dict";
NSString	*kMBMUUIDFirstUnsupportedUUIDDictKey = @"first-unsupported-uuid-dict";
NSString	*kMBMUUIDNotificationSenderKey = @"sender-id";

//	Keys for System Information dictionary
NSString	*kMBMSysInfoKey = @"system-info";
NSString	*kMBMSysInfoSystemKey = @"system";
NSString	*kMBMSysInfoMailKey = @"mail";
NSString	*kMBMSysInfoMessageKey = @"message";
NSString	*kMBMSysInfoVersionKey = @"version";
NSString	*kMBMSysInfoBuildKey = @"build";
NSString	*kMBMSysInfoHardwareKey = @"hardware";
NSString	*kMBMSysInfoInstalledMailPluginsKey = @"installed";
NSString	*kMBMSysInfoDisabledMailPluginsKey = @"disabled";

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
NSString	*kMBMSystemInfoDistNotification = @"MBMSystemInfoDistNotification";
NSString	*kMBMUUIDListDistNotification = @"MBMUUIDListDistNotification";

NSString	*kMBMCompaniesInfoFileName = @"companies";

//	Names for objects in MBM
NSString	*kMBMAnimationBackgroundImageName = @"InstallAnimationBackground";



