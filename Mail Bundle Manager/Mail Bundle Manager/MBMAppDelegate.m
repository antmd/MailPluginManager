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


@implementation MBMAppDelegate

#pragma mark - Accessors & Memeory

@synthesize window = _window;
@synthesize bundleViewController = _bundleViewController;
@synthesize collectionItem = _collectionItem;

@synthesize installing = _installing;
@synthesize uninstalling = _uninstalling;
@synthesize managing = _managing;
@synthesize runningFromInstallDisk = _runningFromInstallDisk;
@synthesize executablePath = _executablePath;
@synthesize singleBundlePath = _singleBundlePath;
@synthesize manifestModel = _manifestModel;
@synthesize currentController = _currentController;
@synthesize mailBundleList = _mailBundleList;

- (void)dealloc {
	
	self.bundleViewController = nil;
	
	self.executablePath = nil;
	self.singleBundlePath = nil;
	self.manifestModel = nil;
	self.currentController = nil;
	self.mailBundleList = nil;
	
    [super dealloc];
}


#pragma mark - App Delegate

//	These are the methods in the order they are called...

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	//	Read in any command line parameters and set instance variables accordingly
	NSArray	*arguments = [[NSProcessInfo processInfo] arguments];
	
	//	Save the executable path
	self.executablePath = [arguments objectAtIndex:0];
	
	LKLog(@"Path is:%@", self.executablePath);
	
	//	Default to managing
	self.managing = YES;
	
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
	
	//	If the file is a valid type..
	if (IsValidPackageFile(filename)) {
		
		//	Load the model
		self.manifestModel = [[[MBMManifestModel alloc] initWithPackageAtPath:filename] autorelease];
		
		//	Determine the type (install/uninstall)
		NSString	*extension = [filename pathExtension];
		if ([extension isEqualToString:kMBMInstallerFileExtension]) {
			if (self.manifestModel.manifestType != kMBMManifestTypeInstallation) {
				LKPresentErrorCode(401);
				return NO;
			}
			self.installing = YES;
		}
		else if ([extension isEqualToString:kMBMUninstallerFileExtension]) {
			if (self.manifestModel.manifestType != kMBMManifestTypeUninstallation) {
				LKPresentErrorCode(402);
				return NO;
			}
			self.uninstalling = YES;
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
	// Insert code here to initialize your application
	
	//	Run the update handler for this application, if we are in any case except, running an install file that 
	//		doesn't want to install the bundle manager
	if (!(self.manifestModel && !self.manifestModel.shouldInstallManager)) {
		//	Run the Check Version Scenario
//		[self ensureRunningBestVersion];
	}
	
	//	Then determine the process to continue down
	if (self.installing) {
		
		MBMInstallerController	*controller = [[[MBMInstallerController alloc] initWithManifestModel:self.manifestModel] autorelease];
		[controller showWindow:self];
		self.currentController = controller;
		
//		//	Then quit
//		[NSApp terminate:self];
	}
	else if (self.uninstalling) {
		MBMInstallerController	*controller = [[[MBMInstallerController alloc] initWithManifestModel:self.manifestModel] autorelease];
		[controller showWindow:self];
		self.currentController = controller;
		
	}
	
	//	Then test to see if we should be showing the general management window
	if (self.managing) {
		[self showBundleManagerWindow];
	}
	
}


#pragma mark - Action Methods

- (void)showBundleManagerWindow {
	
	self.bundleViewController = [[[NSViewController alloc] initWithNibName:@"MBMBundleView" bundle:nil] autorelease];
	[self.bundleViewController configureForCollectionItem:self.collectionItem];

	self.mailBundleList = [MBMMailBundle allMailBundles];
	
	//	Add a notification watcher to handle uninstalls
	[[NSNotificationCenter defaultCenter] addObserverForName:kMBMMailBundleUninstalledNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		if ([[note object] isKindOfClass:[MBMMailBundle class]]) {
			self.mailBundleList = [MBMMailBundle allMailBundles];
		}
	}];

	[[self window] center];
	[[self window] makeKeyAndOrderFront:self];
}

- (void)restartMail {
	
}

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
		
		MBMMySparkleDelegate	*sparkleDelegate = [[[MBMMySparkleDelegate alloc] init] autorelease];
		sparkleDelegate.pathToReplace = otherInstaller;
		
		//	Get the version in Applications and compare that to this one
		NSString	*otherVersion = [[[NSBundle bundleWithPath:otherInstaller] infoDictionary] valueForKey:(NSString *)kCFBundleVersionKey];
		NSString	*myVersion = [[[NSBundle bundleForClass:[self class]] infoDictionary] valueForKey:(NSString *)kCFBundleVersionKey];
		
		//	If the currently running version (on installer), is less than the local version...
		if ([MBMMailBundle compareVersion:myVersion toVersion:otherVersion] == NSOrderedAscending) {
			//	Use Sparkle to check the local version.
		}
	}
}


@end
