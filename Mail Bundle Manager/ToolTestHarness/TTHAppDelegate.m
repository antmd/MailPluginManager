//
//  TTHAppDelegate.m
//  ToolTestHarness
//
//  Created by Scott Little on 10/11/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "TTHAppDelegate.h"
#import	"MBMPluginMacros.h"

@implementation TTHAppDelegate

@synthesize window = _window;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
	
	MBMResultNotificationBlock myBlock = ^(NSDictionary *object) {
		NSLog(@"\n\nThe returned object is:%@\n\n", object);
	};
	
	NSBundle *mailBundle = [NSBundle bundleWithPath:@"/Users/scott/Library/Mail/Bundles/ExamplePlugin.mailbundle"];

//	MBMMailInformationForBundleWithBlock(mailBundle, myBlock);
	MBMUUIDListForBundleWithBlock(mailBundle, myBlock);
	
}

@end
