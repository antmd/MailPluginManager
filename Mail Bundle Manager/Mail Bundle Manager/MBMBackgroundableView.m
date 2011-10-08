//
//  MBMBackgroundableView.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 07/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MBMBackgroundableView.h"

@implementation MBMBackgroundableView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
	
	NSString	*imagePath = [[NSBundle bundleWithPath:@"/System/Library/Frameworks/AppKit.framework"] pathForImageResource:@"NSLinenBackgroundPattern"];
	NSImage		*image = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
	
	[[NSColor colorWithPatternImage:image] set];
	NSRectFill(dirtyRect);
}

@end
