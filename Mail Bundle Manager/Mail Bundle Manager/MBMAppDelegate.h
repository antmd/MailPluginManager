//
//  MBMAppDelegate.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MBMManifestModel.h"
#import "MBMMySparkleDelegate.h"

@interface MBMAppDelegate : NSObject <NSApplicationDelegate>

@property (assign)	IBOutlet	NSWindow	*window;

@property (assign)	BOOL		installing;
@property (assign)	BOOL		uninstalling;
@property (assign)	BOOL		updating;
@property (assign)	BOOL		checkingCrashReports;
@property (assign)	BOOL		validating;
@property (assign)	BOOL		managing;

@property (assign)				BOOL				runningFromInstallDisk;
@property (nonatomic, copy)		NSString			*executablePath;
@property (nonatomic, copy)		NSString			*singleBundlePath;
@property (nonatomic, retain)	MBMManifestModel	*manifestModel;

@property (nonatomic, retain)	NSWindowController	*currentController;

- (void)validateAllBundles;
- (void)showBundleManagerWindow;

- (void)restartMail;

- (void)ensureRunningBestVersion;

+ (BOOL)isMailRunning;
+ (BOOL)quitMail;

@end
