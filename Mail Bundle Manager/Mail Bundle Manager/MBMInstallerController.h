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

@interface MBMInstallerController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {
	NSScrollView *_displayTextScrollView;
	NSView *_displayProgressView;
	NSProgressIndicator *_progressBar;
	NSTextField *_displayProgressTextView;
	NSTextField *_displayProgressLabel;
	NSTableView *_installationSummaryTable;
	NSScrollView *_displayInstallationPreview;
}

@property	(nonatomic, retain)	MBMInstallationModel		*installationModel;
@property	(nonatomic, retain)	MBMAnimatedListController	*animatedListController;
@property	(nonatomic, assign)	NSUInteger					currentStep;

@property	(assign) IBOutlet NSImageView	*backgroundImageView;
@property	(assign) IBOutlet NSView		*installStepsView;
@property	(assign) IBOutlet NSTextField	*titleTextField;
@property	(assign) IBOutlet WebView		*displayWebView;
@property	(assign) IBOutlet NSButton		*previousStepButton;
@property	(assign) IBOutlet NSButton		*actionButton;

@property	(assign) IBOutlet NSText				*displayTextView;
@property	(assign) IBOutlet NSScrollView			*displayTextScrollView;
@property	(assign) IBOutlet NSView				*displayProgressView;
@property	(assign) IBOutlet NSScrollView			*installationSummaryView;
@property	(assign) IBOutlet NSProgressIndicator	*progressBar;
@property	(assign) IBOutlet NSTextField			*displayProgressTextView;
@property	(assign) IBOutlet NSTextField			*displayProgressLabel;
@property	(assign) IBOutlet NSTableView			*installationSummaryTable;

@property	(assign) IBOutlet NSWindow				*agreementDialog;

- (id)initWithInstallationModel:(MBMInstallationModel *)aModel;

- (IBAction)closeAgreementDialog:(id)sender;
- (IBAction)moveToPreviousStep:(id)sender;
- (IBAction)moveToNextStep:(id)sender;
@end
