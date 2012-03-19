//
//  MPCScheduledUpdateDriver.m
//  Mail Plugin Manager
//
//  Created by Scott Little on 01/03/2012.
//  Copyright (c) 2012 Little Known Software. All rights reserved.
//

#import "MPCScheduledUpdateDriver.h"

#import "SUStatusController.h"

#define SPARKLE_BUNDLE [NSBundle bundleWithIdentifier:@"org.andymatuschak.Sparkle"]
#define SULocalizedString(key,comment) NSLocalizedStringFromTableInBundle(key, @"Sparkle", SPARKLE_BUNDLE, comment)

@implementation MPCScheduledUpdateDriver

- (void)unarchiverDidFinish:(SUUnarchiver *)ua {
	SUStatusController	*aStatusController = [self valueForKey:@"statusController"];
	[aStatusController beginActionWithTitle:SULocalizedString(@"Ready to Install", nil) maxProgressValue:1.0 statusText:nil];
	[aStatusController setProgressValue:1.0]; // Fill the bar.
	[aStatusController setButtonEnabled:YES];
	[aStatusController setButtonTitle:SULocalizedString(@"Install Plugin", nil) target:self action:@selector(installAndRestart:) isDefault:YES];
	[[aStatusController window] makeKeyAndOrderFront: self];
	[NSApp requestUserAttention:NSInformationalRequest];	
}

- (void)installAndRestart:(id)sender {
    [self installWithToolAndRelaunch:NO];
}

- (void)didFindValidUpdate {
	showErrors = YES; // We only start showing errors after we present the UI for the first time.
	[super didFindValidUpdate];
}

- (void)didNotFindUpdate {
	if ([[updater delegate] respondsToSelector:@selector(updaterDidNotFindUpdate:)])
		[[updater delegate] updaterDidNotFindUpdate:updater];
	[self abortUpdate]; // Don't tell the user that no update was found; this was a scheduled update.
}

- (void)abortUpdateWithError:(NSError *)error {
	if (showErrors)
		[super abortUpdateWithError:error];
	else
		[self abortUpdate];
}

- (BOOL)isPastSchedule {
	
	// How long has it been since last we checked for an update?
	NSDate			*lastCheckDate = [updater lastUpdateCheckDate];
	if (!lastCheckDate) {
		lastCheckDate = [NSDate distantPast];
	}
	NSTimeInterval	intervalSinceCheck = [[NSDate date] timeIntervalSinceDate:lastCheckDate];
	
	// Now we want to figure out how long until we check again.
	NSTimeInterval updateCheckInterval = [updater updateCheckInterval];
	if (updateCheckInterval < SU_MIN_CHECK_INTERVAL)
		updateCheckInterval = SU_MIN_CHECK_INTERVAL;
	if (intervalSinceCheck < updateCheckInterval) {
		//	Not yet due for a check so just finish the operation
		return NO;
	}

	return YES;
}

@end
