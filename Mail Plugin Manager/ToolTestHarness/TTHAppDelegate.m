//
//  TTHAppDelegate.m
//  ToolTestHarness
//
//  Created by Scott Little on 10/11/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "TTHAppDelegate.h"
#define MODULE_CLASS [self class]
#import	"MPTPluginMacros.h"


@implementation TTHAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	
	MPTResultNotificationBlock myBlock = ^(NSDictionary *object) {
		NSLog(@"\n\nThe returned object is:%@\n\n", object);
	};
	
	NSBundle *mailBundle = [NSBundle bundleWithPath:@"/Users/scott/Library/Mail/Bundles/ExamplePlugin.mailbundle"];

//	MPTCallToolCommandForBundleWithBlock2(MPT_SEND_MAIL_INFO_TEXT, mailBundle, myBlock);
//	MPTCallToolCommandForBundleWithBlock2(MPT_SEND_UUID_LIST_TEXT, mailBundle, myBlock);

//	MPTLaunchCommandForBundle2(@"update", mailBundle, YES, nil);

	MPTMailInformationForBundleWithBlock(mailBundle, myBlock);
//	MPTUUIDListForBundleWithBlock(mailBundle, myBlock);
	
//	MPTUninstallForBundle(mailBundle);
	
//	MPTUpdateAndSendReportsForBundleNow(mailBundle);
	NSBundle *sisBundle = [NSBundle bundleWithPath:@"/Users/scott/Library/Mail/Bundles/Sidebar for Infusionsoft.mailbundle"];
//	MPTCheckForUpdatesForBundle(sisBundle);
//	MPTUninstallForBundle(sisBundle);
	MPTSendCrashReportsForBundle(sisBundle);
//	MPTSendCrashReportsForBundle(mailBundle);
	
	double delayInSeconds = 10.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[NSApp terminate:nil];
	});
}

@end
