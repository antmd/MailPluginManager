//
//  MBMInstallerController.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 20/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBMInstallerController.h"

@implementation MBMInstallerController

@synthesize installationModel = _installationModel;
@synthesize backgroundImageView = _backgroundImageView;
@synthesize installStepsView = _installStepsView;
@synthesize titleTextField = _titleTextField;
@synthesize displayWebView = _displayWebView;
@synthesize previousStepButton = _previousStepButton;
@synthesize actionButton = _actionButton;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
