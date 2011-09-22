//
//  MBMInstallerController.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 20/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBMInstallerController.h"

@interface MBMInstallerController ()
- (void)updateCurrentConfigurationFromStep:(NSInteger)fromStep toStep:(NSInteger)toStep;
@end

@implementation MBMInstallerController

@synthesize installationModel = _installationModel;
@synthesize installListController = _installListController;
@synthesize currentInstallStep = _currentInstallStep;

@synthesize backgroundImageView = _backgroundImageView;
@synthesize installStepsView = _installStepsView;
@synthesize titleTextField = _titleTextField;
@synthesize displayWebView = _displayWebView;
@synthesize previousStepButton = _previousStepButton;
@synthesize actionButton = _actionButton;
@synthesize displayTextView = _displayTextView;
@synthesize displayTextScrollView = _displayTextScrollView;


- (id)initWithInstallationModel:(MBMInstallationModel *)aModel {
    self = [super initWithWindowNibName:@"MBMInstallerWindow"];
    if (self) {
        // Initialization code here.
		_installationModel = [aModel retain];
		_currentInstallStep = kMBMInvalidStep;
    }
    
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	//	Create the install steps view
	self.installListController = [[[MBMAnimatedListController alloc] initWithContentList:self.installationModel.confirmationStepList inView:self.installStepsView] autorelease];
	
	//	Set the current step
	self.currentInstallStep = 0;
	
	//	Set the window title from the installation Model
	NSString	*localizedFormat = NSLocalizedString([[self window] title], @"");
	[[self window] setTitle:[NSString stringWithFormat:localizedFormat, self.installationModel.displayName]];
	
	//	Get the image for the background from the installationModel
	NSImage	*bgImage = [[[NSImage alloc] initWithContentsOfFile:self.installationModel.backgroundImagePath] autorelease];
	[self.backgroundImageView setImage:bgImage];
	
	//	Localize the Go Back step as well
	[self.previousStepButton setTitle:NSLocalizedString(@"Go Back", @"Go Back button text for installation")];
	
}

- (void)setCurrentInstallStep:(NSInteger)aCurrentInstallStep {
	if (_currentInstallStep != aCurrentInstallStep) {
		[self updateCurrentConfigurationFromStep:_currentInstallStep toStep:aCurrentInstallStep];
		_currentInstallStep = aCurrentInstallStep;
	}
}

- (void)updateCurrentConfigurationFromStep:(NSInteger)fromStep toStep:(NSInteger)toStep {
	
	NSArray			*configItems = self.installationModel.confirmationStepList;
	NSDictionary	*oldStepDict = nil;
	NSDictionary	*newStepDict = nil;
	if ((fromStep != kMBMInvalidStep) && ([configItems count] > (NSUInteger)fromStep)) {
		oldStepDict = [configItems objectAtIndex:fromStep];
	}
	if ([configItems count] > (NSUInteger)toStep) {
		newStepDict = [configItems objectAtIndex:toStep];
	}
	
	//	Ensure that we have something to do
	if (newStepDict == nil) {
		return;
	}
	
	//	Get some values out
	NSString	*type = [newStepDict valueForKey:kMBMConfirmationTypeKey];
	NSString	*contentPath = [newStepDict valueForKey:kMBMPathKey];
	BOOL		isContentHTML = [[newStepDict valueForKey:kMBMPathIsHTMLKey] boolValue];
	
	//	Load the contents 
	//	Is it html?
	if (isContentHTML) {
		[self.displayWebView setHidden:NO];
		[self.displayTextScrollView setHidden:YES];
		[self.displayWebView setMainFrameURL:contentPath];
	}
	else {
		[self.displayTextScrollView setHidden:NO];
		[self.displayWebView setHidden:YES];
		[self.displayTextView readRTFDFromFile:contentPath];
	}
	
	//	Title above the webview
	[self.titleTextField setStringValue:[newStepDict valueForKey:kMBMConfirmationLocalizedTitleKey]];
	
	//	Configure the two buttons at the bottom
	NSString	*actionTitle = NSLocalizedString(@"Continue", @"Continue button text for installation");
	if ([type isEqualToString:kMBMConfirmationTypeConfirm]) {
		actionTitle = NSLocalizedString(@"Install", @"Install button text for installation");
	}
	[self.actionButton setTitle:actionTitle];
	[self.previousStepButton setEnabled:(toStep != 0)];
	
	self.installListController.selectedStep = toStep;
}

@end
