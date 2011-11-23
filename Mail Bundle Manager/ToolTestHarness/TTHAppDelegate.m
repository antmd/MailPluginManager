//
//  TTHAppDelegate.m
//  ToolTestHarness
//
//  Created by Scott Little on 10/11/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "TTHAppDelegate.h"
#import	"MBMPluginMacros.h"


#define MBT_TELL_APPLICATION_FORMAT		@"tell application \"MailBundleTool\" to %@ \"%@\""
#define MBT_FREQUENCY_FORMAT			@" frequency %@"
#define MBT_SEND_MAIL_INFO_TEXT			@"send mail info plugin path"
#define MBT_SEND_UUID_LIST_TEXT			@"send uuid list plugin path"
#define MBT_UPDATE_TEXT					@"update"
#define MBT_CRASH_REPORTS_TEXT			@"crash reports"
#define MBT_UPDATE_CRASH_REPORTS_TEXT	@"update and crash reports"

@implementation TTHAppDelegate

@synthesize window = _window;

void	MBMLaunchCommandForBundle2(NSString *mbmCommand, NSBundle *mbmMailBundle, NSString *mbmFrequency);
void	MBMCallToolCommandForBundleWithBlock2(NSString *mbmCommand, NSBundle *mbmMailBundle, MBMResultNotificationBlock mbmNotificationBlock);

void	MBMLaunchCommandForBundle2(NSString *mbmCommand, NSBundle *mbmMailBundle, NSString *mbmFrequency) \
{ \
	NSDictionary	*scriptErrors = nil; \
	NSMutableString	*appleScript = [NSMutableString stringWithFormat:MBT_TELL_APPLICATION_FORMAT, mbmCommand, [mbmMailBundle bundlePath]]; \
	if (mbmFrequency != nil) { \
		[appleScript appendFormat:MBT_FREQUENCY_FORMAT, mbmFrequency]; \
	} \
	NSAppleScript	*theScript = [[[NSAppleScript alloc] initWithSource:appleScript] autorelease]; \
	NSAppleEventDescriptor	*desc = [theScript executeAndReturnError:&scriptErrors]; \
	if (!desc) { \
		NSLog(@"Script (%@) to call MailBundleTool failed:%@", appleScript, scriptErrors); \
	} \
}

void	MBMCallToolCommandForBundleWithBlock2(NSString *mbmCommand, NSBundle *mbmMailBundle, MBMResultNotificationBlock mbmNotificationBlock) \
{ \
	NSString	*mbmNotificationName = [mbmCommand isEqualToString:MBT_SEND_MAIL_INFO_TEXT]?MBM_SYSTEM_INFO_NOTIFICATION:MBM_UUID_LIST_NOTIFICATION; \
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
	MBMLaunchCommandForBundle2(mbmCommand, mbmMailBundle, nil); \
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	
	MBMResultNotificationBlock myBlock = ^(NSDictionary *object) {
		NSLog(@"\n\nThe returned object is:%@\n\n", object);
	};
	
	NSBundle *mailBundle = [NSBundle bundleWithPath:@"/Users/scott/Library/Mail/Bundles/ExamplePlugin.mailbundle"];

	MBMCallToolCommandForBundleWithBlock2(MBT_SEND_MAIL_INFO_TEXT, mailBundle, myBlock);
	MBMCallToolCommandForBundleWithBlock2(MBT_SEND_UUID_LIST_TEXT, mailBundle, myBlock);

//	MBMLaunchCommandForBundle2(@"update", mailBundle, nil);

//	MBMMailInformationForBundleWithBlock(mailBundle, myBlock);
//	MBMUUIDListForBundleWithBlock(mailBundle, myBlock);
	
	
}

@end
