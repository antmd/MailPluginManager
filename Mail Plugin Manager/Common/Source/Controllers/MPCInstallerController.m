//
//  MPCInstallerController.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 20/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MPCInstallerController.h"
#import <QuartzCore/QuartzCore.h>

#import "MPCMailBundle.h"
#import "MPCSystemInfo.h"
#import "MPCUUIDList.h"
#import "LKError.h"
#import "NSFileManager+LKAdditions.h"

typedef enum {
	MPCMinOSInsufficientCode = 101,
	MPCMaxOSInsufficientCode = 102,
	MPCMinMailInsufficientCode = 103,
	
	MPCGenericFileCode = 200,
	MPCInvalidSourcePath = 201,
	MPCDifferentDestinationBundleManager = 202,
	MPCTryingToInstallOverFile = 203,
	MPCUnableToMoveFileToTrash = 204,
	
	MPCCantCreateFolder = 211,
	MPCCopyFailed = 212,
	
	MPCPluginDoesNotWorkWithMailVersion = 221,
	
	MPCUnknownInstallCode
} MPCInstallErrorCodes;



@interface MPCInstallerController ()
@property	(nonatomic, assign)				id					notificationObserver;
@property	(nonatomic, retain, readonly)	MPCConfirmationStep	*currentInstallationStep;
@property	(nonatomic, retain)				NSString			*displayErrorMessage;

- (void)updateCurrentConfigurationToStep:(NSUInteger)toStep;
- (void)showContentView:(NSView *)aView;
- (void)startActions;

- (BOOL)processAllItems;
- (BOOL)processItems;
- (BOOL)processBundleManager;
- (BOOL)validateRequirements;
- (BOOL)installBundleManager;
- (BOOL)installItem:(MPCActionItem *)anItem;
- (BOOL)removeBundleManagerIfReasonable;
- (BOOL)removeItem:(MPCActionItem *)anItem;
- (BOOL)configureMail;

- (BOOL)checkForLicenseRequirement;
@end

@implementation MPCInstallerController

#pragma mark - Accessors

@synthesize notificationObserver = _notificationObserver;

@synthesize manifestModel = _manifestModel;
@synthesize animatedListController = _animatedListController;
@synthesize currentStep = _currentStep;
@synthesize displayErrorMessage = _displayErrorMessage;

@synthesize backgroundImageView = _backgroundImageView;
@synthesize confirmationStepsView = _confirmationStepsView;
@synthesize titleTextField = _titleTextField;
@synthesize displayWebView = _displayWebView;
@synthesize displayProgressTextView = _displayProgressTextView;
@synthesize displayProgressLabel = _displayProgressLabel;
@synthesize actionSummaryTable = _actionSummaryTable;
@synthesize actionSummaryView = _actionSummaryView;
@synthesize previousStepButton = _previousStepButton;
@synthesize actionButton = _actionButton;
@synthesize displayTextView = _displayTextView;
@synthesize displayTextScrollView = _displayTextScrollView;
@synthesize displayProgressView = _displayProgressView;
@synthesize progressBar = _progressBar;
@synthesize agreementDialog = _agreementDialog;

- (MPCConfirmationStep *)currentInstallationStep {
	if (self.currentStep == kMPCInvalidStep) {
		return nil;
	}
	return [self.manifestModel.confirmationStepList objectAtIndex:self.currentStep];
}

#pragma mark - Memory and Window Management

- (id)initWithManifestModel:(MPCManifestModel *)aModel {
    self = [super initWithWindowNibName:@"MPCInstallerWindow"];
    if (self) {
        // Initialization code here.
		_manifestModel = [aModel retain];
		_currentStep = kMPCInvalidStep;
    }
    
    return self;
}

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self.notificationObserver];
	self.notificationObserver = nil;
	self.manifestModel = nil;
	self.animatedListController = nil;
	self.displayErrorMessage = nil;
	
	[super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	//	Create the install steps view
	self.animatedListController = [[[MPCAnimatedListController alloc] initWithContentList:self.manifestModel.confirmationStepList inView:self.confirmationStepsView] autorelease];

	//	Initialize some text and get the localization proper for the type (install/uninstall)
	NSString	*localizedFormat = NSLocalizedString(@"Install %@", @"");
	NSString	*progressText = NSLocalizedString(@"Please wait while I install the plugin…", @"Title description for progress view during installation");
	if (self.manifestModel.manifestType == kMPCManifestTypeUninstallation) {
		localizedFormat = NSLocalizedString(@"Uninstall %@", @"");
		progressText = NSLocalizedString(@"Please wait while I remove your plugin…", @"Title description for progress view during UNinstallation");
	}
	
	//	Set the window title from the installation Model
	[[self window] setTitle:[NSString stringWithFormat:localizedFormat, self.manifestModel.displayName]];
	[[self window] center];
	
	//	Get the image for the background from the manifestModel
	NSImage	*bgImage = [[[NSImage alloc] initWithContentsOfFile:self.manifestModel.backgroundImagePath] autorelease];
	[self.backgroundImageView setImage:bgImage];
	
	//	Set up the title label to be animatable
	CATextLayer	*textLayer = [CATextLayer layer];
	[self.titleTextField setLayer:textLayer];
	[self.titleTextField setWantsLayer:YES];
	textLayer.fontSize = 16.0;
	CGColorRef	aColor = CGColorCreateGenericGray(0.000, 1.000);	//	Black
	textLayer.foregroundColor = aColor;
	CGColorRelease(aColor);
	 
	 //	Localize the progress label
	[self.displayProgressLabel setStringValue:progressText];
	[self.displayProgressTextView setStringValue:@""];
	
	//	Localize the Go Back step as well
	[self.previousStepButton setTitle:NSLocalizedString(@"Go Back", @"Go Back button text for installation/uninstallation window")];
	
	//	Initialize the views
	self.displayWebView.hidden = YES;
	self.displayTextScrollView.hidden = YES;
	self.displayProgressView.hidden = YES;
	self.actionSummaryView.hidden = YES;
	self.displayWebView.alphaValue = 0.0f;
	self.displayTextScrollView.alphaValue = 0.0f;
	self.displayProgressView.alphaValue = 0.0f;
	self.actionSummaryView.alphaValue = 0.0f;
	
	//	Set the current step
	self.currentStep = 0;
	
}


#pragma mark - Step Management

- (void)setCurrentStep:(NSUInteger)aCurrentInstallStep {
	if (_currentStep != aCurrentInstallStep) {
		
		BOOL	goingBackward = (aCurrentInstallStep < _currentStep);
		
		//	Validate that we don't go beyond our range
		if (self.manifestModel.confirmationStepCount <= aCurrentInstallStep) {
			//	Call our display the installation progress method and return
			[self startActions];
			return;
		}
		
		//	Ensure that license agreements are agreed to, if necessary
		if (!goingBackward && ![self checkForLicenseRequirement]) {
			return;
		}
		
		[self updateCurrentConfigurationToStep:aCurrentInstallStep];
		_currentStep = aCurrentInstallStep;
	}
}


- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
	if (flag) {
		if ([[anim valueForKey:@"name"] isEqualToString:@"fadeOut"]) {
			CABasicAnimation	*fadeIn = [CABasicAnimation animation];
			[fadeIn setValue:@"fadeIn" forKey:@"name"];
			fadeIn.duration = 0.1f;
			[fadeIn setDelegate:self];
			if ([anim valueForKey:@"removeView"] != nil) {
				[fadeIn setValue:[anim valueForKey:@"removeView"] forKey:@"removeView"];
			}
			NSView	*incomingView = [anim valueForKey:@"incomingView"];
			[incomingView setAnimations:[NSDictionary dictionaryWithObject:fadeIn forKey:@"alphaValue"]];
			//	Fade in
			[[incomingView animator] setAlphaValue:1.0f];
		}
		else if ([[anim valueForKey:@"name"] isEqualToString:@"fadeIn"]) {
			if ([anim valueForKey:@"removeView"] != nil) {
				[[anim valueForKey:@"removeView"] setHidden:YES];
			}
		}
	}
}

- (void)showContentView:(NSView *)aView {
	NSView	*outView = nil;
	if (self.displayWebView.alphaValue > 0.9f) {
		outView = self.displayWebView;
	}
	else if (self.displayTextScrollView.alphaValue > 0.9f) {
		outView = self.displayTextScrollView;
	}
	else if (self.displayProgressView.alphaValue > 0.9f) {
		outView = self.displayProgressView;
	}
	else if (self.actionSummaryView.alphaValue > 0.9f) {
		outView = self.actionSummaryView;
	}
	
	aView.hidden = NO;
	aView.alphaValue = 0.0;

	//	If outview is nil, just show the view
	if (outView == nil) {
		CABasicAnimation	*fadeIn = [CABasicAnimation animation];
		fadeIn.duration = 0.2f;
		[aView setAnimations:[NSDictionary dictionaryWithObject:fadeIn forKey:@"alphaValue"]];
		//	Fade in
		[[aView animator] setAlphaValue:1.0f];
	}
	else {
		CABasicAnimation	*fadeOut = [CABasicAnimation animation];
		[fadeOut setValue:@"fadeOut" forKey:@"name"];
		fadeOut.duration = 0.1f;
		[fadeOut setDelegate:self];
		[fadeOut setValue:aView forKey:@"incomingView"];
		[fadeOut setValue:outView forKey:@"removeView"];
		[outView setAnimations:[NSDictionary dictionaryWithObject:fadeOut forKey:@"alphaValue"]];
		//	Fade out
		[[outView animator] setAlphaValue:0.0f];
	}
}


- (void)updateCurrentConfigurationToStep:(NSUInteger)toStep {
	
	MPCConfirmationStep	*newStep = nil;
	if (self.manifestModel.confirmationStepCount > toStep) {
		newStep = [self.manifestModel.confirmationStepList objectAtIndex:toStep];
	}
	
	//	Ensure that we have something to do
	if (newStep == nil) {
		return;
	}
	
	BOOL	isConfirmed = newStep.type == kMPCConfirmationTypeConfirm;
	//	Load the contents 
	//	Is it html?
	if (newStep.hasHTMLContent) {
		[self showContentView:self.displayWebView];
		[self.displayWebView setMainFrameURL:newStep.path];
	}
	else if (isConfirmed) {
		//	Set the datasource for the installation summary tableview
		[self.actionSummaryTable setDataSource:self];
		[self showContentView:self.actionSummaryView];
	}
	else {
		[self showContentView:self.displayTextScrollView];
		[self.displayTextView readRTFDFromFile:newStep.path];
	}
	
	//	Title above the webview (its layer is used to animate it)
	((CATextLayer *)self.titleTextField.layer).string = newStep.title;
	
	//	Configure the two buttons at the bottom
	NSString	*actionTitle = NSLocalizedString(@"Continue", @"Continue button text for installation/uninstallation");
	if (isConfirmed) {
		actionTitle = (self.manifestModel.manifestType==kMPCManifestTypeInstallation)?NSLocalizedString(@"Install", @"Install button text for installation"):NSLocalizedString(@"Uninstall", @"Remove button text for uninstallation");
	}
	[self.actionButton setTitle:actionTitle];
	[self.previousStepButton setEnabled:(toStep != 0)];
	
	self.animatedListController.selectedStep = toStep;
}


#pragma mark - Actions

- (IBAction)moveToNextStep:(id)sender {
	self.currentStep = self.currentStep + 1;
}

- (IBAction)moveToPreviousStep:(id)sender {
	self.currentStep = self.currentStep - 1;
}

- (IBAction)closeAgreementDialog:(id)sender {
	[NSApp endSheet:self.agreementDialog];

	switch ([sender tag]) {
		case NSAlertDefaultReturn:
			//	Continue
			self.currentInstallationStep.agreementAccepted = YES;
			[self moveToNextStep:self];
			break;
			
		case NSAlertOtherReturn:
			//	Quit
			[NSApp terminate:self];
			break;
			
		default:
			break;
	}
}



- (void)startActions {

	//	Test installation requirements
	if ((self.manifestModel.manifestType == kMPCManifestTypeInstallation) &&
		![self validateRequirements]) {
		return;
	}
	

	//	Show the progress view
	[self showContentView:self.displayProgressView];
	
	//	Disable the buttons
	[self.previousStepButton setEnabled:NO];
	[self.actionButton setEnabled:NO];
	
	//	Set the total value for the progress bar
	[self.progressBar setMaxValue:self.manifestModel.totalActionItemCount];
	
	//	Set up some notification watches
	self.notificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMPCInstallationProgressNotification object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		//	Update the UI
		NSDictionary	*info = [note userInfo];
		if ([info valueForKey:kMPCInstallationProgressDescriptionKey]) {
			[self.displayProgressTextView setStringValue:[info valueForKey:kMPCInstallationProgressDescriptionKey]];
		}
		if ([info valueForKey:kMPCInstallationProgressValueKey]) {
			[self.progressBar incrementBy:[[info valueForKey:kMPCInstallationProgressValueKey] doubleValue]];
		}
	}];
	
	//	Do the installation on a dispatch queue
	dispatch_queue_t	myQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(myQueue, ^(void) {
		
		NSString	*displayMessage = nil;
		self.displayErrorMessage = nil;
		if (![self processAllItems]) {
			if (self.displayErrorMessage == nil) {
				//	Localize the progress label
				NSString	*progressText = NSLocalizedString(@"The %@ was not completed successfully .\nSorry for any inconvenience.", @"Progress label after failure");
				NSString	*actionText = NSLocalizedString(@"installation", @"Installation name");
				if (self.manifestModel.manifestType == kMPCManifestTypeUninstallation) {
					actionText = NSLocalizedString(@"removal", @"Uninstallation name");
				}
				displayMessage = [NSString stringWithFormat:progressText, actionText];
			}
			else {
				displayMessage = self.displayErrorMessage;
			}
			
		}
		else if (self.manifestModel.manifestType == kMPCManifestTypeUninstallation) {
			displayMessage = NSLocalizedString(@"Uninstall successful.\n\n%@", @"Uninstall successful message in view");
			displayMessage = [NSString stringWithFormat:displayMessage, self.manifestModel.completionMessage];
		}
		else if (self.displayErrorMessage != nil) {
			displayMessage = self.displayErrorMessage;
		}
		else {
			displayMessage = NSLocalizedString(@"Installation complete.\n\n%@", @"Installation successful message in view");
			displayMessage = [NSString stringWithFormat:displayMessage, self.manifestModel.completionMessage];
		}
		
		//	Configure a quit button
		NSString	*actionTitle = NSLocalizedString(@"Quit", @"Quit button text for installation/uninstallation");
		[self.actionButton setTitle:actionTitle];
		[self.actionButton setEnabled:YES];
		[self.actionButton setTarget:AppDel];
		[self.actionButton setAction:@selector(finishApplication:)];
		[self.previousStepButton setHidden:YES];

		[self.displayProgressLabel setStringValue:displayMessage];
		[self.progressBar setHidden:YES];
		[self.displayProgressTextView setHidden:YES];
		
		//	Try to ensure that Manager is in front
		int64_t delta = (int64_t)(NSEC_PER_SEC * 2.0f);
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delta), dispatch_get_main_queue(), ^{
			[NSApp activateIgnoringOtherApps:YES];
		});
		
	});
	
}


#pragma mark - ActionItem Methods

- (BOOL)processAllItems {
	
	//	Try to process the items first
	BOOL result = [self processItems];
	//	If that worked, then try to process the bundle manager
	if (result) {
		result = [self processBundleManager];
	}
	//	Then if needed configure Mail
	if (result) {
		result = [self configureMail];
	}
	return result;
}

- (BOOL)validateRequirements {
	
	MPCManifestModel	*model = self.manifestModel;
	NSFileManager		*manager = [NSFileManager defaultManager];
	NSWorkspace			*workspace = [NSWorkspace sharedWorkspace];
	
	//	Ensure that the versions all check out
	MPCOSSupportResult	supportResult = [model supportResultForManifest];
	if (supportResult == kMPCOSIsTooLow) {
		LKPresentErrorCode(MPCMinOSInsufficientCode);
		return NO;
	}
	if (supportResult == kMPCOSIsTooHigh) {
		LKPresentErrorCode(MPCMaxOSInsufficientCode);
		return NO;
	}
	if (model.minMailVersion != kMPCNoVersionRequirement) {
		CGFloat	currentVersion = mailVersion();
		if (currentVersion > model.minMailVersion) {
			LKPresentErrorCode(MPCMinMailInsufficientCode);
			return NO;
		}
	}
	
	//	First just ensure that the all items are there to copy
	for (MPCActionItem *anItem in model.actionItemList) {
		if (![manager fileExistsAtPath:anItem.path]) {
			NSDictionary	*dict = [NSDictionary dictionaryWithObjectsAndKeys:anItem.name, kMPCNameKey, anItem.path, kMPCPathKey, nil];
			LKPresentErrorCodeUsingDict(MPCInvalidSourcePath, dict);
			LKErr(@"The source path for the item (%@) [%@] is invalid.", anItem.name, anItem.path);
			return NO;
		}
	}

	//	Ensure that the source bundle is where we think it is
	if ((model.bundleManager != nil) && (![manager fileExistsAtPath:model.bundleManager.path] || ![workspace isFilePackageAtPath:model.bundleManager.path])) {
		NSDictionary	*dict = [NSDictionary dictionaryWithObjectsAndKeys:model.bundleManager.name, kMPCNameKey, model.bundleManager.path, kMPCPathKey, nil];
		LKPresentErrorCodeUsingDict(MPCInvalidSourcePath, dict);
		LKErr(@"The source path for the bundle manager (%@) is invalid.", model.bundleManager.path);
		return NO;
	}

	return YES;
}

- (BOOL)configureMail {
	
	//	Only need to bother if the manifest asked for it
	if (self.manifestModel.shouldConfigureMail || self.manifestModel.shouldRestartMail) {
		//	Get Mail settings
		NSDictionary	*mailDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:kMPCMailBundleIdentifier];
		
		//	Make the block for updating those values
		void	(^configureBlock)(void) = nil;

		//	Test to see if those settings are sufficient
		if (([[mailDefaults valueForKey:kMPCEnableBundlesKey] boolValue]) &&
			(((NSUInteger)[[mailDefaults valueForKey:kMPCBundleCompatibilityVersionKey] integerValue]) >= self.manifestModel.configureMailVersion)) {
			
			//	If no restart wanted,
			if (!self.manifestModel.shouldRestartMail) {
				//	Then we are done
				return YES;
			}
		}
		else { 
			//	Make the block for updating those values
			configureBlock = ^(void) {
				NSMutableDictionary	*newMailDefs = [[mailDefaults mutableCopy] autorelease];
				[newMailDefs setValue:@"YES" forKey:kMPCEnableBundlesKey];
				[newMailDefs setValue:[NSNumber numberWithInteger:self.manifestModel.configureMailVersion] forKey:kMPCBundleCompatibilityVersionKey];
				[[NSUserDefaults standardUserDefaults] setPersistentDomain:newMailDefs forName:kMPCMailBundleIdentifier];
			};
		}
		
		//	If we should restart mail
		if (self.manifestModel.shouldRestartMail && AppDel.isMailRunning) {
			//	Test to see if Mail is running
			if (![AppDel askToRestartMailWithBlock:configureBlock usingIcon:nil]) {
				self.displayErrorMessage = NSLocalizedString(@"The plugin has been %@, but Mail has not been completely configured correctly to recognize it.\n\nPlease quit Mail for the changes to take affect.", @"Message to indicate to the user that mail was configured but not restarted");
				self.displayErrorMessage = [NSString stringWithFormat:self.displayErrorMessage, 
											(self.manifestModel.manifestType == kMPCManifestTypeInstallation)?NSLocalizedString(@"installed", @"Install name"):NSLocalizedString(@"uninstalled", @"Installed name")];
			}
		}

		//	If we are here then, we just need to run the configure block if it not nil
		if (configureBlock != nil) {
			configureBlock();
		}
	}

	return YES;
}

#pragma mark Items

- (BOOL)processItems {
	
	//	Install each one
	for (MPCActionItem *anItem in self.manifestModel.actionItemList) {
		if (self.manifestModel.manifestType == kMPCManifestTypeInstallation) {
			if (![self installItem:anItem]) {
				return NO;
			}
		}
		else {
			if (![self removeItem:anItem]) {
				return NO;
			}
		}
	}
	
	return YES;
}

- (BOOL)installItem:(MPCActionItem *)anItem {
	
	NSFileManager	*manager = [NSFileManager defaultManager];
	
	//	Before installing an actual mail bundle, ensure that the plugin is actaully update to date
	if (anItem.isMailBundle) {

		//	Create a mail bundle
		MPCMailBundle	*mailBundle = [[[MPCMailBundle alloc] initWithPath:anItem.path shouldLoadUpdateInfo:NO] autorelease];
		//	Test to ensure that the plugin is actually compatible
		if ([mailBundle incompatibleWithCurrentMail]) {
			NSDictionary	*theDict = [NSDictionary dictionaryWithObjectsAndKeys:[MPCSystemInfo mailVersion], kMPCVersionKey, nil];
			LKPresentErrorCodeUsingDict(MPCPluginDoesNotWorkWithMailVersion, theDict);
			LKErr(@"This Mail Plugin will not work with this version of Mail:mailUUID:%@ messageUUID:%@", [MPCUUIDList currentMailUUID], [MPCUUIDList currentMessageUUID]);
			return NO;
		}
	}
	
	//	Notification for what we are copying
	NSDictionary	*myDict = [NSDictionary dictionaryWithObjectsAndKeys:anItem.name, kMPCInstallationProgressDescriptionKey, nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kMPCInstallationProgressNotification object:self userInfo:myDict];
	
	//	Make sure that the destination folder exists
	NSError	*error;
	if (![manager fileExistsAtPath:[anItem.destinationPath stringByDeletingLastPathComponent]]) {
		if (![manager createDirectoryAtPath:[anItem.destinationPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error]) {
			NSDictionary	*theDict = [NSDictionary dictionaryWithObjectsAndKeys:anItem.name, kMPCNameKey, error, kMPCErrorKey, nil];
			LKPresentErrorCodeUsingDict(MPCCantCreateFolder, theDict);
			LKErr(@"Couldn't create folder to copy item '%@' into:%@", anItem.name, error);
			return NO;
		}
	}
	
	BOOL	isFolder;
	[manager fileExistsAtPath:[anItem.destinationPath stringByDeletingLastPathComponent] isDirectory:&isFolder];
	if (!isFolder) {
		NSDictionary	*theDict = [NSDictionary dictionaryWithObjectsAndKeys:anItem.name, kMPCNameKey, [anItem.destinationPath stringByDeletingLastPathComponent], kMPCPathKey, nil];
		LKPresentErrorCodeUsingDict(MPCTryingToInstallOverFile, theDict);
		LKErr(@"Can't copy item '%@' to location that is actually a file:%@", anItem.name, [anItem.destinationPath stringByDeletingLastPathComponent]);
		return NO;
	}
	
	//	Now do the copy, replacing anything that is already there
	if (![manager copyWithAuthenticationIfNeededFromPath:anItem.path toPath:anItem.destinationPath error:&error]) {
		NSDictionary	*theDict = [NSDictionary dictionaryWithObjectsAndKeys:anItem.name, kMPCNameKey, anItem.destinationPath, kMPCPathKey, error, kMPCErrorKey, nil];
		LKPresentErrorCodeUsingDict(MPCCopyFailed, theDict);
		LKErr(@"Unable to copy item '%@' to %@\n%@", anItem.name, anItem.destinationPath, error);
		return NO;
	}

	//	Notification for progress bar
	myDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:1.0f], kMPCInstallationProgressValueKey, nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kMPCInstallationProgressNotification object:self userInfo:myDict];

	return YES;
}

- (BOOL)removeItem:(MPCActionItem *)anItem {
	
	//	Default is to trash it
	NSString	*fromPath = anItem.path;
	NSString	*toPath = [[NSHomeDirectory() stringByAppendingPathComponent:@".Trash"] stringByAppendingPathComponent:[anItem.path lastPathComponent]];
	NSError		*error;
		
	//	Ensure that we have a unique file name for the trash
	NSString	*tempPath = toPath;
	NSInteger	counter = 1;
	while ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
		tempPath = [toPath stringByAppendingFormat:@" %ld", counter++];
	}
	if (toPath != tempPath) {	//	Using pointer equivalence here expressly!!
		toPath = tempPath;
	}
	
	//	Notification for what we are deleting
	NSDictionary	*myDict = [NSDictionary dictionaryWithObjectsAndKeys:anItem.name, kMPCInstallationProgressDescriptionKey, nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kMPCInstallationProgressNotification object:self userInfo:myDict];
	
	//	Move the plugin to the trash
	if ([[NSFileManager defaultManager] moveWithAuthenticationIfNeededFromPath:fromPath toPath:toPath overwrite:NO error:&error]) {
		//	Send a notification
		[[NSNotificationCenter defaultCenter] postNotificationName:kMPCMailBundleUninstalledNotification object:self];
	}
	else {
		NSDictionary	*theDict = [NSDictionary dictionaryWithObjectsAndKeys:anItem.name, kMPCNameKey, error, kMPCErrorKey, nil];
		LKPresentErrorCodeUsingDict(MPCUnableToMoveFileToTrash, theDict);
		return NO;
	}

	//	Notification for progress bar
	myDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:1.0f], kMPCInstallationProgressValueKey, nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kMPCInstallationProgressNotification object:self userInfo:myDict];
	
	return YES;
}


#pragma mark BundleManager

- (BOOL)processBundleManager {
	if (!self.manifestModel.shouldInstallManager) {
		return YES;
	}
	
	if (self.manifestModel.manifestType == kMPCManifestTypeInstallation) {
		return [self installBundleManager];
	}
	else {
		return [self removeBundleManagerIfReasonable];
	}
}

- (BOOL)installBundleManager {
	
	MPCManifestModel	*model = self.manifestModel;
	NSFileManager		*manager = [NSFileManager defaultManager];
	NSWorkspace			*workspace = [NSWorkspace sharedWorkspace];
	
	//	First get any existing bundle at the destination
	NSBundle	*destBundle = nil;
	if ([manager fileExistsAtPath:model.bundleManager.destinationPath]) {
		//	Then ensure that it is a package
		if ([workspace isFilePackageAtPath:model.bundleManager.destinationPath]) {
			destBundle = [NSBundle bundleWithPath:model.bundleManager.destinationPath];
		}
	}
	//	If there is a destination already, check it's bundle id matches and version is < installing one
	if (destBundle) {
		NSBundle	*sourceBundle = [NSBundle bundleWithPath:model.bundleManager.path];
		
		BOOL		isSameBundleID = [[sourceBundle bundleIdentifier] isEqualToString:[destBundle bundleIdentifier]];
		BOOL		isSourceVersionGreater = ([MPCMailBundle compareVersion:[[sourceBundle infoDictionary] valueForKey:(NSString *)kCFBundleVersionKey] toVersion:[[destBundle infoDictionary] valueForKey:(NSString *)kCFBundleVersionKey]] == NSOrderedDescending);
		
		//	There is a serious problem if the bundle ids are different
		if (!isSameBundleID) {
			NSDictionary	*theDict = [NSDictionary dictionaryWithObjectsAndKeys:[[sourceBundle infoDictionary] valueForKey:(NSString *)kCFBundleNameKey], kMPCNameKey, [sourceBundle bundleIdentifier], @"bundleid", [[destBundle infoDictionary] valueForKey:(NSString *)kCFBundleNameKey], @"dest-name", [destBundle bundleIdentifier], @"bundleid2", nil];
			LKPresentErrorCodeUsingDict(MPCGenericFileCode, theDict);
			LKErr(@"Trying to install a bundle manager (%@) with different BundleID [%@] over existing app (%@) [%@]", [[sourceBundle infoDictionary] valueForKey:(NSString *)kCFBundleNameKey], [sourceBundle bundleIdentifier], [[destBundle infoDictionary] valueForKey:(NSString *)kCFBundleNameKey], [destBundle bundleIdentifier]);
			return NO;
		}
		
		//	If the source version is not greater then just return yes and leave the existing one
		if (!isSourceVersionGreater) {
			LKWarn(@"Not actually copying the Bundle Manager since a recent version is already at destination");
			return YES;
		}
	}
	
	//	Install the bundle
	return [self installItem:model.bundleManager];
}

- (BOOL)removeBundleManagerIfReasonable {
	
	MPCManifestModel	*model = self.manifestModel;
	BOOL				shouldRemove = NO;
	
	//	Test the existing bundles first
	NSArray	*mailBundleList = [MPCMailBundle allMailBundles];
	//	Test to ensure what rules we should use
	if ((model.canDeleteManagerIfNoBundlesLeft) && ([mailBundleList count] > 0)) {
		shouldRemove = YES;
	}
	if (model.canDeleteManagerIfNotUsedByOthers) {
		shouldRemove = YES;
		for (MPCMailBundle *aMailBundle in mailBundleList) {
			if (aMailBundle.usesBundleManager) {
				shouldRemove = NO;
			}
		}
	}

	//	If we should remove, do it and return those results
	if (shouldRemove) {
		return [self removeItem:model.bundleManager];
	}
	
	return NO;
}


#pragma mark - License Agreement Handling

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	[sheet orderOut:self];
}

- (BOOL)checkForLicenseRequirement {
	if (self.currentInstallationStep.requiresAgreement && !self.currentInstallationStep.agreementAccepted) {

		//	Load the dialog window
		if (!self.agreementDialog) {
			[NSBundle loadNibNamed:@"MPCAgreementWindow" owner:self];
			
			//	Localize the labels and buttons
			NSArray	*subviews = [[self.agreementDialog contentView] subviews];
			for (NSView *aView in subviews) {
				if ([aView isKindOfClass:[NSTextField class]]) {
					//	Localize the stringValue
					[(NSTextField *)aView setStringValue:NSLocalizedString([(NSTextField *)aView stringValue], @"don't localize")];
				}
				else if ([aView isKindOfClass:[NSButton class]]) {
					//	Localize the title
					[(NSButton *)aView setTitle:NSLocalizedString([(NSButton *)aView title], @"don't localize")];
				}
			}
			
		}
		
		//	Show the dialog
		[NSApp beginSheet:self.agreementDialog modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
		
		return NO;
	}
	return YES;
}

#pragma mark - TableView DataSource & Delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return self.manifestModel.totalActionItemCount;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	
	NSInteger			maxIndex = self.manifestModel.totalActionItemCount - 1;
	MPCActionItem	*theItem = nil;
	
	//	Get the correct item
	if (row > maxIndex) {
		return nil;
	}
	else if ((row == maxIndex) && self.manifestModel.shouldInstallManager) {
		theItem = self.manifestModel.bundleManager;
	}
	else {
		theItem = [self.manifestModel.actionItemList objectAtIndex:row];
	}
	
	//	If we need the icon, get that from the filemanager
	if ([[tableColumn identifier] isEqualToString:@"icon"]) {
		NSImage		*theIcon = [[NSWorkspace sharedWorkspace] iconForFile:theItem.path];
		[theIcon setSize:NSMakeSize(128.0f, 128.0f)];
		return theIcon;
	}
	//	Otherwise format a description of the file to install
	else {
		//	Format each piece of the description
		//	
		NSColor	*mainColor = [NSColor colorWithDeviceRed:0.267 green:0.271 blue:0.278 alpha:1.000];
		NSColor	*pathColor = [NSColor colorWithDeviceRed:0.433 green:0.438 blue:0.456 alpha:1.000];
		NSColor	*labelColor = [NSColor colorWithDeviceRed:0.364 green:0.369 blue:0.385 alpha:1.000];
		if ([tableView selectedRow] == row) {
			mainColor = [NSColor colorWithDeviceWhite:1.000 alpha:1.000];
			pathColor = [NSColor colorWithDeviceWhite:0.841 alpha:1.000];
			labelColor = [NSColor colorWithDeviceWhite:0.900 alpha:1.000];
		}
		NSDictionary	*nameAttrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:16.0f] , NSFontAttributeName, 
									  mainColor, NSForegroundColorAttributeName,
									  nil];
		NSDictionary	*filenameAttrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:11.0f] , NSFontAttributeName, 
											 pathColor, NSForegroundColorAttributeName,
											 [NSNumber numberWithFloat:0.2f], NSObliquenessAttributeName,
											 [NSNumber numberWithFloat:-2.0f], NSBaselineOffsetAttributeName,
											 nil];
		NSDictionary	*fileLabelAttrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:12.0f] , NSFontAttributeName, 
										   labelColor, NSForegroundColorAttributeName,
										   [NSNumber numberWithFloat:-2.0f], NSBaselineOffsetAttributeName,
										   nil];
		
		NSDictionary	*descAttrs = [NSDictionary dictionaryWithObjectsAndKeys:mainColor, NSForegroundColorAttributeName,
									  nil];
		NSAttributedString	*nameString = [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:((theItem.itemDescription != nil)?@"%@ – ":@"%@"), theItem.name] attributes:nameAttrs] autorelease];
		NSAttributedString	*filenameString = [[[NSAttributedString alloc] initWithString:[theItem.path lastPathComponent] attributes:filenameAttrs] autorelease];
		NSAttributedString	*descString = [[[NSAttributedString alloc] initWithString:((theItem.itemDescription != nil)?theItem.itemDescription:@"") attributes:descAttrs] autorelease];
		
		//	Test for destination info
		NSAttributedString	*destinationLabelString = nil;
		NSAttributedString	*destinationString = nil;
		if (theItem.destinationPath != nil) {
			
			destinationLabelString = [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Destination: ", @"Label for destination in action summary lists.") attributes:fileLabelAttrs] autorelease];
			destinationString = [[[NSAttributedString alloc] initWithString:[theItem.destinationPath stringByDeletingLastPathComponent] attributes:filenameAttrs] autorelease];
		}
		
		//	Then build them all together in the correct format
		NSMutableAttributedString	*fullString = [[[NSMutableAttributedString alloc] initWithAttributedString:nameString] autorelease];
		[fullString appendAttributedString:descString];
		[fullString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n  "] autorelease]];
		[fullString appendAttributedString:[[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Filename: ", @"Label for source file name in action summary lists.") attributes:fileLabelAttrs] autorelease]];
		[fullString appendAttributedString:filenameString];
		if (destinationString != nil) {
			[fullString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n  "] autorelease]];
			[fullString appendAttributedString:destinationLabelString];
			[fullString appendAttributedString:destinationString];
		}
		
		return [[[NSAttributedString alloc] initWithAttributedString:fullString] autorelease];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	[[notification object] reloadData];
}


#pragma mark - Error Delegate Methods

- (NSString *)overrideErrorDomainForCode:(NSInteger)aCode {
	return (self.manifestModel.manifestType==kMPCManifestTypeInstallation)?@"MPCInstallErrorDomain":@"MPCUnInstallErrorDomain";
}

- (NSArray *)recoveryOptionsForError:(LKError *)error {
	return [error localizedRecoveryOptionList];
}

- (NSArray *)formatDescriptionValuesForError:(LKError *)error {
	NSMutableArray	*values = [NSMutableArray array];
	switch ([error code]) {
		case MPCMinOSInsufficientCode:
			[values addObject:self.manifestModel.displayName];
			[values addObject:self.manifestModel.minOSVersion];
			[values addObject:[NSString stringWithFormat:@"%3.1f.%d", macOSXVersion(), macOSXBugFixVersion()]];
			break;
			
		case MPCMaxOSInsufficientCode:
			[values addObject:self.manifestModel.displayName];
			[values addObject:self.manifestModel.maxOSVersion];
			[values addObject:[NSString stringWithFormat:@"%3.1f.%d", macOSXVersion(), macOSXBugFixVersion()]];
			break;
			
		case MPCMinMailInsufficientCode:
			[values addObject:self.manifestModel.displayName];
			[values addObject:[NSString stringWithFormat:@"%3.1f", self.manifestModel.minMailVersion]];
			[values addObject:[NSString stringWithFormat:@"%3.1f", mailVersion()]];
			break;
			
		default:
			break;
	}
	return IsEmpty(values)?nil:[NSArray arrayWithArray:values];
}

- (id)recoveryAttemptorForError:(LKError *)error {
	return self;
}

- (BOOL)attemptRecoveryFromError:(NSError *)error optionIndex:(NSUInteger)recoveryOptionIndex {
	return recoveryOptionIndex==0?YES:NO;
}



@end
