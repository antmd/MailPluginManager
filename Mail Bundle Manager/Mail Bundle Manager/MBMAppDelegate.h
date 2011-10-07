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

@interface MBMAppDelegate : NSObject <NSApplicationDelegate> {
}


@property (assign)	IBOutlet	NSWindow				*window;
@property (assign)	IBOutlet	NSCollectionViewItem	*collectionItem;

@property (retain)				NSViewController		*bundleViewController;

@property (assign)	BOOL		installing;
@property (assign)	BOOL		uninstalling;
@property (assign)	BOOL		managing;

@property (assign, readonly)	BOOL		isMailRunning;

@property (assign)				BOOL				runningFromInstallDisk;
@property (nonatomic, copy)		NSString			*executablePath;
@property (nonatomic, copy)		NSString			*singleBundlePath;
@property (nonatomic, retain)	MBMManifestModel	*manifestModel;

@property (nonatomic, retain)	NSWindowController	*currentController;

@property (nonatomic, retain)	NSArray				*mailBundleList;


- (void)showBundleManagerWindow;

- (void)ensureRunningBestVersion;

- (IBAction)restartMail:(id)sender;

@end
