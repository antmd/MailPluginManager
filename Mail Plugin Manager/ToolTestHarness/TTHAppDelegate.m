//
//  TTHAppDelegate.m
//  ToolTestHarness
//
//  Created by Scott Little on 10/11/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "TTHAppDelegate.h"
#import	"MPTPluginMacros.h"



@implementation TTHAppDelegate

@synthesize window = _window;

void	MBMLaunchCommandForBundle2(NSString *mbmCommand, NSBundle *mbmMailBundle, BOOL needsActivate, NSString *mbmFrequency);
void	MBMCallToolCommandForBundleWithBlock2(NSString *mbmCommand, NSBundle *mbmMailBundle, MPTResultNotificationBlock mbmNotificationBlock);

void	MBMLaunchCommandForBundle2(NSString *mbmCommand, NSBundle *mbmMailBundle, BOOL mbmNeedsActivate, NSString *mbmFrequency) \
{ \
	NSDictionary	*scriptErrors = nil; \
	NSMutableString	*appleScript = [NSMutableString stringWithString:MPT_TELL_APPLICATION_OPEN]; \
	if (mbmNeedsActivate) {
		[appleScript appendString:MPT_ACTIVATE_APP];
	}
	[appleScript appendFormat:MPT_SCRIPT_FORMAT, mbmCommand, [mbmMailBundle bundlePath]]; \
	if (mbmFrequency != nil) { \
		[appleScript appendFormat:MPT_FREQUENCY_FORMAT, mbmFrequency]; \
	} \
	[appleScript appendString:MPT_END_TELL]; \
	NSAppleScript	*theScript = [[[NSAppleScript alloc] initWithSource:appleScript] autorelease]; \
	NSAppleEventDescriptor	*desc = [theScript executeAndReturnError:&scriptErrors]; \
	if (!desc) { \
		NSLog(@"Script (%@) to call MailBundleTool failed:%@", appleScript, scriptErrors); \
	} \
}

void	MBMCallToolCommandForBundleWithBlock2(NSString *mbmCommand, NSBundle *mbmMailBundle, MPTResultNotificationBlock mbmNotificationBlock) \
{ \
	NSString	*mbmNotificationName = [mbmCommand isEqualToString:MPT_SEND_MAIL_INFO_TEXT]?MPT_SYSTEM_INFO_NOTIFICATION:MPT_UUID_LIST_NOTIFICATION; \
	/*	Set up the notification watch	*/ \
	NSOperationQueue	*mbmQueue = [[[NSOperationQueue alloc] init] autorelease]; \
	__block id mbmObserver; \
	mbmObserver = [[NSDistributedNotificationCenter defaultCenter] addObserverForName:mbmNotificationName object:nil queue:mbmQueue usingBlock:^(NSNotification *note) { \
		/*	If this was aimed at us, then perform the block and remove the observer	*/ \
		if ([[note object] isEqualToString:[mbmMailBundle bundleIdentifier]]) { \
			mbmNotificationBlock([note userInfo]); \
			[[NSDistributedNotificationCenter defaultCenter] removeObserver:mbmObserver]; \
		} \
	}]; \
	/*	Then actually launch the app to get the information back	*/ \
	MBMLaunchCommandForBundle2(mbmCommand, mbmMailBundle, NO, nil); \
}

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
	MPTUUIDListForBundleWithBlock(mailBundle, myBlock);
	
	MPTCheckForUpdatesForBundle(mailBundle);
	NSBundle *sisBundle = [NSBundle bundleWithPath:@"/Users/scott/Library/Mail/Bundles/Sidebar for Infusionsoft.mailbundle"];
	MPTCheckForUpdatesForBundle(sisBundle);
	
	double delayInSeconds = 10.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[NSApp terminate:nil];
	});
}

@end
