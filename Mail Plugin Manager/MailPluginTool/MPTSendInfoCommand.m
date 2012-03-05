//
//  MBTSendInfoCommand.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 23/11/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MPTSendInfoCommand.h"

#import "MPTPluginMacros.h"

@implementation MPTSendInfoCommand

- (id)performDefaultImplementation {

	LKLog(@"Args%@", [self evaluatedArguments]);
	LKLog(@"AppleEvent:%@", [self appleEvent]);
	
	NSString	*command = nil;
	NSString	*pluginPath = [self directParameter];
	switch ([[self appleEvent] eventID]) {
		case 'ReMv':
			command = kMPCCommandLineUninstallKey;
			break;
			
		case 'UpDt':
			command = kMPCCommandLineUpdateKey;
			break;
			
		case 'CrRp':
			command = kMPCCommandLineCheckCrashReportsKey;
			break;
			
		case 'Both':
			command = kMPCCommandLineUpdateAndCrashReportsKey;
			break;
			
		default:
			command = [self directParameter];
			pluginPath = [[self evaluatedArguments] valueForKey:@"pluginPath"];
			break;
	}
	NSArray		*arguments = [NSArray arrayWithObject:pluginPath];
	if ([[self evaluatedArguments] valueForKey:@"frequency"]) {
		arguments = [arguments arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:MPT_FREQUENCY_OPTION, [[self evaluatedArguments] valueForKey:@"frequency"], nil]];
	}
	LKLog(@"Action='%@' args=%@", command, arguments);
	[AppDel doAction:command withArguments:arguments];
	
	return nil;
}

@end
