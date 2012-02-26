//
//  MBMAnimatedListController.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 20/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kMBMInvalidStep	((NSUInteger)-1)

@interface MBMAnimatedListController : NSViewController {
@private	
	NSArray		*_subviewList;
	NSView		*_animatorView;
	NSUInteger	_selectedStep;
}
@property	(nonatomic, copy)	NSArray		*subviewList;
@property	(nonatomic, retain)	NSView		*animatorView;
@property	(nonatomic, assign)	NSUInteger	selectedStep;

- (id)initWithContentList:(NSArray *)aContentList inView:(NSView *)aView;
@end
