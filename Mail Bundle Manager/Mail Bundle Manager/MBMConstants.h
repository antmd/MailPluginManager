//
//  MBMConstants.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

extern NSString	*kMBMCommandLineInstallKey;
extern NSString	*kMBMCommandLineUninstallKey;
extern NSString	*kMBMCommandLineUpdateKey;
extern NSString	*kMBMCommandLineCheckCrashReportsKey;
extern NSString	*kMBMCommandLineUpdateAndCrashReportsKey;
extern NSString	*kMBMCommandLineValidateAllKey;

extern NSString	*kMBMPlistExtension;
extern NSString	*kMBMInstallManifestName;
extern NSString	*kMBMMailFolderName;
extern NSString	*kMBMBundleFolderName;
extern NSString	*kMBMDisabledBundleFolderPrefix;

extern NSString	*kMBMInstallerFileExtension;
extern NSString	*kMBMInstallBGImagePathKey;
extern NSString	*kMBMInstallDisplayNameKey;
extern NSString	*kMBMInstallItemsKey;
extern NSString	*kMBMNameKey;
extern NSString	*kMBMDescriptionKey;
extern NSString	*kMBMPermissionsKey;
extern NSString	*kMBMPathKey;
extern NSString	*kMBMPathIsHTMLKey;
extern NSString	*kMBMDestinationPathKey;
extern NSString	*kMBMMinOSVersionKey;
extern NSString	*kMBMMaxOSVersionKey;
extern NSString	*kMBMMinMailVersionKey;
extern NSString	*kMBMIsBundleManagerKey;

extern NSString	*kMBMConfirmationStepsKey;
extern NSString	*kMBMConfirmationTitleKey;
extern NSString	*kMBMConfirmationBulletTitleKey;
extern NSString	*kMBMConfirmationShouldAgreeToLicense;
extern NSString	*kMBMConfirmationTypeKey;

extern NSString	*kMBMInstallationProgressNotification;
extern NSString	*kMBMInstallationProgressDescriptionKey;
extern NSString	*kMBMInstallationProgressValueKey;

extern NSString	*kMBMMailBundleIdentifier;
extern NSString	*kMBMMailBundleExtension;
extern NSString	*kMBMMailBundleUUIDKey;
extern NSString	*kMBMMailBundleUUIDListKey;
extern NSString	*kMBMMessageBundlePath;

extern NSString	*kMBMAnimationBackgroundImageName;

typedef enum {
	kMBMStatusEnabled,
	kMBMStatusDisabled,
	kMBMStatusUninstalled,
	kMBMStatusUnknown
} MBMBundleStatus;

typedef enum {
	kMBMConfirmationTypeReleaseNotes,
	kMBMConfirmationTypeLicense,
	kMBMConfirmationTypeConfirm
} MBMConfirmationType;


#define	kMBMNoVersionRequirement	-1.0


#define PerformOnAppDelegate(aSelectorString)						[[NSApp delegate] performSelector:NSSelectorFromString(aSelectorString)]
#define PerformOnAppDelegate1(aSelectorString, object)				[[NSApp delegate] performSelector:NSSelectorFromString(aSelectorString) withObject:object]
#define PerformOnAppDelegate2(aSelectorString, object1, object2)	[[NSApp delegate] performSelector:NSSelectorFromString(aSelectorString) withObject:object1 withObject:object2]

#define	MBMLocalizedStringFromInstallFile(string, installFilePath)	NSLocalizedStringFromTableInBundle(string, nil, [NSBundle bundleWithPath:installFilePath], @"")

