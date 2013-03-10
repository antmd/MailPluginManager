//
//  MPIAppDelegate.m
//  Plugin Installer
//
//  Created by Scott Little on 9/3/13.
//  Copyright (c) 2013 Little Known Software. All rights reserved.
//

#import "MPIAppDelegate.h"
#import "MPCInstallerController.h"

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
