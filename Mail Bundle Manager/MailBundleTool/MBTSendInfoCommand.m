//
//  MBTSendInfoCommand.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 23/11/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MBTSendInfoCommand.h"

#import "MBMPluginMacros.h"

@implementation MBTSendInfoCommand

- (id)performDefaultImplementation {

	LKLog(@"Args%@", [self evaluatedArguments]);
	LKLog(@"AppleEvent:%@", [self appleEvent]);
	
	NSString	*command = nil;
	NSString	*pluginPath = [self directParameter];
	switch ([[self appleEvent] eventID]) {
		case 'ReMv':
			command = kMBMCommandLineUninstallKey;
			break;
			
		case 'UpDt':
			command = kMBMCommandLineUpdateKey;
			break;
			
		case 'CrRp':
			command = kMBMCommandLineCheckCrashReportsKey;
			break;
			
		case 'Both':
			command = kMBMCommandLineUpdateAndCrashReportsKey;
			break;
			
		default:
			command = [self directParameter];
			pluginPath = [[self evaluatedArguments] valueForKey:@"pluginPath"];
			break;
	}
	NSArray		*arguments = [NSArray arrayWithObject:pluginPath];
	if ([[self evaluatedArguments] valueForKey:@"frequency"]) {
		arguments = [arguments arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:MBT_FREQUENCY_OPTION, [[self evaluatedArguments] valueForKey:@"frequency"], nil]];
	}
	LKLog(@"Action='%@' args=%@", command, arguments);
	[AppDel doAction:command withArguments:arguments];
	
	return nil;
}

@end
