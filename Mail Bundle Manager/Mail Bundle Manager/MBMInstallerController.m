//
//  MBMInstallerController.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 20/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBMInstallerController.h"
#import <QuartzCore/QuartzCore.h>

@interface MBMInstallerController ()
- (void)updateCurrentConfigurationToStep:(NSInteger)toStep;
- (void)startInstall;
- (void)showContentView:(NSView *)aView;
@end

@implementation MBMInstallerController

@synthesize installationModel = _installationModel;
@synthesize animatedListController = _animatedListController;
@synthesize currentInstallStep = _currentInstallStep;

@synthesize backgroundImageView = _backgroundImageView;
@synthesize installStepsView = _installStepsView;
@synthesize titleTextField = _titleTextField;
@synthesize displayWebView = _displayWebView;
@synthesize displayProgressTextView = _displayProgressTextView;
@synthesize displayProgressLabel = _displayProgressLabel;
@synthesize installationSummaryTable = _installationSummaryTable;
@synthesize installationSummaryView = _displayInstallationPreview;
@synthesize previousStepButton = _previousStepButton;
@synthesize actionButton = _actionButton;
@synthesize displayTextView = _displayTextView;
@synthesize displayTextScrollView = _displayTextScrollView;
@synthesize displayProgressView = _displayProgressView;
@synthesize progressBar = _progressBar;


- (id)initWithInstallationModel:(MBMInstallationModel *)aModel {
    self = [super initWithWindowNibName:@"MBMInstallerWindow"];
    if (self) {
        // Initialization code here.
		_installationModel = [aModel retain];
		_currentInstallStep = kMBMInvalidStep;
    }
    
    return self;
}

- (IBAction)moveToNextStep:(id)sender {
	self.currentInstallStep = self.currentInstallStep + 1;
}

- (IBAction)moveToPreviousStep:(id)sender {
	self.currentInstallStep = self.currentInstallStep - 1;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	//	Create the install steps view
	self.animatedListController = [[[MBMAnimatedListController alloc] initWithContentList:self.installationModel.confirmationStepList inView:self.installStepsView] autorelease];
	
	//	Set the window title from the installation Model
	NSString	*localizedFormat = NSLocalizedString([[self window] title], @"");
	[[self window] setTitle:[NSString stringWithFormat:localizedFormat, self.installationModel.displayName]];
	
	//	Get the image for the background from the installationModel
	NSImage	*bgImage = [[[NSImage alloc] initWithContentsOfFile:self.installationModel.backgroundImagePath] autorelease];
	[self.backgroundImageView setImage:bgImage];
	
	//	Set up the title label to be animatable
	CATextLayer	*textLayer = [CATextLayer layer];
	[self.titleTextField setLayer:textLayer];
	[self.titleTextField setWantsLayer:YES];
	textLayer.fontSize = 16.0;
	CGColorRef	aColor = CGColorCreateGenericGray(0.000, 1.000);
	textLayer.foregroundColor = aColor;
	CGColorRelease(aColor);
	 
	 //	Localize the progress label
	[self.displayProgressLabel setStringValue:NSLocalizedString(@"Please wait while I install your plugin…", @"Title description for progress view during installation")];
	
	//	Localize the Go Back step as well
	[self.previousStepButton setTitle:NSLocalizedString(@"Go Back", @"Go Back button text for installation")];
	
	//	Set the current step
	self.currentInstallStep = 0;
	
}

- (void)setCurrentInstallStep:(NSInteger)aCurrentInstallStep {
	if (_currentInstallStep != aCurrentInstallStep) {
		
		//	Validate that we don't go beyond our range
		if ([self.installationModel.confirmationStepList count] <= (NSUInteger)aCurrentInstallStep) {
			//	Call our display the installation progress method and return
			[self startInstall];
			return;
		}
		
		[self updateCurrentConfigurationToStep:aCurrentInstallStep];
		_currentInstallStep = aCurrentInstallStep;
	}
}

- (void)updateCurrentConfigurationToStep:(NSInteger)toStep {
	
	NSArray			*configItems = self.installationModel.confirmationStepList;
	NSDictionary	*newStepDict = nil;
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
	BOOL		isConfirmed = [type isEqualToString:kMBMConfirmationTypeConfirm];
	BOOL		isContentHTML = [[newStepDict valueForKey:kMBMPathIsHTMLKey] boolValue];
	
	//	Load the contents 
	//	Is it html?
	if (isContentHTML) {
		[self showContentView:self.displayWebView];
		[self.displayWebView setMainFrameURL:contentPath];
	}
	else if (isConfirmed) {
		//	Set the datasource for the installation summary tableview
		[self.installationSummaryTable setDataSource:self];
		[self showContentView:self.installationSummaryView];
	}
	else {
		[self showContentView:self.displayTextScrollView];
		[self.displayTextView readRTFDFromFile:contentPath];
	}
	
	//	Title above the webview (its layer is used to animate it)
	((CATextLayer *)self.titleTextField.layer).string = [newStepDict valueForKey:kMBMConfirmationLocalizedTitleKey];
	
	//	Configure the two buttons at the bottom
	NSString	*actionTitle = NSLocalizedString(@"Continue", @"Continue button text for installation");
	if (isConfirmed) {
		actionTitle = NSLocalizedString(@"Install", @"Install button text for installation");
	}
	[self.actionButton setTitle:actionTitle];
	[self.previousStepButton setEnabled:(toStep != 0)];
	
	self.animatedListController.selectedStep = toStep;
}

- (void)startInstall {
	//	Show the progress view
	[self showContentView:self.displayProgressView];
	
	//	Disable the buttons
	[self.previousStepButton setEnabled:NO];
	[self.actionButton setEnabled:NO];
	
	//	Set the total value for the progress bar
	[self.progressBar setMaxValue:[self.installationModel.installationItemList count]+1];
	
	//	Set up some notification watches
	//id notificationWatcher = 
	[[NSNotificationCenter defaultCenter] addObserverForName:@"sjl" object:self.installationModel queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		//	Update the UI
		[self.displayProgressTextView setStringValue:[[note userInfo] valueForKey:@"install-description"]];
		[self.progressBar setDoubleValue:[[[note userInfo] valueForKey:@"progress-value"] doubleValue]];
	}];
	
	NSArray	*textList = [NSArray arrayWithObjects:@"A File.txt", @"My Big File.app", @"Bundle Manager.app", nil];

	CGFloat	delayTime = 0.0f;
	for (NSString *text in textList) {
		NSDictionary	*myDict = [NSDictionary dictionaryWithObjectsAndKeys:text, @"install-description", 
								   [NSNumber numberWithDouble:delayTime + 1.0f], @"progress-value",
								   nil];
		NSNotification	*dumNote = [NSNotification notificationWithName:@"sjl" object:self.installationModel userInfo:myDict];
		[[NSNotificationCenter defaultCenter] performSelector:@selector(postNotification:) withObject:dumNote afterDelay:delayTime];
		delayTime = delayTime + 1.0f;
	}
	
	
}

- (void)showContentView:(NSView *)aView {
	//	Handle the transition with a small animation
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:0.25f];
	//	After the animation, HIDE the view because otherwise they eat the events (thanks CALayer!)
	[[NSAnimationContext currentContext] setCompletionHandler:^(void) {
		[self.displayWebView setHidden:(aView != self.displayWebView)];
		[self.displayTextScrollView setHidden:(aView != self.displayTextScrollView)];
		[self.displayProgressView setHidden:(aView != self.displayProgressView)];
		[self.installationSummaryView setHidden:(aView != self.installationSummaryView)];
	}];
	[[self.displayWebView animator] setAlphaValue:(aView == self.displayWebView)?1.0f:0.0f];
	[[self.displayTextScrollView animator] setAlphaValue:(aView == self.displayTextScrollView)?1.0f:0.0f];
	[[self.displayProgressView animator] setAlphaValue:(aView == self.displayProgressView)?1.0f:0.0f];
	[[self.installationSummaryView animator] setAlphaValue:(aView == self.installationSummaryView)?1.0f:0.0f];
	[NSAnimationContext endGrouping];
}


#pragma mark - TableView DataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return 1;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSMutableAttributedString	*attrString = [[[NSMutableAttributedString alloc] initWithString:@"File To Install\nSome Description"] autorelease];
	[attrString setAttributes:[NSDictionary dictionaryWithObject:[NSColor redColor] forKey:NSForegroundColorAttributeName] range:NSMakeRange(0, 16)];
	return ([[tableColumn identifier] isEqualToString:@"icon"]?[NSImage imageNamed:@"InstallDocument"]:attrString);
}

@end
