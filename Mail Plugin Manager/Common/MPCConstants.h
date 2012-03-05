//
//  MPCConstants.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#define STR_CONST(name, value) extern NSString* const name
#include "MPCConstantsList.h"


typedef enum {
	kMPCConfirmationTypeInformation,
	kMPCConfirmationTypeLicense,
	kMPCConfirmationTypeConfirm
} MPCConfirmationType;

typedef enum {
	kMPCManifestTypeUnknown,
	kMPCManifestTypeInstallation,
	kMPCManifestTypeUninstallation
} MPCManifestType;



#define	kMPCNoVersionRequirement		-1.0
#define	kMPCDefaultMailPluginVersion	4

#define PerformOnAppDelegate(aSelectorString)						[[NSApp delegate] performSelector:NSSelectorFromString(aSelectorString)]
#define PerformOnAppDelegate1(aSelectorString, object)				[[NSApp delegate] performSelector:NSSelectorFromString(aSelectorString) withObject:object]
#define PerformOnAppDelegate2(aSelectorString, object1, object2)	[[NSApp delegate] performSelector:NSSelectorFromString(aSelectorString) withObject:object1 withObject:object2]

#define	MPCLocalizedStringFromPackageFile(string, packageFilePath)	(([NSBundle bundleWithPath:packageFilePath]==nil)?string:NSLocalizedStringFromTableInBundle(string, nil, [NSBundle bundleWithPath:packageFilePath], @""))

