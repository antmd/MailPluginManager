//
//  MBMAppDelegate.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MBMAppDelegate.h"

#import "MBMMailBundle.h"

@interface MBMAppDelegate ()
+ (BOOL)validInstallFile:(NSString *)installFilePath;
@end

@implementation MBMAppDelegate

@synthesize window = _window;
@synthesize installing = _installing;
@synthesize uninstalling = _uninstalling;
@synthesize updating = _updating;
@synthesize validating = _validating;
@synthesize runningFromInstallDisk = _runningFromInstallDisk;
@synthesize executablePath = _executablePath;
@synthesize singleBundlePath = _singleBundlePath;
@synthesize installationModel = _installationModel;

- (void)dealloc {
	[_executablePath release];
	_executablePath = nil;
	[_singleBundlePath release];
	_singleBundlePath = nil;
	[_installationModel release];
	_installationModel = nil;
    [super dealloc];
}


//	These are the methods in the order they are called...

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	//	Read in any command line parameters and set instance variables accordingly
	NSArray	*arguments = [[NSProcessInfo processInfo] arguments];
	
	//	Save the executable path
	self.executablePath = [arguments objectAtIndex:0];
	
	LKLog(@"Path is:%@", self.executablePath);
	
	//	See if there are more arguments
	NSString	*firstArg = nil;
	NSString	*secondArg = nil;
	
	if ([arguments count] > 1) {
		firstArg = [arguments objectAtIndex:1];
	}
	if ([arguments count] > 2) {
		secondArg = [arguments objectAtIndex:2];
	}
	
	//	Look at the first argument (after executable name) and test for one of our types
	if ([kMBMCommandLineInstallKey isEqualToString:firstArg]) {
		self.installing = YES;
	}
	else if ([kMBMCommandLineUninstallKey isEqualToString:firstArg]) {
		self.uninstalling = YES;
		self.singleBundlePath = secondArg;
	}
	else if ([kMBMCommandLineUpdateKey isEqualToString:firstArg]) {
		self.updating = YES;
		self.singleBundlePath = secondArg;
	}
	else if ([kMBMCommandLineValidateAllKey isEqualToString:firstArg]) {
		self.validating = YES;
	}
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
	
	//	If the file is a valid type..
	if ([[self class] validInstallFile:filename]) {
		self.installationModel = [[[MBMInstallationModel alloc] initWithInstallPackageAtPath:filename] autorelease];
		self.installing = YES;

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
	if (!(self.installationModel && !self.installationModel.shouldInstallManager)) {
		//	Run the Check Version Scenario
//		[self ensureRunningBestVersion];
	}
	
	//	Then determine the process to continue down
	if (self.installing) {
		//	Ask the model to install everything
		[self.installationModel installAll];
		//	Then quit
		[NSApp terminate:self];
	}
	else if (self.uninstalling) {
		//	Get the mail bundle
		MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:self.singleBundlePath];
		//	Tell it to update itself
		[mailBundle uninstall];
	}
	else if (self.updating) {
		//	Get the mail bundle
		MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:self.singleBundlePath];
		//	Tell it to update itself
		[mailBundle updateIfNecessary];
	}
	else if (self.validating) {
		[self validateAllBundles];
	}
	else {
		[self showBundleManagerWindow];
	}
	
	NSLog(@"didFinish called");
}


#pragma mark - Entry Methods

- (void)validateAllBundles {
	
	/*
	 
	 Two types of BundleSparkleDelegates
	 
	 1. One-off delegate - used for doing an update that was explicitly asked for
	 2. Delayed delegate - used when looking to validate all plugins
		this one should do a lookup of the update data and see if there is 
			one to do and queue the information for later processing.
	 
	 Another Update type that is used when the plugin doesn't support Sparkle.
		This simply tries to determine a website to direct the user to
			or is based on a database as well.
	
	*/
	
}

- (void)showBundleManagerWindow {
	
}

- (void)restartMail {
	
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


#pragma mark - Class Methods

+ (BOOL)isMailRunning {
	BOOL mailIsRunning = NO;
	NSArray *launchedApps = [[NSWorkspace sharedWorkspace] launchedApplications];
	for (NSDictionary *app in launchedApps) {
		if ([[app objectForKey:@"NSApplicationBundleIdentifier"] isEqualToString:kMBMMailBundleIdentifier])
			mailIsRunning = YES;
	}
	return mailIsRunning;
}


+ (BOOL)quitMail {
	
	//	If it's not running, just return success
	if (![self isMailRunning]) {
		return YES;
	}
	
	NSString		*bundleID = kMBMMailBundleIdentifier;
	OSStatus		result = noErr;
	AEAddressDesc	target = {};
	AEInitializeDesc(&target);
	
	const char	*bundleIDString = [bundleID UTF8String];
	
	result = AECreateDesc(typeApplicationBundleID, bundleIDString, strlen(bundleIDString), &target);
	if (result == noErr) {
		AppleEvent	event = {};
		AEInitializeDesc(&event);
		
		result = AECreateAppleEvent( kCoreEventClass, kAEQuitApplication, &target, kAutoGenerateReturnID, kAnyTransactionID, &event );
		if (result == noErr) {
			AppleEvent	reply = {};
			AEInitializeDesc(&reply);
			
			// Send the Apple event and Wait 10 seconds for it to quit  (before timing out)	
			// if the wait is not here Bundle Manager quits and before Host Application does and the relaunch will relaunch an open application.
			// then the Apple event will be processed and quit the open application and so it will seem that the application will not relaunch.
			
			result = AESendMessage(&event, &reply, kAEWaitReply, 600);
			
			AEDisposeDesc(&event);
		}
		
		AEDisposeDesc(&target);
	}
	
	return (result == noErr);
}

+ (BOOL)validInstallFile:(NSString *)installFilePath {
	
	//	The extension should be our extension
	if (![[installFilePath pathExtension] isEqualToString:kMBMInstallerFileExtension]) {
		ALog(@"Installation file (%@) does not have a proper file extension (%@).", installFilePath, kMBMInstallerFileExtension);
		return NO;
	}
	
	//	Also ensure that the path is a folder and exists
	BOOL	isFolder = NO;
	if (![[NSFileManager defaultManager] fileExistsAtPath:installFilePath isDirectory:&isFolder] || !isFolder) {
		ALog(@"Installation file (%@) either doesn't exist or is not a folder.", installFilePath);
		return NO;
	}

	//	Ensure that the filename is a package
	if (![[NSWorkspace sharedWorkspace] isFilePackageAtPath:installFilePath]) {
		ALog(@"Installation file (%@) is not a package.", installFilePath);
		return NO;
	}

	return YES;
}


@end
