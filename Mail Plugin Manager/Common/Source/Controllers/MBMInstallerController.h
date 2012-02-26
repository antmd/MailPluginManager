//
//  MBMInstallerController.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 20/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

#import "MBMManifestModel.h"
#import "MBMAnimatedListController.h"
#import "MBMConfirmationStep.h"

@interface MBMInstallerController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {
@private
	MBMManifestModel			*_manifestModel;
	MBMAnimatedListController	*_animatedListController;
	NSUInteger					_currentStep;
	
	NSImageView					*_backgroundImageView;
	NSView						*_confirmationStepsView;
	NSTextField					*_titleTextField;
	WebView						*_displayWebView;
	NSButton					*_previousStepButton;
	NSButton					*_actionButton;
	
	NSText						*_displayTextView;
	NSScrollView				*_displayTextScrollView;
	NSView						*_displayProgressView;
	NSScrollView				*_actionSummaryView;
	NSProgressIndicator			*_progressBar;
	NSTextField					*_displayProgressTextView;
	NSTextField					*_displayProgressLabel;
	NSTableView					*_actionSummaryTable;
	
	NSWindow					*_agreementDialog;

	id							_notificationObserver;
	NSString					*_displayErrorMessage;
}

@property	(nonatomic, retain)	MBMManifestModel			*manifestModel;
@property	(nonatomic, retain)	MBMAnimatedListController	*animatedListController;
@property	(nonatomic, assign)	NSUInteger					currentStep;

@property	(assign) IBOutlet NSImageView			*backgroundImageView;
@property	(assign) IBOutlet NSView				*confirmationStepsView;
@property	(assign) IBOutlet NSTextField			*titleTextField;
@property	(assign) IBOutlet WebView				*displayWebView;
@property	(assign) IBOutlet NSButton				*previousStepButton;
@property	(assign) IBOutlet NSButton				*actionButton;

@property	(assign) IBOutlet NSText				*displayTextView;
@property	(assign) IBOutlet NSScrollView			*displayTextScrollView;
@property	(assign) IBOutlet NSView				*displayProgressView;
@property	(assign) IBOutlet NSScrollView			*actionSummaryView;
@property	(assign) IBOutlet NSProgressIndicator	*progressBar;
@property	(assign) IBOutlet NSTextField			*displayProgressTextView;
@property	(assign) IBOutlet NSTextField			*displayProgressLabel;
@property	(assign) IBOutlet NSTableView			*actionSummaryTable;

@property	(assign) IBOutlet NSWindow				*agreementDialog;

- (id)initWithManifestModel:(MBMManifestModel *)aModel;

- (IBAction)closeAgreementDialog:(id)sender;
- (IBAction)moveToPreviousStep:(id)sender;
- (IBAction)moveToNextStep:(id)sender;
@end



