//
//  MBMAppDelegate.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MBAppDelegate.h"
#import "MBMManifestModel.h"

@interface MBMAppDelegate : MBAppDelegate {
@private
	BOOL				_installing;
	BOOL				_uninstalling;
	BOOL				_managing;
	
	BOOL				_runningFromInstallDisk;
	NSString			*_executablePath;
	NSString			*_singleBundlePath;
	MBMManifestModel	*_manifestModel;
	
	NSNumber			*_savedEnableAutoChecks;
}


@property (assign)	BOOL		installing;
@property (assign)	BOOL		uninstalling;
@property (assign)	BOOL		managing;

@property (assign)				BOOL				runningFromInstallDisk;
@property (nonatomic, copy)		NSString			*executablePath;
@property (nonatomic, copy)		NSString			*singleBundlePath;
@property (nonatomic, retain)	MBMManifestModel	*manifestModel;

- (void)ensureRunningBestVersion;
@end
