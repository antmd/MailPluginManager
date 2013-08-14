//
//  MPIAppDelegate.m
//  Plugin Installer
//
//  Created by Scott Little on 9/3/13.
//  Copyright (c) 2013 Little Known Software. All rights reserved.
//

#import "MPIAppDelegate.h"
#import "MPCInstallerController.h"

#import <ServiceManagement/ServiceManagement.h>

typedef enum MPIAppDelegateErrorDomain {
	MPIInstallerHasBadTypeCode = 401,
	MPIUninstallerHasBadTypeCode = 402,

	MPINoInstallerFileFound = 403,
	
	MPIEndAppDelegateCode
} MPIAppDelegateErrorDomain;


@implementation MPIAppDelegate

@synthesize manifestModel = _manifestModel;

- (void)dealloc {
	self.manifestModel = nil;
    [super dealloc];
}

#pragma mark - App Delegate

//	These are the methods in the order they are called...

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	//	Call our super to setup stuff
	[super applicationDidFinishLaunching:aNotification];
	
	NSBundle		*bundle = [NSBundle mainBundle];
	NSFileManager	*manager = [NSFileManager defaultManager];
	NSURL			*deliveryURL = [NSURL URLWithString:@"Delivery" relativeToURL:[bundle bundleURL]];
	
	NSError	*error;
	NSArray	*deliveryItems = [manager contentsOfDirectoryAtURL:deliveryURL includingPropertiesForKeys:nil options:(NSDirectoryEnumerationSkipsHiddenFiles & NSDirectoryEnumerationSkipsPackageDescendants & NSDirectoryEnumerationSkipsSubdirectoryDescendants) error:&error];

	if (deliveryItems == nil) {
		//	Handle error
		LKPresentErrorCode(MPIInstallerHasBadTypeCode);
		[self quittingNowIsReasonable];
		return;
	}
	
	NSString	*installFilePath = nil;
	for (NSURL *deliveryItem in deliveryItems) {
		if ([[deliveryItem pathExtension] isEqualToString:kMPCInstallerFileExtension]) {
			installFilePath = [deliveryItem path];
			break;
		}
	}

	//	If the file is a valid type..
	if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath:installFilePath]) {
		
		//	Load the model
		self.manifestModel = [[[MPCManifestModel alloc] initWithPackageAtPath:installFilePath] autorelease];
		
		//	Determine the type (install/uninstall)
		if (self.manifestModel.manifestType != kMPCManifestTypeInstallation) {
			LKPresentErrorCode(MPIInstallerHasBadTypeCode);
			[self quittingNowIsReasonable];
			return;
		}
	}
	
	MPCInstallerController	*controller = [[[MPCInstallerController alloc] initWithManifestModel:self.manifestModel] autorelease];
	[controller showWindow:self];
	self.currentController = controller;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	
	NSDictionary	*helpers = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kSMInfoKeyPrivilegedExecutables];
	NSString		*label = nil;
	NSError			*error = nil;
	for (NSString *key in [helpers allKeys]) {
		if ([key hasPrefix:@"com.littleknownsoftware.MPC.CopyMoveHelper"]) {
			label = [key copy];
			break;
		}
	}
	NSDictionary	*jobDict = (NSDictionary *)SMJobCopyDictionary(kSMDomainSystemLaunchd, (CFStringRef)label);
	if (jobDict) {
	
		AuthorizationItem	authItem	= { kSMRightModifySystemDaemons, 0, NULL, 0 };
		AuthorizationRights	authRights	= { 1, &authItem };
		AuthorizationFlags	flags		=	kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
		
		AuthorizationRef authRef = NULL;
		
		/* Obtain the right to install privileged helper tools (kSMRightBlessPrivilegedHelper). */
		OSStatus	status = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
		if (status != errAuthorizationSuccess) {
			NSLog(@"Failed to create AuthorizationRef. Error code: %d", (int)status);
			
		} else {
			/* This does all the work of verifying the helper tool against the application
			 * and vice-versa. Once verification has passed, the embedded launchd.plist
			 * is extracted and placed in /Library/LaunchDaemons and then loaded. The
			 * executable is placed in /Library/PrivilegedHelperTools.
			 */
			SMJobRemove(kSMDomainSystemLaunchd, (CFStringRef)label, authRef, false, (CFErrorRef *)&error);
		}
	}
	[jobDict release];
	
}



#pragma mark - Error Delegate Methods

- (NSString *)overrideErrorDomainForCode:(NSInteger)aCode {
	return @"MPIAppDelegateErrorDomain";
}

- (NSArray *)recoveryOptionsForError:(LKError *)error {
	return [error localizedRecoveryOptionList];
}

- (id)recoveryAttemptorForError:(LKError *)error {
	return self;
}

- (BOOL)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex {
	return recoveryOptionIndex==0?YES:NO;
}

@end
