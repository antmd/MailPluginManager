//
//  MBMAnimatedListController.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 20/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBMAnimatedListController.h"

#import "LKCGStructs.h"

#define TEXT_FIELD_X		0.0f
#define TEXT_FIELD_Y		0.0f
#define TEXT_FIELD_WIDTH	100.0f
#define TEXT_FIELD_HEIGHT	23.0f
#define TEXT_FIELD_OFFSET	10.0f


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
		NSArray			*titleArray = (NSArray *)[self representedObject];
		NSMutableArray	*textList = [NSMutableArray arrayWithCapacity:[titleArray count]];
		NSRect			fieldFrame = NSMakeRect(TEXT_FIELD_X, TEXT_FIELD_Y, TEXT_FIELD_WIDTH, TEXT_FIELD_HEIGHT);
		for (NSDictionary *itemDict in titleArray) {
			NSTextField		*aField = [[[NSTextField alloc] initWithFrame:fieldFrame] autorelease];
			NSString	*aTitle = [itemDict valueForKey:kMBMConfirmationBulletTitleKey];
			if (aTitle == nil) {
				aTitle = [itemDict valueForKey:kMBMConfirmationTitleKey];
			}
			[aField setStringValue:aTitle];
			[aField setAlignment:NSLeftTextAlignment];
			[aField setTextColor:[NSColor blackColor]];
			
			//	Add the view to our internal list and to the main view
			[textList addObject:aField];
			[[self view] addSubview:aField];
			
			//	Adjust the frame for another field, if needed
			fieldFrame = LKRectByOffsettingX(fieldFrame, TEXT_FIELD_OFFSET);
		}
		
		//	Create a dummy animator view for the moment that shows the step
		NSTextField	*animatorView = [[[NSTextField alloc] initWithFrame:NSMakeRect(10.0f, 200.0f, 25.0f, 23.0f)] autorelease];
		[animatorView setTextColor:[NSColor redColor]];
		[animatorView setAlignment:NSCenterTextAlignment];
		self.animatorView = animatorView;
		[[self view] addSubview:animatorView];
		
		//	Set the selected step to the first by default
		self.selectedStep = 0;
		
    
	}
    
    return self;
}


- (void)setSelectedStep:(NSInteger)aSelectedStep {
	if (_selectedStep != aSelectedStep) {
		[(NSTextField *)self.animatorView setIntegerValue:aSelectedStep];
		_selectedStep = aSelectedStep;
	}
}

@end
