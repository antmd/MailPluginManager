//
//  MBMInstallerController.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 20/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBMInstallerController.h"
#import <QuartzCore/QuartzCore.h>

#import "MBMMailBundle.h"

@interface MBMInstallerController ()
@property	(nonatomic, assign)	id	notificationObserver;
- (void)updateCurrentConfigurationToStep:(NSInteger)toStep;
- (void)showContentView:(NSView *)aView;
- (void)startInstall;

- (BOOL)installAll;
- (BOOL)installItems;
- (BOOL)installBundleManager;
- (BOOL)installItem:(MBMInstallationItem *)anItem;
@end

@implementation MBMInstallerController

#pragma mark - Accessors

@synthesize notificationObserver = _notificationObserver;

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


#pragma mark - Memory and Window Management

- (id)initWithInstallationModel:(MBMInstallationModel *)aModel {
    self = [super initWithWindowNibName:@"MBMInstallerWindow"];
    if (self) {
        // Initialization code here.
		_installationModel = [aModel retain];
		_currentInstallStep = kMBMInvalidStep;
    }
    
    return self;
}

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self.notificationObserver];
	self.notificationObserver = nil;
	self.installationModel = nil;
	self.animatedListController = nil;
	
	[super dealloc];
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
	CGColorRef	aColor = CGColorCreateGenericGray(0.000, 1.000);	//	Black
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

#pragma mark - Actions

- (IBAction)moveToNextStep:(id)sender {
	self.currentInstallStep = self.currentInstallStep + 1;
}

- (IBAction)moveToPreviousStep:(id)sender {
	self.currentInstallStep = self.currentInstallStep - 1;
}


- (void)startInstall {
	//	Show the progress view
	[self showContentView:self.displayProgressView];
	
	//	Disable the buttons
	[self.previousStepButton setEnabled:NO];
	[self.actionButton setEnabled:NO];
	
	//	Set the total value for the progress bar
	[self.progressBar setMaxValue:self.installationModel.totalInstallationItemCount];
	
	//	Set up some notification watches
	self.notificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kMBMInstallationProgressNotification object:self.installationModel queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		//	Update the UI
		NSDictionary	*info = [note userInfo];
		if ([info valueForKey:kMBMInstallationProgressDescriptionKey]) {
			[self.displayProgressTextView setStringValue:[info valueForKey:kMBMInstallationProgressDescriptionKey]];
		}
		if ([info valueForKey:kMBMInstallationProgressValueKey]) {
			[self.progressBar setDoubleValue:[[info valueForKey:kMBMInstallationProgressValueKey] doubleValue]];
		}
	}];
	
	NSArray	*textList = [NSArray arrayWithObjects:@"A File.txt", @"My Big File.app", @"Bundle Manager.app", nil];

	CGFloat	counter = 0.4f;
	CGFloat	delayTime = 0.0f;
	for (NSString *text in textList) {
		NSDictionary	*myDict = [NSDictionary dictionaryWithObjectsAndKeys:text, kMBMInstallationProgressDescriptionKey, 
								   [NSNumber numberWithDouble:counter], kMBMInstallationProgressValueKey,
								   nil];
		NSNotification	*dumNote = [NSNotification notificationWithName:kMBMInstallationProgressNotification object:self.installationModel userInfo:myDict];
		[[NSNotificationCenter defaultCenter] performSelector:@selector(postNotification:) withObject:dumNote afterDelay:delayTime];
		counter = counter + 0.4f;
		delayTime = delayTime + 1.0f;
	}
	
	
}


#pragma mark - Installer Methods

- (BOOL)installAll {
	
	MBMInstallationModel	*model = self.installationModel;
	
	//	Ensure that the versions all check out
	CGFloat	currentVersion = macOSXVersion();
	if ((model.minOSVersion != kMBMNoVersionRequirement) && (currentVersion < model.minOSVersion)) {
		LKLog(@"ERROR:Minimum OS version (%3.2f) requirement not met (%3.2f)", model.minOSVersion, currentVersion);
		return NO;
	}
	if ((model.maxOSVersion != kMBMNoVersionRequirement) && (currentVersion > model.maxOSVersion)) {
		LKLog(@"ERROR:Maximum OS version (%3.2f) requirement not met (%3.2f)", model.maxOSVersion, currentVersion);
		return NO;
	}
	if (model.minMailVersion != kMBMNoVersionRequirement) {
		currentVersion = mailVersion();
		if (currentVersion > model.minMailVersion) {
			LKLog(@"ERROR:Minimum Mail version (%3.2f) requirement not met (%3.2f)", model.minMailVersion, currentVersion);
			return NO;
		}
	}
	
	BOOL	result = [self installBundleManager];
	if (result) {
		result = [self installItems];
	}
	return result;
}

- (BOOL)installItems {
	
	NSFileManager	*manager = [NSFileManager defaultManager];
	
	//	First just ensure that the all items are there to copy
	for (MBMInstallationItem *anItem in self.installationModel.installationItemList) {
		if (![manager fileExistsAtPath:anItem.path]) {
			ALog(@"ERROR:The source path for the item (%@) [%@] is invalid.", anItem.name, anItem.path);
			return NO;
		}
	}
	
	//	Then install each one
	for (MBMInstallationItem *anItem in self.installationModel.installationItemList) {
		[self installItem:anItem];
	}
	
	return YES;
}

- (BOOL)installBundleManager {
	
	MBMInstallationModel	*model = self.installationModel;
	NSFileManager			*manager = [NSFileManager defaultManager];
	NSWorkspace				*workspace = [NSWorkspace sharedWorkspace];
	
	//	Ensure that the source bundle is where we think it is
	if (![manager fileExistsAtPath:model.bundleManager.path] || ![workspace isFilePackageAtPath:model.bundleManager.path]) {
		ALog(@"ERROR:The source path for the bundle manager (%@) is invalid.", model.bundleManager.path);
		return NO;
	}
	
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
		BOOL		isSourceVersionGreater = ([MBMMailBundle compareVersion:[[sourceBundle infoDictionary] valueForKey:(NSString *)kCFBundleVersionKey] toVersion:[[destBundle infoDictionary] valueForKey:(NSString *)kCFBundleVersionKey]] == NSOrderedDescending);
		
		//	There is a serious problem if the bundle ids are different
		if (!isSameBundleID) {
			
			ALog(@"ERROR:Trying to install a bundle manager (%@) with different BundleID [%@] over existing app (%@) [%@]", [[sourceBundle infoDictionary] valueForKey:(NSString *)kCFBundleNameKey], [sourceBundle bundleIdentifier], [[destBundle infoDictionary] valueForKey:(NSString *)kCFBundleNameKey], [destBundle bundleIdentifier]);
			return NO;
		}
		
		//	If the source version is not greater then just return yes and leave the existing one
		if (!isSourceVersionGreater) {
			LKLog(@"Not actually copying the Bundle Manager since a recent version is already at destination");
			return YES;
		}
	}
	
	//	Install the bundle
	return [self installItem:model.bundleManager];
}

- (BOOL)installItem:(MBMInstallationItem *)anItem {
	
	NSFileManager	*manager = [NSFileManager defaultManager];
	
	//	Before installing an actual mail bundle, ensure that the plugin is actaully update to date
	if (anItem.isMailBundle) {
		//	Get the values to test
		NSBundle	*aBundle = [NSBundle bundleWithPath:anItem.path];
		NSArray		*supportedUUIDs = [[aBundle infoDictionary] valueForKey:kMBMMailBundleUUIDListKey];
		aBundle = [NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:kMBMMailBundleIdentifier]];
		NSString	*mailUUID = [[aBundle infoDictionary] valueForKey:kMBMMailBundleUUIDKey];
		NSString	*messageBundlePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSSystemDomainMask, NO) lastObject];
		messageBundlePath = [messageBundlePath stringByAppendingPathComponent:kMBMMessageBundlePath];
		aBundle = [NSBundle bundleWithPath:messageBundlePath];
		NSString	*messageUUID = [[aBundle infoDictionary] valueForKey:kMBMMailBundleUUIDKey];
		
		//	Test to ensure that the plugin list contains both the mail and message UUIDs
		if (![supportedUUIDs containsObject:mailUUID] || ![supportedUUIDs containsObject:messageUUID]) {
			LKLog(@"This Mail Plugin will not work with this version of Mail");
			return NO;
		}
	}
	
	//	Make sure that the destination folder exists
	NSError	*error;
	if (![manager fileExistsAtPath:[anItem.destinationPath stringByDeletingLastPathComponent]]) {
		if (![manager createDirectoryAtPath:[anItem.destinationPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error]) {
			ALog(@"ERROR:Couldn't create folder to copy item '%@' into:%@", anItem.name, error);
			return NO;
		}
	}
	
	BOOL	isFolder;
	[manager fileExistsAtPath:[anItem.destinationPath stringByDeletingLastPathComponent] isDirectory:&isFolder];
	if (!isFolder) {
		ALog(@"ERROR:Can't copy item '%@' to location that is actually a file:%@", anItem.name, [anItem.destinationPath stringByDeletingLastPathComponent]);
		return NO;
	}
	
	//	Now do the copy, replacing anything that is already there
	if (![manager copyItemAtPath:anItem.path toPath:anItem.destinationPath error:&error]) {
		ALog(@"ERROR:Unable to copy item '%@' to %@\n%@", anItem.name, anItem.destinationPath, error);
		return NO;
	}
	
	return YES;
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
