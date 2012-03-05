//
//  MBTSinglePluginController.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 04/10/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBTSinglePluginController.h"
#import "MBTAppDelegate.h"

typedef enum {
	kMBTButtonRight = 0,
	kMBTButtonCenter,
	kMBTButtonLeft
} MBTButtonLocation;

typedef enum {
	kMBTActionUpdate = 0,
	kMBTActionDisable,
	kMBTActionRemove,
	kMBTActionThanks,
	kMBTActionNotNow
} MBTButtonActionType;

//	Configuration Dictionary Keys
#define TITLE_KEY			@"title"
#define ACTION_KEY			@"action"
#define MAIN_TEXT_KEY		@"mainText"
#define SECONDARY_TEXT_KEY	@"secondaryText"
#define BUTTON_LIST_KEY		@"buttonList"



@interface MBTSinglePluginController ()
@property	(assign)	MBTButtonLayoutType	buttonLayout;
@property	(retain, readonly)	NSArray		*buttonConfigurations;

- (BOOL)confirmAndPerformAction:(MBTButtonActionType)actionType;
- (void)configureButtonsForLayoutType:(MBTButtonLayoutType)layout;
@end

@implementation MBTSinglePluginController

#pragma mark - Accessors

@synthesize buttonLayout = _buttonLayout;
@synthesize buttonConfigurations = _buttonConfigurations;

@synthesize mailBundle = _mailBundle;
@synthesize mainDescriptionField = _mainDescriptionField;
@synthesize secondaryTextField = _secondaryTextField;
@synthesize rightButton = _rightButton;
@synthesize centerButton = _centerButton;
@synthesize leftButton = _leftButton;


#pragma mark - Memory Management

- (id)initWithMailBundle:(MBMMailBundle *)aMailBundle {
    self = [super initWithWindowNibName:@"MBTSinglePluginWindow"];
    if (self) {
        // Initialization code here.
		_mailBundle = [aMailBundle retain];
		_buttonConfigurations = nil;
		
    }
    
    return self;
}

- (void)dealloc {
	//	Remove observers
	[_buttonConfigurations release];
	_buttonConfigurations = nil;
	self.mailBundle = nil;
	
	[super dealloc];
}


#pragma mark - Window Management

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	
	//	Set up the data for the window
	//	Buttons first
	self.buttonLayout = kMBTButtonLayoutUpdate;
	if (self.mailBundle.hasUpdate) {
		if (self.mailBundle.incompatibleWithCurrentMail) {
			self.buttonLayout = self.mailBundle.enabled?kMBTButtonLayoutUpdateIncompatible:kMBTButtonLayoutUpdateIncompatibleDisabled;
		}
		else if (self.mailBundle.incompatibleWithFutureMail) {
			self.buttonLayout = kMBTButtonLayoutUpdateFutureIncompatible;
		}
	}
	else {
		if (self.mailBundle.incompatibleWithCurrentMail) {
			self.buttonLayout = kMBTButtonLayoutIncompatibleOnly;
		}
		else {
			self.buttonLayout = kMBTButtonLayoutFutureIncompatibleOnly;
		}
		
		//	If it is disabled move that value up by one
		if (!self.mailBundle.enabled) {
			self.buttonLayout++;
		}
	}
	[self configureButtonsForLayoutType:self.buttonLayout];
	
	//	Configure the text views
	NSDictionary	*configurationDict = [[self buttonConfigurations] objectAtIndex:self.buttonLayout];
	NSString	*mainText = [configurationDict valueForKey:MAIN_TEXT_KEY];
	NSString	*secondaryText = [configurationDict valueForKey:SECONDARY_TEXT_KEY];
	NSArray		*values = nil;
	
	NSDictionary		*boldAttrs = [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Lucida Grande Bold" size:11.0f] forKey:NSFontAttributeName];
	NSAttributedString	*boldPluginName = [[[NSAttributedString alloc] initWithString:self.mailBundle.name attributes:boldAttrs] autorelease];
	
	switch (self.buttonLayout) {
		case kMBTButtonLayoutUpdate:
		case kMBTButtonLayoutUpdateIncompatible:
		case kMBTButtonLayoutUpdateIncompatibleDisabled:
		case kMBTButtonLayoutIncompatibleOnly:
		case kMBTButtonLayoutIncompatibleOnlyDisabled:
			values = [NSArray arrayWithObject:boldPluginName];
			break;
			
		case kMBTButtonLayoutUpdateFutureIncompatible:
		case kMBTButtonLayoutFutureIncompatibleOnly:
		case kMBTButtonLayoutFutureIncompatibleOnlyDisabled:
			values = [NSArray arrayWithObjects:boldPluginName, [[[NSAttributedString alloc] initWithString:[self.mailBundle firstOSVersionUnsupported] attributes:boldAttrs] autorelease], nil];
			break;
			
	}
	
	[self.mainDescriptionField setStringValue:[NSString stringWithFormat:mainText, self.mailBundle.name]];

	//	Build the string with attributes from the secondary text and list of values
	NSArray						*replacementArray = [NSArray arrayWithObjects:@"%1$@", @"%2$@", @"%3$@", @"%4$@", nil];
	NSMutableAttributedString	*attrString = [[[NSMutableAttributedString alloc] initWithString:secondaryText] autorelease];
	for (NSString *replacement in replacementArray) {
		NSRange		aRange = [[attrString string] rangeOfString:replacement];
		NSInteger	idx = [[replacement substringWithRange:NSMakeRange(1, 1)] integerValue] - 1;
		if ((idx >= 0) && (idx < (NSInteger)[values count])) {
			[attrString replaceCharactersInRange:aRange withAttributedString:[values objectAtIndex:idx]];
		}
	}
	
	//	build the visit text as an attributed string
	if (self.mailBundle.productURL || self.mailBundle.companyURL) {

		NSString					*urlString = self.mailBundle.productURL?self.mailBundle.productURL:self.mailBundle.companyURL;
		NSDictionary				*urlAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
												 [NSURL URLWithString:urlString], NSLinkAttributeName,
												 [NSColor blueColor], NSForegroundColorAttributeName,
												 [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName,
												 nil];
		NSAttributedString			*attrURL = [[[NSAttributedString alloc] initWithString:urlString attributes:urlAttrs] autorelease];
		
		NSMutableAttributedString	*visitText = [[[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@" Visit the product site %@ to see if there is more information.", @"Visit Product Site Text")] autorelease];
		[visitText replaceCharactersInRange:[[visitText string] rangeOfString:@"%@"] withAttributedString:attrURL];

		//	Then add it
		[attrString appendAttributedString:visitText];
		
		[self.secondaryTextField setAllowsEditingTextAttributes:NO];
		[self.secondaryTextField setSelectable:NO];
		[self.secondaryTextField setEditable:NO];
	}
	
	//	Then set the field
	[self.secondaryTextField setAttributedStringValue:attrString];
	
	//	Set the window title explicitly
	[self.window setTitle:NSLocalizedString(@"Issue with Mail Plugin", @"Window title indicating there is an issue with a plugin")];
}


#pragma mark - Actions & Watchers

- (IBAction)buttonPressed:(id)sender {
	BOOL			closeWindow = YES;
	MBTButtonActionType	actionType = (MBTButtonActionType)[[[[[[self buttonConfigurations] objectAtIndex:self.buttonLayout] valueForKey:BUTTON_LIST_KEY] objectAtIndex:[sender tag]] valueForKey:ACTION_KEY] integerValue];
	switch (actionType) {
		case kMBTActionNotNow:
		case kMBTActionThanks:
			[[NSApp delegate] quittingNowIsReasonable];
			break;
			
		case kMBTActionDisable:
		case kMBTActionRemove:
			closeWindow = [self confirmAndPerformAction:actionType];
			break;
			
		case kMBTActionUpdate:
			[self.mailBundle updateIfNecessary];
			break;
			
		default:
			break;
	}
	
	if (closeWindow) {
		[[self window] close];
	}
}

- (BOOL)confirmAndPerformAction:(MBTButtonActionType)actionType {

	//	Set up strings
	NSString	*messageText = nil;
	NSString	*confirmButton = nil;
	NSString	*infoText = nil;
	NSString	*disableFolder = [MBMMailBundle disabledBundleFolderName];
	switch (actionType) {
		case kMBTActionDisable:
			messageText = NSLocalizedString(@"Are you sure you want to disable %@?", @"");
			confirmButton = NSLocalizedString(@"Disable", @"");
			infoText = NSLocalizedString(@"%1$@ will be moved into '%2$@'.", @"");
			break;
			
		case kMBTActionRemove:
			messageText = NSLocalizedString(@"Are you sure you want to remove %@?", @"");
			confirmButton = NSLocalizedString(@"Remove", @"");
			infoText = NSLocalizedString(@"%1$@ will be placed in the Trash.", @"");
			if ([MBMMailBundle latestDisabledBundlesPathShouldCreate:NO]) {
				disableFolder = [[MBMMailBundle latestDisabledBundlesPathShouldCreate:NO] lastPathComponent];
			}
			break;
			
		default:
			break;
	}
	
	NSAlert	*confirm = [NSAlert alertWithMessageText:[NSString stringWithFormat:messageText, self.mailBundle.name]
									   defaultButton:confirmButton
									 alternateButton:NSLocalizedString(@"Cancel", @"")
										 otherButton:nil
						   informativeTextWithFormat:[NSString stringWithFormat:infoText, self.mailBundle.name, disableFolder]];
	[confirm setIcon:self.mailBundle.icon];
	
	//	If they canceled return FALSE
	if ([confirm runModal] != NSAlertDefaultReturn) {
		return NO;
	}
	
	//	Perform the action
	if (actionType == kMBTActionDisable) {
		LKLog(@"Would be disabling the plugin");
		//			self.mailBundle.enabled = NO;
	}
	else if (actionType == kMBTActionRemove) {
		LKLog(@"Would be removing the plugin");
		//			self.mailBundle.installed = NO;
	}

	//	New Alert to tell them we did it? and restart mail
	switch (actionType) {
		case kMBTActionDisable:
			messageText = NSLocalizedString(@"Plugin %@ was successfully disabled.", @"");
			break;
			
		case kMBTActionRemove:
			messageText = NSLocalizedString(@"Plugin %@ was successfully moved to the Trash.", @"");
			break;
			
		default:
			break;
	}
	NSString	*alternateButton = nil;
	NSImage		*iconImage = nil;
	confirmButton = nil;
	infoText = @"";
	if ([[NSApp delegate] isMailRunning]) {
		confirmButton = NSLocalizedString(@"Restart Mail", @"");
		alternateButton = NSLocalizedString(@"Later", @"");
		infoText = NSLocalizedString(@"You will need to restart Mail to see the changes.", @"");
		iconImage = self.mailBundle.icon;
	}
	//	Build a new alert
	confirm = [NSAlert alertWithMessageText:[NSString stringWithFormat:messageText, self.mailBundle.name]
									   defaultButton:confirmButton
									 alternateButton:alternateButton
										 otherButton:nil
						   informativeTextWithFormat:infoText];
	[confirm setIcon:iconImage];
	//	And show it
	if ([confirm runModal] == NSAlertDefaultReturn) {
		//	If we have an alternate button, then they asked to restart Mail
		if (alternateButton != nil) {
			[AppDel restartMailWithBlock:nil];
//			[[NSApp delegate] restartMail:self];
		}
	}
	
	[[NSApp delegate] quittingNowIsReasonable];
	return YES;
}


#pragma mark - Configuration Methods

- (void)configureButtonsForLayoutType:(MBTButtonLayoutType)layout {
	if (layout >= [self.buttonConfigurations count]) {
		ALog(@"Layout index passed in is too large");
	}
	
	MBTButtonLocation	location = kMBTButtonRight;
	for (NSObject *anObject in [[self.buttonConfigurations objectAtIndex:layout] valueForKey:BUTTON_LIST_KEY]) {
		//	get the button
		NSButton	*aButton = nil;
		switch (location) {
			case kMBTButtonRight:
				aButton = self.rightButton;
				break;
				
			case kMBTButtonCenter:
				aButton = self.centerButton;
				break;
				
			case kMBTButtonLeft:
				aButton = self.leftButton;
				break;
				
			default:
				break;
		}
		
		//	Configure the button
		if ([anObject isEqual:[NSNull null]]) {
			//	Hide the button
			[aButton setHidden:YES];
		}
		else {
			NSDictionary	*dict = (NSDictionary *)anObject;
			[aButton setHidden:NO];
			aButton.title = [dict valueForKey:TITLE_KEY];
		}
		
		//	Increment the location value
		location++;
	}
	
}

- (NSArray *)buttonConfigurations {
	if (_buttonConfigurations == nil) {
		
		//	Prelocalized strings
		NSString	*updateString = NSLocalizedString(@"Update", @"Update button text");
		NSString	*disableString = NSLocalizedString(@"Disable", @"Disable button text");
		NSString	*removeString = NSLocalizedString(@"Remove", @"Remove button text");
		NSString	*thanksString = NSLocalizedString(@"Thanks", @"Thanks button text");
		NSString	*notNowString = NSLocalizedString(@"Not Now", @"Not Now button text");
		
		
		NSString	*updateAvailableText = NSLocalizedString(@"There is an update available for this Mail plugin. Would you like to install it?", @"Main text for Update");
		NSString	*incompatibleText = NSLocalizedString(@"The Mail plugin %@ is not compatible with this version of Mac OS X.", @"Main text for Incompatible");
		NSString	*futureIncompatibleText  = NSLocalizedString(@"The Mail plugin %@ will be incompatible with a future known version of Mac OS X.", @"Main text for Future Incompatiblity");

		
		_buttonConfigurations = [[NSArray arrayWithObjects:
								  //	kMBTButtonLayoutUpdate
								  [NSDictionary dictionaryWithObjectsAndKeys:
								   updateAvailableText, MAIN_TEXT_KEY,
								   (NSLocalizedString(@"Updating now will ensure that you are using the best version of %1$@ for your system.", @"Secondary text for Update Only")), SECONDARY_TEXT_KEY,
								   [NSArray arrayWithObjects:
									[NSDictionary dictionaryWithObjectsAndKeys:
									 updateString, TITLE_KEY,
									 [NSNumber numberWithInteger:kMBTActionUpdate], ACTION_KEY,
									 nil],
									[NSDictionary dictionaryWithObjectsAndKeys:
									 notNowString, TITLE_KEY,
									 [NSNumber numberWithInteger:kMBTActionNotNow], ACTION_KEY,
									 nil],
									[NSNull null],
									nil], BUTTON_LIST_KEY,
								   nil],
								  //	kMBTButtonLayoutUpdateIncompatible
								  [NSDictionary dictionaryWithObjectsAndKeys:
								   updateAvailableText, MAIN_TEXT_KEY,
								   (NSLocalizedString(@"Note that the installed version of %1$@ is not compatible with the current version of Mail and will be disabled by Mail.", @"Secondary text for Update with Incompatible")), SECONDARY_TEXT_KEY,
								   [NSArray arrayWithObjects:
									[NSDictionary dictionaryWithObjectsAndKeys:
									 updateString, TITLE_KEY,
									 [NSNumber numberWithInteger:kMBTActionUpdate], ACTION_KEY,
									 nil],
									[NSDictionary dictionaryWithObjectsAndKeys:
									 notNowString, TITLE_KEY,
									 [NSNumber numberWithInteger:kMBTActionNotNow], ACTION_KEY,
									 nil],
									[NSDictionary dictionaryWithObjectsAndKeys:
									 disableString, TITLE_KEY,
									 [NSNumber numberWithInteger:kMBTActionDisable], ACTION_KEY,
									 nil],
									nil], BUTTON_LIST_KEY,
								   nil],
								  //	kMBTButtonLayoutUpdateIncompatibleDisabled
								  [NSDictionary dictionaryWithObjectsAndKeys:
								   updateAvailableText, MAIN_TEXT_KEY,
								    (NSLocalizedString(@"Note that the installed version of %1$@ is not compatible with the current version of Mail and has been disabled by Mail.", @"Secondary text for Update with Incompatible - currently disabled")), SECONDARY_TEXT_KEY,
								   [NSArray arrayWithObjects:
									[NSDictionary dictionaryWithObjectsAndKeys:
									 updateString, TITLE_KEY,
									 [NSNumber numberWithInteger:kMBTActionUpdate], ACTION_KEY,
									 nil],
									[NSDictionary dictionaryWithObjectsAndKeys:
									 notNowString, TITLE_KEY,
									 [NSNumber numberWithInteger:kMBTActionNotNow], ACTION_KEY,
									 nil],
									[NSNull null],
									nil], BUTTON_LIST_KEY,
								   nil],
								  //	kMBTButtonLayoutUpdateFutureIncompatible
								  [NSDictionary dictionaryWithObjectsAndKeys:
								   updateAvailableText, MAIN_TEXT_KEY,
								   (NSLocalizedString(@"The installed version of %1$@ will not be compatible with a future version of Mac OS X (%2$@). You should update before installing that version.", @"Secondary text for Update with Incompatible")), SECONDARY_TEXT_KEY,
								   [NSArray arrayWithObjects:
									[NSDictionary dictionaryWithObjectsAndKeys:
									 updateString, TITLE_KEY,
									 [NSNumber numberWithInteger:kMBTActionUpdate], ACTION_KEY,
									 nil],
									[NSDictionary dictionaryWithObjectsAndKeys:
									 thanksString, TITLE_KEY,
									 [NSNumber numberWithInteger:kMBTActionThanks], ACTION_KEY,
									 nil],
									[NSNull null],
									nil], BUTTON_LIST_KEY,
								   nil],
								  //	kMBTButtonLayoutIncompatibleOnly
								  [NSDictionary dictionaryWithObjectsAndKeys:
								   incompatibleText, MAIN_TEXT_KEY,
								   (NSLocalizedString(@"The installed version of %1$@ is not compatible with the current version of Mail and will be disabled by Mail. Please note that we have no further information.", @"Secondary text for Update with Incompatible")), SECONDARY_TEXT_KEY,
								   [NSArray arrayWithObjects:
									[NSDictionary dictionaryWithObjectsAndKeys:
									 thanksString, TITLE_KEY,
									 [NSNumber numberWithInteger:kMBTActionThanks], ACTION_KEY,
									 nil],
									[NSDictionary dictionaryWithObjectsAndKeys:
									 disableString, TITLE_KEY,
									 [NSNumber numberWithInteger:kMBTActionDisable], ACTION_KEY,
									 nil],
									[NSDictionary dictionaryWithObjectsAndKeys:
									 removeString, TITLE_KEY,
									 [NSNumber numberWithInteger:kMBTActionRemove], ACTION_KEY,
									 nil],
									nil], BUTTON_LIST_KEY,
								   nil],
								  //	kMBTButtonLayoutIncompatibleOnlyDisabled
								  [NSDictionary dictionaryWithObjectsAndKeys:
								   incompatibleText, MAIN_TEXT_KEY,
								   (NSLocalizedString(@"Note that the installed version of %1$@ is not compatible with the current version of Mail and has been disabled by Mail. Sorry, no further information is available.", @"Secondary text for Update with Incompatible - currently disabled")), SECONDARY_TEXT_KEY,
								   [NSArray arrayWithObjects:
									[NSDictionary dictionaryWithObjectsAndKeys:
									 thanksString, TITLE_KEY,
									 [NSNumber numberWithInteger:kMBTActionThanks], ACTION_KEY,
									 nil],
									[NSNull null],
									[NSDictionary dictionaryWithObjectsAndKeys:
									 removeString, TITLE_KEY,
									 [NSNumber numberWithInteger:kMBTActionRemove], ACTION_KEY,
									 nil],
									nil], BUTTON_LIST_KEY,
								   nil],
								  //	kMBTButtonLayoutFutureIncompatibleOnly
								  [NSDictionary dictionaryWithObjectsAndKeys:
								   futureIncompatibleText, MAIN_TEXT_KEY,
								   (NSLocalizedString(@"The current version of %1$@ will not be compatible with version %2$@ of Mac OS X.", @"Secondary text for Future Incompatible")), SECONDARY_TEXT_KEY,
								   [NSArray arrayWithObjects:
									[NSDictionary dictionaryWithObjectsAndKeys:
									 thanksString, TITLE_KEY,
									 [NSNumber numberWithInteger:kMBTActionThanks], ACTION_KEY,
									 nil],
									[NSNull null],
									[NSDictionary dictionaryWithObjectsAndKeys:
									 disableString, TITLE_KEY,
									 [NSNumber numberWithInteger:kMBTActionDisable], ACTION_KEY,
									 nil],
									nil], BUTTON_LIST_KEY,
								   nil],
								  //	kMBTButtonLayoutFutureIncompatibleOnlyDisabled
								  [NSDictionary dictionaryWithObjectsAndKeys:
								   futureIncompatibleText, MAIN_TEXT_KEY,
								   (NSLocalizedString(@"The current version of %1$@ will not be compatible with version %2$@ of Mac OS X. It is also currently disabled.", @"Secondary text for Future Incompatible - currently disabled")), SECONDARY_TEXT_KEY,
								   [NSArray arrayWithObjects:
									[NSDictionary dictionaryWithObjectsAndKeys:
									 thanksString, TITLE_KEY,
									 [NSNumber numberWithInteger:kMBTActionThanks], ACTION_KEY,
									 nil],
									[NSNull null],
									[NSNull null],
									nil], BUTTON_LIST_KEY,
								   nil],
								  nil] retain];
	}
	return [[_buttonConfigurations retain] autorelease];
}

@end


