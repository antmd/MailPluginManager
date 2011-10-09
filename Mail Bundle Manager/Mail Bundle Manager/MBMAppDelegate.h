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
#import "MBMMySparkleDelegate.h"

@interface MBMAppDelegate : MBAppDelegate {
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
