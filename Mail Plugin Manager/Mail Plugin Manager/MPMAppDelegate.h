//
//  MBMAppDelegate.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MPCAppDelegate.h"
#import "MPCManifestModel.h"

@interface MPMAppDelegate : MPCAppDelegate {
@private
	BOOL				_installing;
	BOOL				_uninstalling;
	BOOL				_managing;
	
	BOOL				_runningFromInstallDisk;
	NSString			*_executablePath;
	NSString			*_singleBundlePath;
	MPCManifestModel	*_manifestModel;
	
	NSNumber			*_savedEnableAutoChecks;
}


@property (assign)	BOOL		installing;
@property (assign)	BOOL		uninstalling;
@property (assign)	BOOL		managing;

@property (assign)				BOOL				runningFromInstallDisk;
@property (nonatomic, copy)		NSString			*executablePath;
@property (nonatomic, copy)		NSString			*singleBundlePath;
@property (nonatomic, retain)	MPCManifestModel	*manifestModel;

- (void)ensureRunningBestVersion;
@end
