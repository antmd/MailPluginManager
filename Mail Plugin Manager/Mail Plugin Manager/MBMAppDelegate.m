//
//  MBMAppDelegate.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MBMAppDelegate.h"

#import "MBMMailBundle.h"
#import "MBMInstallerController.h"
#import "NSViewController+LKCollectionItemFix.h"


typedef enum {
	MBMInstallerHasBadTypeCode = 401,
	MBMUninstallerHasBadTypeCode = 402,
	
	MBMEndAppDelegateCode
} MBMAppDelegateErrorCodes;


@implementation MBMAppDelegate

#pragma mark - Accessors & Memeory

@synthesize installing = _installing;
@synthesize uninstalling = _uninstalling;
@synthesize managing = _managing;
@synthesize runningFromInstallDisk = _runningFromInstallDisk;
@synthesize executablePath = _executablePath;
@synthesize singleBundlePath = _singleBundlePath;
@synthesize manifestModel = _manifestModel;


- (void)dealloc {
	
	self.executablePath = nil;
	self.singleBundlePath = nil;
	self.manifestModel = nil;
	
    [super dealloc];
}


#pragma mark - App Delegate

//	These are the methods in the order they are called...

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	//	Read in any command line parameters and set instance variables accordingly
	NSArray	*arguments = [[NSProcessInfo processInfo] arguments];
	
	//	Save the executable path
	self.executablePath = [arguments objectAtIndex:0];
	
	//	Default to managing
	self.managing = YES;
	
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
	
	//	If the file is a valid type..
	if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath:filename]) {
		
		//	Load the model
		self.manifestModel = [[[MBMManifestModel alloc] initWithPackageAtPath:filename] autorelease];
		
		//	Determine the type (install/uninstall)
		NSString	*extension = [filename pathExtension];
		if ([extension isEqualToString:kMBMInstallerFileExtension]) {
			if (self.manifestModel.manifestType != kMBMManifestTypeInstallation) {
				LKPresentErrorCode(MBMInstallerHasBadTypeCode);
				[self quittingNowIsReasonable];
				return NO;
			}
			self.installing = YES;
			self.managing = NO;
		}
		else if ([extension isEqualToString:kMBMUninstallerFileExtension]) {
			if (self.manifestModel.manifestType != kMBMManifestTypeUninstallation) {
				LKPresentErrorCode(MBMUninstallerHasBadTypeCode);
				[self quittingNowIsReasonable];
				return NO;
			}
			self.uninstalling = YES;
			self.managing = NO;
		}
		else {
			return NO;
		}

		//	Determine if the install is running from the installation volume
		NSArray		*removableMedia = [[NSWorkspace sharedWorkspace] mountedRemovableMedia];
		NSString	*installVolumePath = nil;
		for (NSString *aVolume in removableMedia) {
			if ([filename hasPrefix:aVolume]) {
				installVolumePath = aVolume;
				break;
			}
		}
		
		//	If we found the volume, see if this app is running from there too.
		if ((installVolumePath) && ([self.executablePath hasPrefix:installVolumePath])) {
			self.runningFromInstallDisk = YES;
		}
	}
	
	return NO;
}
	
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	//	Call our super to setup stuff
	[super applicationDidFinishLaunching:aNotification];
	
	//	Run the update handler for this application, if we are in any case except, running an install file that 
	//		doesn't want to install the bundle manager
	if (!(self.manifestModel && !self.manifestModel.shouldInstallManager)) {
		//	Run the Check Version Scenario
//		[self ensureRunningBestVersion];
	}
	
	//	Then test to see if we should be showing the general management window
	if (self.managing) {
		[self showCollectionWindowForBundles:[MBMMailBundle allMailBundlesLoadInfo]];
		
		//	Add a notification watcher to handle uninstalls
		self.bundleUninstallObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMBMMailBundleUninstalledNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
			if ([[note object] isKindOfClass:[MBMMailBundle class]]) {
				self.mailBundleList = [MBMMailBundle allMailBundlesLoadInfo];
				[self adjustWindowSizeForBundleList:self.mailBundleList animate:YES];
			}
		}];
	}
	else {	//	Either install or uninstall uses the same process
		MBMInstallerController	*controller = [[[MBMInstallerController alloc] initWithManifestModel:self.manifestModel] autorelease];
		[controller showWindow:self];
		self.currentController = controller;
	}
	
}


#pragma mark - Action Methods

- (IBAction)showURL:(id)sender {
	if ([sender respondsToSelector:@selector(toolTip)]) {
		NSURL	*aURL = [NSURL URLWithString:[sender toolTip]];
		if (aURL) {
			[[NSWorkspace sharedWorkspace] openURL:aURL];
		}
	}
}

#pragma mark - This App Update Methods

- (void)ensureRunningBestVersion {
	
	//	If we are running from the install disk, then check for another version on local volume
	if (self.runningFromInstallDisk) {
		NSString	*otherInstaller = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:[[NSBundle bundleForClass:[self class]] bundleIdentifier]];
		
		//	Get the version in Applications and compare that to this one
		NSString	*otherVersion = [[[NSBundle bundleWithPath:otherInstaller] infoDictionary] valueForKey:(NSString *)kCFBundleVersionKey];
		NSString	*myVersion = [[[NSBundle bundleForClass:[self class]] infoDictionary] valueForKey:(NSString *)kCFBundleVersionKey];
		
		//	If the currently running version (on installer), is less than the local version...
		if ([MBMMailBundle compareVersion:myVersion toVersion:otherVersion] == NSOrderedAscending) {
			//	Use Sparkle to check the local version.
		}
	}
}


#pragma mark - Error Delegate Methods

- (NSString *)overrideErrorDomainForCode:(NSInteger)aCode {
	return @"MBMAppDelegateErrorDomain";
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
