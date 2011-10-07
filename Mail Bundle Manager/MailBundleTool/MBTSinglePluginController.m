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
	kMBTButtonLayoutUpdate = 0,
	//	[hidden]			[Not Now]	[Update]
	kMBTButtonLayoutUpdateIncompatible,
	//	[Disable]			[Not Now]	[Update]
	kMBTButtonLayoutUpdateIncompatibleDisabled,
	//	[hidden]			[Not Now]	[Update]
	kMBTButtonLayoutUpdateFutureIncompatible,
	//	[hidden]			[Thanks]	[Update]
	kMBTButtonLayoutIncompatibleOnly,
	//	[Remove]			[Disable]	[Thanks]
	kMBTButtonLayoutIncompatibleOnlyDisabled,
	//	[Remove]			[hidden]	[Thanks]
	kMBTButtonLayoutFutureIncompatibleOnly,
	//	[Disable]			[hidden]	[Thanks]
	kMBTButtonLayoutFutureIncompatibleOnlyDisabled
	//	[hidden]			[hidden]	[Thanks]
} MBTButtonLayoutType;

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

#define EDGE_DISTANCE		20.0f
#define BETWEEN_DISTANCE	12.0f

#define TITLE_KEY		@"title"
#define ACTION_KEY		@"action"


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
	NSString	*mainText = nil;
	NSString	*secondaryText = nil;
	NSArray		*values = nil;
	
	NSDictionary		*boldAttrs = [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Lucida Grande Bold" size:11.0f] forKey:NSFontAttributeName];
	NSAttributedString	*boldPluginName = [[[NSAttributedString alloc] initWithString:self.mailBundle.name attributes:boldAttrs] autorelease];
	
	switch (self.buttonLayout) {
		case kMBTButtonLayoutUpdate:
			mainText = NSLocalizedString(@"There is an update available for this Mail plugin. Would you like to install it?", @"Main text for Update");
			secondaryText = NSLocalizedString(@"Updating now will ensure that you are using the best version of %1$@ for your system.", @"Secondary text for Update Only");
			values = [NSArray arrayWithObject:boldPluginName];
			break;
			
		case kMBTButtonLayoutUpdateIncompatible:
			mainText = NSLocalizedString(@"There is an update available for this Mail plugin. Would you like to install it?", @"Main text for Update");
			secondaryText = NSLocalizedString(@"However the installed version of %1$@ is not compatible with the current version of Mail and will be disabled by Mail.", @"Secondary text for Update with Incompatible");
			values = [NSArray arrayWithObject:boldPluginName];
			break;
			
		case kMBTButtonLayoutUpdateIncompatibleDisabled:
			mainText = NSLocalizedString(@"There is an update available for this Mail plugin. Would you like to install it?", @"Main text for Update");
			secondaryText = NSLocalizedString(@"However the installed version of %1$@ is not compatible with the current version of Mail and has been disabled by Mail.", @"Secondary text for Update with Incompatible - currently disabled");
			values = [NSArray arrayWithObject:boldPluginName];
			break;
			
		case kMBTButtonLayoutUpdateFutureIncompatible:
			mainText = NSLocalizedString(@"There is an update available for this Mail plugin. Would you like to install it?", @"Main text for Update");
			secondaryText = NSLocalizedString(@"The installed version of %1$@ will not be compatible with a future version of Mac OS X (%2$@). You should update before installing that version.", @"Secondary text for Update with Incompatible");
			values = [NSArray arrayWithObjects:boldPluginName, [[[NSAttributedString alloc] initWithString:@"10.8" attributes:boldAttrs] autorelease], nil];
			break;
			
		case kMBTButtonLayoutIncompatibleOnly:
			mainText = NSLocalizedString(@"The Mail plugin %@ is not compatible with this version of Mac OS X.", @"Main text for Incompatible");
			secondaryText = NSLocalizedString(@"The installed version of %1$@ is not compatible with the current version of Mail and will be disabled by Mail. Please note that we have no further information.", @"Secondary text for Update with Incompatible");
			values = [NSArray arrayWithObject:boldPluginName];
			break;
			
		case kMBTButtonLayoutIncompatibleOnlyDisabled:
			mainText = NSLocalizedString(@"The Mail plugin %@ is not compatible with this version of Mac OS X.", @"Main text for Incompatible");
			secondaryText = NSLocalizedString(@"The installed version of %1$@ is not compatible with the current version of Mail and has been disabled by Mail. Please note that we have no further information.", @"Secondary text for Update with Incompatible - currently disabled");
			values = [NSArray arrayWithObject:boldPluginName];
			break;
			
		case kMBTButtonLayoutFutureIncompatibleOnly:
			mainText = NSLocalizedString(@"The Mail plugin %@ will be incompatible with a future known version of Mac OS X.", @"Main text for Future Incompatiblity");
			secondaryText = NSLocalizedString(@"The current version of %1$@ will not be compatible with version %2$@ of Mac OS X.", @"Secondary text for Future Incompatible");
			values = [NSArray arrayWithObjects:boldPluginName, [[[NSAttributedString alloc] initWithString:@"10.8" attributes:boldAttrs] autorelease], nil];
			break;

		case kMBTButtonLayoutFutureIncompatibleOnlyDisabled:
			mainText = NSLocalizedString(@"The Mail plugin %@ will be incompatible with a future known version of Mac OS X.", @"Main text for Future Incompatiblity");
			secondaryText = NSLocalizedString(@"The current version of %1$@ will not be compatible with version %2$@ of Mac OS X. It is also currently disabled.", @"Secondary text for Future Incompatible - currently disabled");
			values = [NSArray arrayWithObjects:boldPluginName, [[[NSAttributedString alloc] initWithString:@"10.8" attributes:boldAttrs] autorelease], nil];
			break;
}
	
	[self.mainDescriptionField setStringValue:[NSString stringWithFormat:mainText, self.mailBundle.name]];

	//	Build the string with attributes from the secondary text and list of values
	NSArray						*stupidArray = [NSArray arrayWithObjects:@"%1$@", @"%2$@", @"%3$@", @"%4$@", nil];
	NSMutableAttributedString	*attrString = [[[NSMutableAttributedString alloc] initWithString:secondaryText] autorelease];
	for (NSString *replacement in stupidArray) {
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

- (IBAction)buttonPressed:(id)sender {
	BOOL			closeWindow = YES;
	MBTButtonActionType	actionType = (MBTButtonActionType)[[[[[self buttonConfigurations] objectAtIndex:self.buttonLayout] objectAtIndex:[sender tag]] valueForKey:ACTION_KEY] integerValue];
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
			[[NSApp delegate] restartMail];
		}
	}
	
	[[NSApp delegate] quittingNowIsReasonable];
	return YES;
}


#pragma mark - Configuration Stuff

- (void)configureButtonsForLayoutType:(MBTButtonLayoutType)layout {
	if (layout >= [self.buttonConfigurations count]) {
		ALog(@"Layout index passed in is too large");
	}
	
	MBTButtonLocation	location = kMBTButtonRight;
	for (NSObject *anObject in [self.buttonConfigurations objectAtIndex:layout]) {
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
		
		_buttonConfigurations = [[NSArray arrayWithObjects:
								  //	kMBTButtonLayoutUpdate
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
								   nil],
								  //	kMBTButtonLayoutUpdateIncompatible
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
								   nil],
								  //	kMBTButtonLayoutUpdateIncompatibleDisabled
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
								   nil],
								  //	kMBTButtonLayoutUpdateFutureIncompatible
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
								   nil],
								  //	kMBTButtonLayoutIncompatibleOnly
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
								   nil],
								  //	kMBTButtonLayoutIncompatibleOnlyDisabled
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
								   nil],
								  //	kMBTButtonLayoutFutureIncompatibleOnly
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
								   nil],
								  //	kMBTButtonLayoutFutureIncompatibleOnlyDisabled
								  [NSArray arrayWithObjects:
								   [NSDictionary dictionaryWithObjectsAndKeys:
									thanksString, TITLE_KEY,
									[NSNumber numberWithInteger:kMBTActionThanks], ACTION_KEY,
									nil],
								   [NSNull null],
								   [NSNull null],
								   nil],
								  nil] retain];
	}
	return [[_buttonConfigurations retain] autorelease];
}

@end


