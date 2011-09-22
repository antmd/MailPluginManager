//
//  MBMInstallerController.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 20/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

#import "MBMInstallationModel.h"
#import "MBMAnimatedListController.h"

@interface MBMInstallerController : NSWindowController {
	NSScrollView *_displayTextScrollView;
}

@property	(nonatomic, retain)	MBMInstallationModel		*installationModel;
@property	(nonatomic, retain)	MBMAnimatedListController	*installListController;
@property	(nonatomic, assign)	NSInteger					currentInstallStep;

@property	(assign) IBOutlet NSImageView	*backgroundImageView;
@property	(assign) IBOutlet NSView		*installStepsView;
@property	(assign) IBOutlet NSTextField	*titleTextField;
@property	(assign) IBOutlet WebView		*displayWebView;
@property	(assign) IBOutlet NSButton		*previousStepButton;
@property	(assign) IBOutlet NSButton		*actionButton;

@property	(assign) IBOutlet NSText		*displayTextView;
@property	(assign) IBOutlet NSScrollView	*displayTextScrollView;

- (id)initWithInstallationModel:(MBMInstallationModel *)aModel;
@end
