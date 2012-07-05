//
//  MPMAppDelegate.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MPMAppDelegate.h"

#import "MPCMailBundle.h"
#import "MPCSystemInfo.h"
#import "MPCInstallerController.h"
#import "NSViewController+LKCollectionItemFix.h"

#define SU_AUTOMATIC_CHECKS_KEY	@"SUEnableAutomaticChecks"

typedef enum {
	MPMInstallerHasBadTypeCode = 401,
	MPMUninstallerHasBadTypeCode = 402,
	
	MPMEndAppDelegateCode
} MPMAppDelegateErrorCodes;


@interface MPMAppDelegate ()
@property	(nonatomic, retain)	NSNumber		*savedEnableAutoChecks;
@end

@implementation MPMAppDelegate

#pragma mark - Accessors & Memeory

@synthesize installing = _installing;
@synthesize uninstalling = _uninstalling;
@synthesize managing = _managing;
@synthesize runningFromInstallDisk = _runningFromInstallDisk;
@synthesize executablePath = _executablePath;
@synthesize singleBundlePath = _singleBundlePath;
@synthesize manifestModel = _manifestModel;
@synthesize savedEnableAutoChecks = _savedEnableAutoChecks;



- (void)dealloc {
	
	self.executablePath = nil;
	self.singleBundlePath = nil;
	self.manifestModel = nil;
	self.savedEnableAutoChecks = nil;
	
    [super dealloc];
}


#pragma mark - Accessors

- (BOOL)collectInstalls {
	return YES;
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
		[self showCollectionWindowForBundles:[MPCMailBundle allMailBundlesLoadInfo]];
		
		//	Add a notification watcher to handle uninstalls
		self.bundleUninstallObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMPCMailBundleUninstalledNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
			if ([[note object] isKindOfClass:[MPCMailBundle class]]) {
				self.mailBundleList = [MPCMailBundle allMailBundlesLoadInfo];
				[self adjustWindowSizeForBundleList:self.mailBundleList animate:YES];
			}
		}];
	}
	else {	//	Either install or uninstall uses the same process
		MPCInstallerController	*controller = [[[MPCInstallerController alloc] initWithManifestModel:self.manifestModel] autorelease];
		[controller showWindow:self];
		self.currentController = controller;
	}
	
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	if (self.installing || self.uninstalling) {
		[self changePluginManagerDefaultValue:self.savedEnableAutoChecks forKey:SU_AUTOMATIC_CHECKS_KEY];
	}
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
	
	//	If the file is a valid type..
	if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath:filename]) {
		
		//	Load the model
		self.manifestModel = [[[MPCManifestModel alloc] initWithPackageAtPath:filename] autorelease];
		
		//	Determine the type (install/uninstall)
		NSString	*extension = [filename pathExtension];
		if ([extension isEqualToString:kMPCInstallerFileExtension]) {
			if (self.manifestModel.manifestType != kMPCManifestTypeInstallation) {
				LKPresentErrorCode(MPMInstallerHasBadTypeCode);
				[self quittingNowIsReasonable];
				return NO;
			}
			self.installing = YES;
			self.managing = NO;
		}
		else if ([extension isEqualToString:kMPCUninstallerFileExtension]) {
			if (self.manifestModel.manifestType != kMPCManifestTypeUninstallation) {
				LKPresentErrorCode(MPMUninstallerHasBadTypeCode);
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

	if (self.installing || self.uninstalling) {
		//	May need to save the state of this value and restore afterward
		self.savedEnableAutoChecks = [self changePluginManagerDefaultValue:[NSNumber numberWithBool:NO] forKey:SU_AUTOMATIC_CHECKS_KEY];
	}

	
	return NO;
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
		if ([MPCMailBundle compareVersion:myVersion toVersion:otherVersion] == NSOrderedAscending) {
			//	Use Sparkle to check the local version.
		}
	}
}


#pragma mark - Sparkle Delegate Methods

- (NSArray *)feedParametersForUpdater:(SUUpdater *)updater sendingSystemProfile:(BOOL)sendingProfile {
	if (sendingProfile) {
		NSMutableArray	*params = [NSMutableArray arrayWithCapacity:4];
		[params addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"mv", @"key", [MPCSystemInfo mailVersion], @"value", @"Mail Version", @"displayKey", [MPCSystemInfo mailVersion], @"displayValue", nil]];
		[params addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"msv", @"key", [MPCSystemInfo mailShortVersion], @"value", @"Mail Short Version", @"displayKey", [MPCSystemInfo mailShortVersion], @"displayValue", nil]];
		[params addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"mfv", @"key", [MPCSystemInfo messageVersion], @"value", @"Message Framework Version", @"displayKey", [MPCSystemInfo messageVersion], @"displayValue", nil]];
		[params addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"mfsv", @"key", [MPCSystemInfo messageShortVersion], @"value", @"Message Framework Short Version", @"displayKey", [MPCSystemInfo messageShortVersion], @"displayValue", nil]];
		return params;
	}
	return nil;
}

- (void)updaterWillRelaunchApplication:(SUUpdater *)updater {
	[self quittingNowIsReasonable];
	[self releaseActivityQueue];
	[self releaseFinalizeQueue];
}


#pragma mark - Error Delegate Methods

- (NSString *)overrideErrorDomainForCode:(NSInteger)aCode {
	return @"MPMAppDelegateErrorDomain";
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
