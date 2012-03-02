
//	Constant Definitions

//	Command line keys
STR_CONST(kMBMCommandLineUninstallKey, "-uninstall");
STR_CONST(kMBMCommandLineUpdateKey, "-update");
STR_CONST(kMBMCommandLineCheckCrashReportsKey, "-send-crash-reports");
STR_CONST(kMBMCommandLineUpdateAndCrashReportsKey, "-update-and-crash-reports");
STR_CONST(kMBMCommandLineSystemInfoKey, "-mail-info");
STR_CONST(kMBMCommandLineUUIDListKey, "-uuid-list");
STR_CONST(kMBMCommandLineFrequencyOptionKey, "-freq");
STR_CONST(kMBMCommandLineValidateAllKey, "-validate-all");

//	Extensions and commonly used values
STR_CONST(kMBMPlistExtension, "plist");
STR_CONST(kMBMInstallerFileExtension, "mbinstall");
STR_CONST(kMBMUninstallerFileExtension, "mbremove");
STR_CONST(kMBMManifestName, "mbm-manifest");
STR_CONST(kMBMMailFolderName, "Mail");
STR_CONST(kMBMBundleFolderName, "Bundles");
STR_CONST(kMBMMailPluginManagerBundleID, "com.littleknownsoftware.MailPluginManager");
STR_CONST(kMBMUserDefaultSharedDomainName, "com.littleknownsoftware.MailPluginShared");
STR_CONST(kMBMGenericBundleIcon, "GenericPlugin");

//	Keys for top level of manifest
STR_CONST(kMBMManifestTypeKey, "manifest-type");
STR_CONST(kMBMManifestTypeInstallValue, "install");
STR_CONST(kMBMManifestTypeUninstallValue, "uninstall");
STR_CONST(kMBMBackgroundImagePathKey, "background-image-path");
STR_CONST(kMBMDisplayNameKey, "display-name");
STR_CONST(kMBMMinOSVersionKey, "min-os-major-version");
STR_CONST(kMBMMaxOSVersionKey, "max-os-major-version");
STR_CONST(kMBMMinMailVersionKey, "min-mail-version");
STR_CONST(kMBMCanDeleteManagerIfNotUsedByOthersKey, "can-delete-bundle-manager-if-no-other-plugins-use");
STR_CONST(kMBMCanDeleteManagerIfNoBundlesKey, "can-delete-bundle-manager-if-no-plugins-left");
STR_CONST(kMBMMinMailBundleVersionKey, "configure-mail-min-bundle-version");
STR_CONST(kMBMDontRestartMailKey, "do-not-ever-restart-mail");
STR_CONST(kMBMCompletionMessageKey, "completion-message");

//	Keys for the action items and sub objects
STR_CONST(kMBMActionItemsKey, "action-items");
STR_CONST(kMBMPathKey, "path");
STR_CONST(kMBMNameKey, "name");
STR_CONST(kMBMVersionKey, "version");
STR_CONST(kMBMDestinationPathKey, "destination-path");
STR_CONST(kMBMDestinationDomainKey, "<LibraryDomain>");
STR_CONST(kMBMDescriptionKey, "description");
STR_CONST(kMBMPermissionsKey, "permissions-needed");
STR_CONST(kMBMIsBundleManagerKey, "is-bundle-manager");
STR_CONST(kMBMUserCanChooseDomainKey, "user-can-choose-domain");
//	Keys for the action items and sub objects
STR_CONST(kMBMConfirmationStepsKey, "confirmation-steps");
STR_CONST(kMBMConfirmationTitleKey, "title");
STR_CONST(kMBMConfirmationBulletTitleKey, "bullet-title");
STR_CONST(kMBMConfirmationShouldAgreeToLicense, "license-agreement-required");
STR_CONST(kMBMConfirmationTypeKey, "type");
//	Other error keys
STR_CONST(kMBMErrorKey, "error");

//	Keys for historical UUID plist
STR_CONST(kMBMUUIDTypeKey, "type");
STR_CONST(kMBMUUIDEarliestOSVersionDisplayKey, "earliest-os-version-display");
STR_CONST(kMBMUUIDEarliestOSVersionKey, "earliest-os-version");
STR_CONST(kMBMUUIDLatestOSVersionDisplayKey, "latest-os-version-display");
STR_CONST(kMBMUUIDLatestOSVersionKey, "latest-os-version");
STR_CONST(kMBMUUIDMailMessageVersionKey, "types-version");
STR_CONST(kMBMUUIDMailMessageVersionDisplayKey, "type-version-display");
STR_CONST(kMBMUUIDLatestVersionTestKey, "latest-version-comparator");
STR_CONST(kMBMUUIDTypeValueMail, "mail");
STR_CONST(kMBMUUIDTypeValueMessage, "message");
STR_CONST(kMBMUUIDListFileName, "uuids");
STR_CONST(kMBMUUIDAllUUIDListKey, "all-uuids");
STR_CONST(kMBMUUIDLatestUUIDDictKey, "latest-supported-uuid-dict");
STR_CONST(kMBMUUIDFirstUnsupportedUUIDDictKey, "first-unsupported-uuid-dict");
STR_CONST(kMBMUUIDNotificationSenderKey, "sender-id");

//	Keys for System Information dictionary
STR_CONST(kMBMSysInfoKey, "system-info");
STR_CONST(kMBMSysInfoSystemKey, "system");
STR_CONST(kMBMSysInfoMailKey, "mail");
STR_CONST(kMBMSysInfoMessageKey, "message");
STR_CONST(kMBMSysInfoVersionKey, "version");
STR_CONST(kMBMSysInfoBuildKey, "build");
STR_CONST(kMBMSysInfoUUIDKey, "uuid");
STR_CONST(kMBMSysInfoHardwareKey, "hardware");
STR_CONST(kMBMSysInfoInstalledMailPluginsKey, "installed");
STR_CONST(kMBMSysInfoDisabledMailPluginsKey, "disabled");

//	Progress handling
STR_CONST(kMBMInstallationProgressNotification, "MBMInstallationProgressNotification");
STR_CONST(kMBMInstallationProgressDescriptionKey, "installation-description");
STR_CONST(kMBMInstallationProgressValueKey, "progress-value");

//	Useful values based on Mail
STR_CONST(kMBMMessageBundlePath, "Frameworks/Message.framework");
STR_CONST(kMBMMailBundleIdentifier, "com.apple.mail");
STR_CONST(kMBMMailBundleExtension, "mailbundle");
STR_CONST(kMBMMailBundleUUIDKey, "PluginCompatibilityUUID");
STR_CONST(kMBMMailBundleUUIDListKey, "SupportedPluginCompatibilityUUIDs");
//	Other info.plist keys and values
STR_CONST(kMBMBundleUsesMBMKey, "PluginUsesMailPluginManager");
STR_CONST(kMBMCompanyNameKey, "MBMCompanyName");
STR_CONST(kMBMCompanyURLKey, "MBMCompanyURL");
STR_CONST(kMBMProductURLKey, "MBMProductURL");
STR_CONST(kMBMUnknownCompanyValue, "<MBMCompanyUnknown>");

//	Notifications
STR_CONST(kMBMMailBundleUninstalledNotification, "MBMMailBundleUninstalledNotification");
STR_CONST(kMBMMailBundleDisabledNotification, "MBMMailBundleDisabledNotification");
STR_CONST(kMBMMailBundleNoActionTakenNotification, "MBMMailBundleNoActionTakenNotification");
STR_CONST(kMBMDoneLoadingSparkleNotification, "MBMDoneLoadingSparkleNotification");
STR_CONST(kMBMMailStatusChangedNotification, "MBMMailStatusChangedNotification");
STR_CONST(kMBMSystemInfoDistNotification, "MBMSystemInfoDistNotification");
STR_CONST(kMBMUUIDListDistNotification, "MBMUUIDListDistNotification");
STR_CONST(kMBMDoneUpdatingMailBundleNotification, "MBMDoneUpdatingMailBundleNotification");
STR_CONST(kMBMCancelledUpdatingMailBundleNotification, "MBMCancelledUpdatingMailBundleNotification");
STR_CONST(kMBMDoneSendingCrashReportsMailBundleNotification, "MBMDoneSendingCrashReportsMailBundleNotification");
STR_CONST(kMBMSUUpdateDriverAbortNotification, "SUUpdateDriverFinished");

STR_CONST(kMBMNotificationWaitNote, "note");
STR_CONST(kMBMNotificationWaitObject, "object");
STR_CONST(kMBMNotificationWaitReceived, "received");
STR_CONST(kMBMNotificationWaitObserver, "observer");

//	Names for objects in MBM
STR_CONST(kMBMAnimationBackgroundImageName, "InstallAnimationBackground");
STR_CONST(kMBMWindowBackgroundImageName, "MBMBackgroundImage");

//	Paths
STR_CONST(kMBMRemoteUpdateableListPathURL, "https://raw.github.com/lksoft/MailPluginManager/master/Remote/");
STR_CONST(kMBMCompaniesInfoFileName, "companies");

//	Mail Compatibility
STR_CONST(kMBMBundleCompatibilityVersionKey, "BundleCompatibilityVersion");
STR_CONST(kMBMEnableBundlesKey, "EnableBundles");

