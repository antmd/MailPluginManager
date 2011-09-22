//
//  MBMAnimatedListController.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 20/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBMAnimatedListController.h"

#import "LKCGStructs.h"

#define TEXT_FIELD_X			10.0f
#define TEXT_FIELD_WIDTH		150.0f
#define TEXT_FIELD_HEIGHT		23.0f
#define TEXT_FIELD_TOP_OFFSET	25.0f
#define TEXT_FIELD_OFFSET		10.0f
#define ANIMATOR_VIEW_X			0.0f
#define ANIMATOR_TOP_START		19.0f
#define ANIMATOR_VIEW_WIDTH		210.0f
#define ANIMATOR_VIEW_HEIGHT	30.0f
#define ANIMATOR_TOP_OFFSET		4.0f

#define TEXT_UNSELECTED_COLOR	[NSColor colorWithDeviceWhite:0.323 alpha:1.000]
#define TEXT_SELECTED_COLOR		[NSColor colorWithDeviceWhite:0.945 alpha:1.000]


@interface MBMAnimatedListController ()
- (void)animateMarkerFromItem:(NSInteger)fromItem toItem:(NSInteger)toItem;
@end

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
		NSImageView	*animatorBGView = [[NSImageView alloc] initWithFrame:NSMakeRect(ANIMATOR_VIEW_X, aView.frame.size.height - (ANIMATOR_TOP_START + ANIMATOR_VIEW_HEIGHT), ANIMATOR_VIEW_WIDTH, ANIMATOR_VIEW_HEIGHT)];
		[animatorBGView setImage:[NSImage imageNamed:kMBMAnimationBackgroundImageName]];
		[animatorBGView setImageScaling:NSScaleNone];
		[[self view] addSubview:animatorBGView];
		_animatorView = animatorBGView;
		
		//	Create the text subviews
		NSArray			*titleArray = (NSArray *)[self representedObject];
		NSMutableArray	*textList = [NSMutableArray arrayWithCapacity:[titleArray count]];
		NSRect			fieldFrame = NSMakeRect(TEXT_FIELD_X, (aView.frame.size.height - (TEXT_FIELD_TOP_OFFSET + TEXT_FIELD_HEIGHT)), TEXT_FIELD_WIDTH, TEXT_FIELD_HEIGHT);
		for (NSDictionary *itemDict in titleArray) {
			NSTextField		*aField = [[[NSTextField alloc] initWithFrame:fieldFrame] autorelease];
			
			/*
			CATextLayer	*textLayer = [CATextLayer layer];
			[aField setLayer:textLayer];
			

			textLayer.string = [itemDict valueForKey:kMBMConfirmationLocalizedTitleKey];
			textLayer.alignmentMode = NSLeftTextAlignment;
			textLayer.fontSize = 16.0f;
			textLayer.opaque = YES;

			CGColorRef color = CGColorCreateGenericRGB(0.267, 0.271, 0.278, 1.000);
			textLayer.foregroundColor = color;
			CGColorRelease(color);
			color = CGColorCreateGenericGray(1.000, 0.000);
			textLayer.backgroundColor = color;
			CGColorRelease(color);
			
			[aField setWantsLayer:YES];
			*/

			[aField setStringValue:[itemDict valueForKey:kMBMConfirmationLocalizedTitleKey]];
			[aField setAlignment:NSLeftTextAlignment];
			[aField setTextColor:TEXT_UNSELECTED_COLOR];
			[aField setFont:[NSFont systemFontOfSize:16.0f]];
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
		[self animateMarkerFromItem:_selectedStep toItem:aSelectedStep];
		_selectedStep = aSelectedStep;
	}
}

- (void)animateMarkerFromItem:(NSInteger)fromItem toItem:(NSInteger)toItem {
	
	//	Try to get our respective views
	NSTextField	*fromField = nil;
	NSTextField	*toField = nil;
	if ((fromItem != kMBMInvalidStep) && ([self.subviewList count] > (NSUInteger)fromItem)) {
		fromField = [self.subviewList objectAtIndex:fromItem];
	}
	if ([self.subviewList count] > (NSUInteger)toItem) {
		toField = [self.subviewList objectAtIndex:toItem];
	}
	
	//	If we don't have at least the to view, there is nothing to do
	if (toField == nil) {
		return;
	}
	
	//	Set the toField color properly
	[toField setTextColor:TEXT_SELECTED_COLOR];
	
	//	Set the fromField color, if there is a field
	if (fromField) {
		[fromField setTextColor:TEXT_UNSELECTED_COLOR];
	}
	
	//	Move the marker background view
	CGFloat	offsetCount = (toItem > fromItem)?-1.0f:1.0f;
	if (fromItem == kMBMInvalidStep) {
		offsetCount = 0.0f;
	}
	CGRect	aRect = LKRectByOffsettingY(self.animatorView.frame, (offsetCount * (ANIMATOR_VIEW_HEIGHT + ANIMATOR_TOP_OFFSET)));
	[[self.animatorView animator] setFrame:aRect];
	
}

@end
