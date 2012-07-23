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
	NSString	*freqValue = @"weekly";
	if ([[self evaluatedArguments] valueForKey:@"frequency"]) {
		LKLog(@"Arg class:%@   value:%@", [[[self evaluatedArguments] valueForKey:@"frequency"] className], [[self evaluatedArguments] valueForKey:@"frequency"]);
		
		switch ([[[self evaluatedArguments] valueForKey:@"frequency"] longValue]) {
			case 'Now ':
				freqValue = @"now";
				break;
				
			case 'Daly':
				freqValue = @"daily";
				break;
				
			case 'Mnth':
				freqValue = @"monthly";
				break;
				
			default:
				break;
		}
		
		arguments = [arguments arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:MPT_FREQUENCY_OPTION, freqValue, nil]];
	}
	LKLog(@"Action='%@' args=%@", command, arguments);
	[AppDel doAction:[AppDel actionTypeForString:command] withArguments:arguments shouldFinish:YES];
	
	return nil;
}

@end
