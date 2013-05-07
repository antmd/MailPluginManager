
//	Constant Definitions

//	Command line keys
STR_CONST(kMPCCommandLineUninstallKey, "-uninstall");
STR_CONST(kMPCCommandLineUpdateKey, "-update");
STR_CONST(kMPCCommandLineCheckCrashReportsKey, "-send-crash-reports");
STR_CONST(kMPCCommandLineUpdateAndCrashReportsKey, "-update-and-crash-reports");
STR_CONST(kMPCCommandLineSystemInfoKey, "-mail-info");
STR_CONST(kMPCCommandLineUUIDListKey, "-uuid-list");
STR_CONST(kMPCCommandLineInstallLaunchAgentKey, "-add-launch-agent");
STR_CONST(kMPCCommandLineRemoveLaunchAgentKey, "-del-launch-agent");
STR_CONST(kMPCCommandLineFrequencyOptionKey, "-freq");
STR_CONST(kMPCCommandLineValidateAllKey, "-validate-all");
STR_CONST(kMPCCommandLineFinishInstallKey, "-finish-install");
STR_CONST(kMPCCommandLineFileLoadKey, "-file-load");
STR_CONST(kMPCCommandLineInstallScriptKey, "-install-script");
STR_CONST(kMPCCommandLineRemoveScriptKey, "-remove-script");

//	Extensions and commonly used values
STR_CONST(kMPCPlistExtension, "plist");
STR_CONST(kMPCInstallerFileExtension, "mpinstall");
STR_CONST(kMPCUninstallerFileExtension, "mpremove");
STR_CONST(kMPCManifestName, "mpm-manifest");
STR_CONST(kMPCMailFolderName, "Mail");
STR_CONST(kMPCBundleFolderName, "Bundles");
STR_CONST(kMPCMailPluginManagerBundleID, "com.littleknownsoftware.MailPluginManager");
STR_CONST(kMPCUserDefaultSharedDomainName, "com.littleknownsoftware.MailPluginShared");
STR_CONST(kMPCSharedApplicationSupportName, "MailPluginShared");
STR_CONST(kMPCRelativeToolPath, "Contents/Resources/MailPluginTool.app");
STR_CONST(kMPCGenericBundleIcon, "GenericPlugin");
STR_CONST(kMPCContainersPathFormat, "Containers/%@/Data/Library");
STR_CONST(kMPCPreferencesFolderName, "Preferences");


//	Keys for top level of manifest
STR_CONST(kMPCManifestTypeKey, "manifest-type");
STR_CONST(kMPCManifestTypeInstallValue, "install");
STR_CONST(kMPCManifestTypeUninstallValue, "uninstall");
STR_CONST(kMPCBackgroundImagePathKey, "background-image-path");
STR_CONST(kMPCDisplayNameKey, "display-name");
STR_CONST(kMPCMinOSVersionKey, "min-os-major-version");
STR_CONST(kMPCMaxOSVersionKey, "max-os-major-version");
STR_CONST(kMPCMinMailVersionKey, "min-mail-version");
STR_CONST(kMPCCanDeleteManagerIfNotUsedByOthersKey, "can-delete-bundle-manager-if-no-other-plugins-use");
STR_CONST(kMPCCanDeleteManagerIfNoBundlesKey, "can-delete-bundle-manager-if-no-plugins-left");
STR_CONST(kMPCMinMailBundleVersionKey, "configure-mail-min-bundle-version");
STR_CONST(kMPCDontRestartMailKey, "do-not-ever-restart-mail");
STR_CONST(kMPCCompletionMessageKey, "completion-message");

//	Keys for the action items and sub objects
STR_CONST(kMPCActionItemsKey, "action-items");
STR_CONST(kMPCPathKey, "path");
STR_CONST(kMPCNameKey, "name");
STR_CONST(kMPCVersionKey, "version");
STR_CONST(kMPCDestinationPathKey, "destination-path");
STR_CONST(kMPCDestinationDomainKey, "<LibraryDomain>");
STR_CONST(kMPCDescriptionKey, "description");
STR_CONST(kMPCPermissionsKey, "permissions-needed");
STR_CONST(kMPCIsBundleManagerKey, "is-bundle-manager");
STR_CONST(kMPCShouldDeletePathKey, "should-delete-path-if-exists");
STR_CONST(kMPCShouldHideItemKey, "should-hide-item");
STR_CONST(kMPCUserCanChooseDomainKey, "user-can-choose-domain");
//	Keys for the confirmation items and sub objects
STR_CONST(kMPCConfirmationStepsKey, "confirmation-steps");
STR_CONST(kMPCConfirmationTitleKey, "title");
STR_CONST(kMPCConfirmationBulletTitleKey, "bullet-title");
STR_CONST(kMPCConfirmationShouldAgreeToLicense, "license-agreement-required");
STR_CONST(kMPCConfirmationTypeKey, "type");
//	Keys for the launch items and sub objects
STR_CONST(kMPCLaunchItemsKey, "launch-items");
//	Other error keys
STR_CONST(kMPCErrorKey, "mpc-error");

//	Keys for historical UUID plist
STR_CONST(kMPCUUIDTypeKey, "type");
STR_CONST(kMPCUUIDEarliestOSVersionDisplayKey, "earliest-os-version-display");
STR_CONST(kMPCUUIDEarliestOSVersionKey, "earliest-os-version");
STR_CONST(kMPCUUIDLatestOSVersionDisplayKey, "latest-os-version-display");
STR_CONST(kMPCUUIDLatestOSVersionKey, "latest-os-version");
STR_CONST(kMPCUUIDLatestVersionTestKey, "latest-version-comparator");
STR_CONST(kMPCUUIDTypeValueMail, "mail");
STR_CONST(kMPCUUIDTypeValueMessage, "message");
STR_CONST(kMPCUUIDListFileName, "uuids");
STR_CONST(kMPCUUIDAllUUIDListKey, "all-uuids");
STR_CONST(kMPCUUIDLatestUUIDDictKey, "latest-supported-uuid-dict");
STR_CONST(kMPCUUIDFirstUnsupportedUUIDDictKey, "first-unsupported-uuid-dict");
STR_CONST(kMPCUUIDNotificationSenderKey, "sender-id");

//	Keys for System Information dictionary
STR_CONST(kMPCSysInfoKey, "system-info");
STR_CONST(kMPCAnonymousIDKey, "anonymous-id");
STR_CONST(kMPCSysInfoSystemKey, "system");
STR_CONST(kMPCSysInfoMailKey, "mail");
STR_CONST(kMPCSysInfoMessageKey, "message");
STR_CONST(kMPCSysInfoVersionKey, "version");
STR_CONST(kMPCSysInfoBuildKey, "build");
STR_CONST(kMPCSysInfoUUIDKey, "uuid");
STR_CONST(kMPCSysInfoHardwareKey, "hardware");
STR_CONST(kMPCSysInfoInstalledMailPluginsKey, "installed");
STR_CONST(kMPCSysInfoDisabledMailPluginsKey, "disabled");

STR_CONST(kMPCSysInfoContainerPrefsKey, "container-prefs");
STR_CONST(kMPCSysInfoLaunchAgentsKey, "launch-agents");
STR_CONST(kMPCSysInfoLaunchAgentFilesKey, "files");
STR_CONST(kMPCSysInfoLaunchAgentListKey, "list");
STR_CONST(kMPCSysInfoPluginManagerKey, "plugin-manager");
STR_CONST(kMPCSysInfoBranchNameKey, "branch-name");
STR_CONST(kMPCSysInfoBuildSHAKey, "build-sha");


STR_CONST(kMPCLocalMailFolderPlaceholder, "[LOCALMailFolder]");
STR_CONST(kMPCUserMailFolderPlaceholder, "[USERMailFolder]");

//	Progress handling
STR_CONST(kMPCInstallationProgressNotification, "MPCInstallationProgressNotification");
STR_CONST(kMPCInstallationProgressDescriptionKey, "installation-description");
STR_CONST(kMPCInstallationProgressValueKey, "progress-value");

//	Useful values based on Mail
STR_CONST(kMPCMessageBundlePath, "Frameworks/Message.framework");
STR_CONST(kMPCMailBundleIdentifier, "com.apple.mail");
STR_CONST(kMPCMailBundleExtension, "mailbundle");
STR_CONST(kMPCMailBundleUUIDKey, "PluginCompatibilityUUID");
STR_CONST(kMPCMailBundleUUIDListKey, "SupportedPluginCompatibilityUUIDs");
//	Other info.plist keys and values
STR_CONST(kMPCBundleUsesMPMKey, "MPCPluginUsesMailPluginManager");
STR_CONST(kMPCCompanyNameKey, "MPCCompanyName");
STR_CONST(kMPCCompanyURLKey, "MPCCompanyURL");
STR_CONST(kMPCProductURLKey, "MPCProductURL");
STR_CONST(kMPCCrashReportURLKey, "MPCCrashReportURL");
STR_CONST(kMPCMaxCrashReportCountKey, "MPCMaxCrashReportsToSend");
STR_CONST(kMPCUnknownCompanyValue, "<MPCCompanyUnknown>");
STR_CONST(kMPCSupplementalSparkleFeedParametersKey, "MPCSupplementalSparkleFeedParameters");
STR_CONST(kMPCPrefsMigratedToSandboxPrefKey, "MPCPrefsMigratedToSandbox");

//	The send crash reports values
STR_CONST(kMPTLastReportDatePrefKey, "MPTCrashReportedLastReportDate");
STR_CONST(kMPTReportListKey, "report-list");

//	Notifications
STR_CONST(kMPCMailBundleUninstalledNotification, "MPCMailBundleUninstalledNotification");
STR_CONST(kMPCMailBundleDisabledNotification, "MPCMailBundleDisabledNotification");
STR_CONST(kMPCMailBundleNoActionTakenNotification, "MPCMailBundleNoActionTakenNotification");
STR_CONST(kMPCDoneLoadingSparkleNotification, "MPCDoneLoadingSparkleNotification");
STR_CONST(kMPCMailStatusChangedNotification, "MPCMailStatusChangedNotification");
STR_CONST(kMPCDoneUpdatingMailBundleNotification, "MPCDoneUpdatingMailBundleNotification");
STR_CONST(kMPCCancelledUpdatingMailBundleNotification, "MPCCancelledUpdatingMailBundleNotification");
STR_CONST(kMPCDoneSendingCrashReportsMailBundleNotification, "MPCDoneSendingCrashReportsMailBundleNotification");
STR_CONST(kMPCSUUpdateDriverAbortNotification, "SUUpdateDriverFinished");
STR_CONST(kMPCRestartMailNowNotification, "com.littleknownsoftware.MPCRestartMailNowNotification");

//	Sparkle info Distributed Notifications
STR_CONST(kMPCBundleUpdateStatusDistNotification, "com.littleknownsoftware.MPCBundleUpdateStatusDistNotification");
STR_CONST(kMPCBundleWillInstallDistNotification, "com.littleknownsoftware.MPCBundleWillInstallDistNotification");

//	Tool Distributed Notifications
STR_CONST(kMPTSystemInfoDistNotification, "com.littleknownsoftware.MPTSystemInfoDistNotification");
STR_CONST(kMPTUUIDListDistNotification, "com.littleknownsoftware.MPTUUIDListDistNotification");

STR_CONST(kMPCNotificationWaitNote, "note");
STR_CONST(kMPCNotificationWaitObject, "object");
STR_CONST(kMPCNotificationWaitReceived, "received");
STR_CONST(kMPCNotificationWaitObserver, "observer");

//	Names for objects in MPM
STR_CONST(kMPCAnimationBackgroundImageName, "InstallAnimationBackground");
STR_CONST(kMPCWindowBackgroundImageName, "MPCBackgroundImage");

//	Paths
STR_CONST(kMPCRemoteUpdateableListPathURL, "https://raw.github.com/lksoft/MailPluginManager/master/Remote/");
STR_CONST(kMPCCompaniesInfoFileName, "companies");

//	Mail Compatibility
STR_CONST(kMPCBundleCompatibilityVersionKey, "BundleCompatibilityVersion");
STR_CONST(kMPCEnableBundlesKey, "EnableBundles");

