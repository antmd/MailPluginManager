//
//  MBMAnimatedListController.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 20/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBMAnimatedListController.h"

#import "LKCGStructs.h"

#define TEXT_FIELD_X			20.0f
#define TEXT_FIELD_WIDTH		150.0f
#define TEXT_FIELD_HEIGHT		23.0f
#define TEXT_FIELD_TOP_OFFSET	25.0f
#define TEXT_FIELD_OFFSET		10.0f
#define ANIMATOR_VIEW_X			2.0f
#define ANIMATOR_TOP_OFFSET		19.0f
#define ANIMATOR_VIEW_WIDTH		200.0f
#define ANIMATOR_VIEW_HEIGHT	30.0f


@implementation MBMAnimatedListController

@synthesize subviewList = _subviewList;
@synthesize animatorView = _animatorView;
@synthesize selectedStep = _selectedStep;

- (id)initWithContentList:(NSArray *)aContentList inView:(NSView *)aView {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        //	Set the values from the passed in arguments
		[self setView:aView];
		[self setRepresentedObject:aContentList];

		//	Create the view hierarchy
		//	Create the animator view for the moment that shows the step
		NSImageView	*animatorBGView = [[NSImageView alloc] initWithFrame:NSMakeRect(ANIMATOR_VIEW_X, aView.frame.size.height - (ANIMATOR_TOP_OFFSET + ANIMATOR_VIEW_HEIGHT), ANIMATOR_VIEW_WIDTH, ANIMATOR_VIEW_HEIGHT)];
		[animatorBGView setImage:[NSImage imageNamed:kMBMAnimationBackgroundImageName]];
		[[self view] addSubview:animatorBGView];
		_animatorView = animatorBGView;
		
		//	Create the text subviews
		NSArray			*titleArray = (NSArray *)[self representedObject];
		NSMutableArray	*textList = [NSMutableArray arrayWithCapacity:[titleArray count]];
		NSRect			fieldFrame = NSMakeRect(TEXT_FIELD_X, (aView.frame.size.height - (TEXT_FIELD_TOP_OFFSET + TEXT_FIELD_HEIGHT)), TEXT_FIELD_WIDTH, TEXT_FIELD_HEIGHT);
		for (NSDictionary *itemDict in titleArray) {
			NSTextField		*aField = [[[NSTextField alloc] initWithFrame:fieldFrame] autorelease];
			[aField setStringValue:[itemDict valueForKey:kMBMConfirmationLocalizedTitleKey]];
			[aField setAlignment:NSLeftTextAlignment];
			[aField setTextColor:[NSColor blackColor]];
			[aField setBackgroundColor:[NSColor clearColor]];
			[aField setEditable:NO];
			[aField setBezeled:NO];
			[aField setBordered:NO];
			
			//	Add the view to our internal list and to the main view
			[textList addObject:aField];
			[[self view] addSubview:aField];
			
			//	Adjust the frame for another field, if needed
			fieldFrame = LKRectByOffsettingY(fieldFrame, -1.0f * (TEXT_FIELD_HEIGHT + TEXT_FIELD_OFFSET));
		}
		_subviewList = [[NSArray arrayWithArray:textList] retain];
		
		//	Set to unreasonable value for init
		self.selectedStep = kMBMInvalidStep;
		
    
	}
    
    return self;
}


- (void)setSelectedStep:(NSInteger)aSelectedStep {
	if (_selectedStep != aSelectedStep) {
		_selectedStep = aSelectedStep;
	}
}

@end
