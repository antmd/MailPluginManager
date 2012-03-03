//
//  TTHAppDelegate.h
//  ToolTestHarness
//
//  Created by Scott Little on 10/11/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TTHAppDelegate : NSObject <NSApplicationDelegate> {
	NSWindow	*_window;
}

@property (assign) IBOutlet NSWindow *window;

@end
