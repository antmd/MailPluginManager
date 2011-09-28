//
//  MBTAppDelegate.m
//  MailBundleTool
//
//  Created by Scott Little on 28/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBTAppDelegate.h"

@implementation MBTAppDelegate

@synthesize window = _window;
@synthesize uninstalling = _uninstalling;
@synthesize updating = _updating;
@synthesize checkingCrashReports = _checkingCrashReports;
@synthesize validating = _validating;
@synthesize singleBundlePath = _singleBundlePath;
@synthesize manifestModel = _manifestModel;
@synthesize currentController = _currentController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	//	Read in any command line parameters and set instance variables accordingly
	NSArray	*arguments = [[NSProcessInfo processInfo] arguments];
	
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
	if ([kMBMCommandLineUninstallKey isEqualToString:firstArg]) {
		self.uninstalling = YES;
		self.singleBundlePath = secondArg;
	}
	else if ([kMBMCommandLineUpdateKey isEqualToString:firstArg]) {
		self.updating = YES;
		self.singleBundlePath = secondArg;
	}
	else if ([kMBMCommandLineCheckCrashReportsKey isEqualToString:firstArg]) {
		self.checkingCrashReports = YES;
		self.singleBundlePath = secondArg;
	}
	else if ([kMBMCommandLineUpdateAndCrashReportsKey isEqualToString:firstArg]) {
		self.updating = YES;
		self.checkingCrashReports = YES;
		self.singleBundlePath = secondArg;
	}
	else if ([kMBMCommandLineValidateAllKey isEqualToString:firstArg]) {
		self.validating = YES;
	}
}

- (void)validateAllBundles {
	
}

@end
