//
//  MBTSinglePluginController.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 04/10/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBTSinglePluginController.h"

typedef enum {
	kMBTButtonLayoutUpdate = 0,
		//	[hidden]			[Not Now]	[Update]
	kMBTButtonLayoutUpdateIncompatible,
		//	[Disable]			[Not Now]	[Update]
	kMBTButtonLayoutUpdateFutureIncompatible,
		//	[hidden]			[Thanks]	[Update]
	kMBTButtonLayoutIncompatibleOnly,
		//	[Remove]			[Disable]	[Thanks]
	kMBTButtonLayoutFutureIncompatibleOnly
		//	[Disable]			[hidden]	[Thanks]
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
	MBTButtonLayoutType	layout = kMBTButtonLayoutUpdate;
	if (self.mailBundle.hasUpdate) {
		if (self.mailBundle.incompatibleWithCurrentMail) {
			layout = kMBTButtonLayoutUpdateIncompatible;
		}
		else if (self.mailBundle.incompatibleWithFutureMail) {
			layout = kMBTButtonLayoutUpdateFutureIncompatible;
		}
	}
	else if (self.mailBundle.incompatibleWithCurrentMail) {
		layout = kMBTButtonLayoutIncompatibleOnly;
	}
	else {
		layout = kMBTButtonLayoutFutureIncompatibleOnly;
	}
	[self configureButtonsForLayoutType:layout];
	
	//	Configure the text views
	NSString	*mainText = nil;
	NSString	*secondaryText = nil;
	NSArray		*values = nil;
	
	NSDictionary		*boldAttrs = [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Lucida Grande Bold" size:11.0f] forKey:NSFontAttributeName];
	NSAttributedString	*boldPluginName = [[[NSAttributedString alloc] initWithString:self.mailBundle.name attributes:boldAttrs] autorelease];
	
	switch (layout) {
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
			
		case kMBTButtonLayoutUpdateFutureIncompatible:
			mainText = NSLocalizedString(@"There is an update available for this Mail plugin. Would you like to install it?", @"Main text for Update");
			secondaryText = NSLocalizedString(@"The installed version of %1$@ will not be compatible with a future version of Mac OS X (%2$@). You should update before installing that version.", @"Secondary text for Update with Incompatible");
			values = [NSArray arrayWithObjects:boldPluginName, [[[NSAttributedString alloc] initWithString:@"10.8" attributes:boldAttrs] autorelease], nil];
			break;
			
		case kMBTButtonLayoutIncompatibleOnly:
			mainText = NSLocalizedString(@"The Mail plugin %@ is not compatible with this version of Mac OS X.", @"Main text for Incompatible");
			secondaryText = NSLocalizedString(@"Please note that we have no further information about %1$@.", @"Secondary text for Update with Incompatible");
			values = [NSArray arrayWithObject:boldPluginName];
			break;
			
		case kMBTButtonLayoutFutureIncompatibleOnly:
			mainText = NSLocalizedString(@"The Mail plugin %@ will be incompatible with a future known version of Mac OS X.", @"Main text for Future Incompatiblity");
			secondaryText = NSLocalizedString(@"The current version of %1$@ will not be compatible with version %2$@ of Mac OS X.", @"Secondary text for Future Incompatible");
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
		
		NSMutableAttributedString	*visitText = [[[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@" Visit the product site %@ for more information.", @"Visit Product Site Text")] autorelease];
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
//			[aButton sizeToFit];
		}
		
		//	Increment the location value
		location++;
	}
	
	/*
	//	Then adjust the button positions
	CGRect	newFrame = self.rightButton.frame;
	newFrame = LKRectBySettingX(newFrame, ([[self.window contentView] frame].size.width - (newFrame.size.width + EDGE_DISTANCE)));
	self.rightButton.frame = newFrame;

	if (![self.centerButton isHidden]) {
		newFrame = self.centerButton.frame;
		newFrame = LKRectBySettingX(newFrame, (self.rightButton.frame.origin.x - (newFrame.size.width + BETWEEN_DISTANCE)));
		self.centerButton.frame = newFrame;
	}

	if (![self.leftButton isHidden]) {
		newFrame = self.leftButton.frame;
		newFrame = LKRectBySettingX(newFrame, EDGE_DISTANCE);
		self.leftButton.frame = newFrame;
	}
	*/
	
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
								  nil] retain];
	}
	return [[_buttonConfigurations retain] autorelease];
}

@end


