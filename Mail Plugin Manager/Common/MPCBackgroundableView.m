//
//  MPCBackgroundableView.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 07/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MPCBackgroundableView.h"

@implementation MPCBackgroundableView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
	
	NSString	*imagePath = [[NSBundle mainBundle] pathForImageResource:kMBMWindowBackgroundImageName];
	NSImage		*image = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
	
	[[NSColor colorWithPatternImage:image] set];
	NSRectFill(dirtyRect);
}

@end
