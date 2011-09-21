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
@synthesize installListController = _installListController;
@synthesize backgroundImageView = _backgroundImageView;
@synthesize installStepsView = _installStepsView;
@synthesize titleTextField = _titleTextField;
@synthesize displayWebView = _displayWebView;
@synthesize previousStepButton = _previousStepButton;
@synthesize actionButton = _actionButton;


- (id)initWithInstallationModel:(MBMInstallationModel *)aModel {
    self = [super initWithWindowNibName:@"MBMInstallerWindow"];
    if (self) {
        // Initialization code here.
		_installationModel = [aModel retain];
    }
    
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	//	Create the install steps view and set the default step
	self.installListController = [[[MBMAnimatedListController alloc] initWithContentList:self.installationModel.confirmationStepList inView:self.installStepsView] autorelease];
	self.installListController.selectedStep = 0;
	
	//	Get the image for the background from the installationModel
	
	//	Update the window based on the step
	[self updateCurrentConfiguration];
}

- (void)updateCurrentConfiguration {
	
}

@end
