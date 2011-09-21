//
//  MBMAnimatedListController.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 20/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MBMAnimatedListController : NSViewController
@property	(nonatomic, copy)	NSArray		*subviewList;
@property	(nonatomic, retain)	NSView		*animatorView;
@property	(nonatomic, assign)	NSInteger	selectedStep;

- (id)initWithContentList:(NSArray *)aContentList inView:(NSView *)aView;
@end
