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

void	MBMLaunchCommandForBundle2(NSString *mbmCommand, NSBundle *mbmMailBundle, NSString *mbmFrequency);
void	MBMCallToolCommandForBundleWithBlock2(NSString *mbmCommand, NSBundle *mbmMailBundle, MBMResultNotificationBlock mbmNotificationBlock);

void	MBMLaunchCommandForBundle2(NSString *mbmCommand, NSBundle *mbmMailBundle, NSString *mbmFrequency) \
{ \
	/*	Then actually launch the app to get the information back	*/ \
	NSString	*mbmToolPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:MBM_TOOL_IDENTIFIER]; \
	NSString	*mbmFreqFlag = (mbmFrequency != nil)?[NSString stringWithFormat:@"%@ %@", MBM_FREQUENCY_OPTION, mbmFrequency]:nil; \
	NSArray		*mbmToolArguments = [NSArray arrayWithObjects:mbmCommand, [mbmMailBundle bundlePath], mbmFreqFlag, nil]; \
	NSTask *myTask = [NSTask launchedTaskWithLaunchPath:mbmToolPath arguments:mbmToolArguments]; \
	NSLog(@"what:%@", myTask);
}

void	MBMCallToolCommandForBundleWithBlock2(NSString *mbmCommand, NSBundle *mbmMailBundle, MBMResultNotificationBlock mbmNotificationBlock) \
{ \
	NSString	*mbmNotificationName = [mbmCommand isEqualToString:MBM_SYSTEM_INFO_COMMAND]?MBM_SYSTEM_INFO_NOTIFICATION:MBM_UUID_LIST_NOTIFICATION; \
	/*	Set up the notification watch	*/ \
	NSOperationQueue	*mbmQueue = [[[NSOperationQueue alloc] init] autorelease]; \
	__block id mbmObserver; \
	mbmObserver = [[NSDistributedNotificationCenter defaultCenter] addObserverForName:mbmNotificationName object:nil queue:mbmQueue usingBlock:^(NSNotification *note) { \
		/*	If this was aimed at us, then perform the block and remove the observer	*/ \
		if ([[[note userInfo] valueForKey:MBM_SENDER_ID_KEY] isEqualToString:[mbmMailBundle bundleIdentifier]]) { \
			mbmNotificationBlock([note object]); \
			[[NSDistributedNotificationCenter defaultCenter] removeObserver:mbmObserver]; \
		} \
	}]; \
	/*	Then actually launch the app to get the information back	*/ \
	MBMLaunchCommandForBundle2(mbmCommand, mbmMailBundle, nil); \
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	
//	MBMResultNotificationBlock myBlock = ^(NSDictionary *object) {
//		NSLog(@"The returned object is:%@", object);
//	};
	
//	NSBundle *mailBundle = [NSBundle bundleWithPath:@"/Users/scott/Library/Mail/Bundles/ExamplePlugin.mailbundle"];

//	MBMLaunchCommandForBundle2(MBM_SYSTEM_INFO_COMMAND, mailBundle, nil);
//	MBMCallToolCommandForBundleWithBlock2(MBM_SYSTEM_INFO_COMMAND, mailBundle, myBlock);
//	MBMCallToolCommandForBundleWithBlock2(MBM_UUID_LIST_COMMAND ,mailBundle, myBlock);

	NSString	*mbmToolPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:@"com.littleknownsoftware.Mail-Bundle-Manager"];
//	NSArray		*mbmToolArguments = [NSArray arrayWithObjects:mbmCommand, [mbmMailBundle bundlePath], mbmFreqFlag, nil];
	NSTask *myTask = [NSTask launchedTaskWithLaunchPath:mbmToolPath arguments:[NSArray array]];
	NSLog(@"what:%@", myTask);

	
}

@end
