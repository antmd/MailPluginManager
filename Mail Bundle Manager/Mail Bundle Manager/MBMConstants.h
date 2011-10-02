//
//  MBMConstants.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

//	Command line keys
extern NSString	*kMBMCommandLineInstallKey;
extern NSString	*kMBMCommandLineUninstallKey;
extern NSString	*kMBMCommandLineUpdateKey;
extern NSString	*kMBMCommandLineCheckCrashReportsKey;
extern NSString	*kMBMCommandLineUpdateAndCrashReportsKey;
extern NSString	*kMBMCommandLineValidateAllKey;

//	Extensions and commonly used values
extern NSString	*kMBMPlistExtension;
extern NSString	*kMBMInstallerFileExtension;
extern NSString	*kMBMUninstallerFileExtension;
extern NSString	*kMBMManifestName;
extern NSString	*kMBMMailFolderName;
extern NSString	*kMBMBundleFolderName;
extern NSString	*kMBMAppSupportFolderName;
extern NSString	*kMBMGenericBundleIcon;

//	Keys for top level of manifest
extern NSString	*kMBMManifestTypeKey;
extern NSString	*kMBMManifestTypeInstallValue;
extern NSString	*kMBMManifestTypeUninstallValue;
extern NSString	*kMBMBackgroundImagePathKey;
extern NSString	*kMBMDisplayNameKey;
extern NSString	*kMBMMinOSVersionKey;
extern NSString	*kMBMMaxOSVersionKey;
extern NSString	*kMBMMinMailVersionKey;
extern NSString	*kMBMCanDeleteManagerIfNotUsedByOthersKey;
extern NSString	*kMBMCanDeleteManagerIfNoBundlesKey;
//	Keys for the action items and sub objects
extern NSString	*kMBMActionItemsKey;
extern NSString	*kMBMPathKey;
extern NSString	*kMBMNameKey;
extern NSString	*kMBMDestinationPathKey;
extern NSString	*kMBMDescriptionKey;
extern NSString	*kMBMPermissionsKey;
extern NSString	*kMBMIsBundleManagerKey;
//	Keys for the action items and sub objects
extern NSString	*kMBMConfirmationStepsKey;
extern NSString	*kMBMConfirmationTitleKey;
extern NSString	*kMBMConfirmationBulletTitleKey;
extern NSString	*kMBMConfirmationShouldAgreeToLicense;
extern NSString	*kMBMConfirmationTypeKey;

//	Keys for historical UUID plist
extern NSString	*kMBMUUIDTypeKey;
extern NSString	*kMBMUUIDEarliestVersionKey;
extern NSString	*kMBMUUIDLatestVersionKey;
extern NSString	*kMBMUUIDLatestVersionTestKey;
extern NSString	*kMBMUUIDTypeValueMail;
extern NSString	*kMBMUUIDTypeValueMessage;
extern NSString	*kMBMHistoricalUUIDFileName;

//	Progress handling
extern NSString	*kMBMInstallationProgressNotification;
extern NSString	*kMBMInstallationProgressDescriptionKey;
extern NSString	*kMBMInstallationProgressValueKey;

//	Useful values based on Mail
extern NSString	*kMBMMessageBundlePath;
extern NSString	*kMBMMailBundleIdentifier;
extern NSString	*kMBMMailBundleExtension;
extern NSString	*kMBMMailBundleUUIDKey;
extern NSString	*kMBMMailBundleUUIDListKey;
//	Other info.plist keys and values
extern NSString	*kMBMBundleUsesMBMKey;
extern NSString	*kMBMCompanyNameKey;
extern NSString	*kMBMCompanyURLKey;
extern NSString	*kMBMUnknownCompanyValue;

extern NSString	*kMBMCompaniesInfoFileName;

//	Names for objects in MBM
extern NSString	*kMBMAnimationBackgroundImageName;

typedef enum {
	kMBMStatusUnknown,
	kMBMStatusEnabled,
	kMBMStatusDisabled,
	kMBMStatusUninstalled
} MBMBundleStatus;

typedef enum {
	kMBMConfirmationTypeInformation,
	kMBMConfirmationTypeLicense,
	kMBMConfirmationTypeConfirm
} MBMConfirmationType;

typedef enum {
	kMBMManifestTypeUnknown,
	kMBMManifestTypeInstallation,
	kMBMManifestTypeUninstallation
} MBMManifestType;


#define	kMBMNoVersionRequirement	-1.0


//	Functions
BOOL IsMailRunning(void);
BOOL QuitMail(void);
NSString *CurrentMailUUID(void);
NSString *CurrentMessageUUID(void);
NSDictionary *HistoricalUUIDInformation(void);
BOOL IsValidPackageFile(NSString *packageFilePath);

#define PerformOnAppDelegate(aSelectorString)						[[NSApp delegate] performSelector:NSSelectorFromString(aSelectorString)]
#define PerformOnAppDelegate1(aSelectorString, object)				[[NSApp delegate] performSelector:NSSelectorFromString(aSelectorString) withObject:object]
#define PerformOnAppDelegate2(aSelectorString, object1, object2)	[[NSApp delegate] performSelector:NSSelectorFromString(aSelectorString) withObject:object1 withObject:object2]

#define	MBMLocalizedStringFromPackageFile(string, packageFilePath)	(([NSBundle bundleWithPath:packageFilePath]==nil)?string:NSLocalizedStringFromTableInBundle(string, nil, [NSBundle bundleWithPath:packageFilePath], @""))

