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

void	MPTLaunchCommandForBundle2(NSString *mptCommand, NSBundle *mptMailBundle, BOOL needsActivate, NSString *mptFrequency);
void	MPTCallToolCommandForBundleWithBlock2(NSString *mptCommand, NSBundle *mptMailBundle, MPTResultNotificationBlock mptNotificationBlock);

void	MPTLaunchCommandForBundle2(NSString *mptCommand, NSBundle *mptMailBundle, BOOL mptNeedsActivate, NSString *mptFrequency) \
{ \
	NSDictionary	*scriptErrors = nil; \
	NSMutableString	*appleScript = [NSMutableString stringWithString:MPT_TELL_APPLICATION_OPEN]; \
	if (mptNeedsActivate) {
		[appleScript appendString:MPT_ACTIVATE_APP];
	}
	[appleScript appendFormat:MPT_SCRIPT_FORMAT, mptCommand, [mptMailBundle bundlePath]]; \
	if (mptFrequency != nil) { \
		[appleScript appendFormat:MPT_FREQUENCY_FORMAT, mptFrequency]; \
	} \
	[appleScript appendString:MPT_END_TELL]; \
	NSAppleScript	*theScript = [[[NSAppleScript alloc] initWithSource:appleScript] autorelease]; \
	NSAppleEventDescriptor	*desc = [theScript executeAndReturnError:&scriptErrors]; \
	if (!desc) { \
		NSLog(@"Script (%@) to call MailBundleTool failed:%@", appleScript, scriptErrors); \
	} \
}

void	MPTCallToolCommandForBundleWithBlock2(NSString *mptCommand, NSBundle *mptMailBundle, MPTResultNotificationBlock mptNotificationBlock) \
{ \
	NSString	*mptNotificationName = [mptCommand isEqualToString:MPT_SEND_MAIL_INFO_TEXT]?MPT_SYSTEM_INFO_NOTIFICATION:MPT_UUID_LIST_NOTIFICATION; \
	/*	Set up the notification watch	*/ \
	NSOperationQueue	*mptQueue = [[[NSOperationQueue alloc] init] autorelease]; \
	__block id mptObserver; \
	mptObserver = [[NSDistributedNotificationCenter defaultCenter] addObserverForName:mptNotificationName object:nil queue:mptQueue usingBlock:^(NSNotification *note) { \
		/*	If this was aimed at us, then perform the block and remove the observer	*/ \
		if ([[note object] isEqualToString:[mptMailBundle bundleIdentifier]]) { \
			mptNotificationBlock([note userInfo]); \
			[[NSDistributedNotificationCenter defaultCenter] removeObserver:mptObserver]; \
		} \
	}]; \
	/*	Then actually launch the app to get the information back	*/ \
	MPTLaunchCommandForBundle2(mptCommand, mptMailBundle, NO, nil); \
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
	
//	MPTUninstallForBundle(mailBundle);
	
//	MPTCheckForUpdatesForBundle(mailBundle);
//	NSBundle *sisBundle = [NSBundle bundleWithPath:@"/Users/scott/Library/Mail/Bundles/Sidebar for Infusionsoft.mailbundle"];
//	MPTCheckForUpdatesForBundle(sisBundle);
//	MPTUninstallForBundle(sisBundle);
//	MPTSendCrashReportsForBundle(sisBundle);
	
	double delayInSeconds = 10.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[NSApp terminate:nil];
	});
}

@end
