//
//  MBTAppDelegate.h
//  MailBundleTool
//
//  Created by Scott Little on 28/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MBMManifestModel.h"

@interface MBTAppDelegate : NSObject <NSApplicationDelegate> {
}

@property (assign) IBOutlet NSWindow *window;

@property (assign)	BOOL		uninstalling;
@property (assign)	BOOL		updating;
@property (assign)	BOOL		checkingCrashReports;
@property (assign)	BOOL		validating;

@property (nonatomic, copy)		NSString			*singleBundlePath;
@property (nonatomic, retain)	MBMManifestModel	*manifestModel;
@property (nonatomic, retain)	NSWindowController	*currentController;

- (void)validateAllBundles;

@end
