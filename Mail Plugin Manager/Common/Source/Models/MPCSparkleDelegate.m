//
//  MPCSparkleDelegate.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MPCSparkleDelegate.h"

@implementation MPCSparkleDelegate

@synthesize mailBundle = _mailBundle;
//@synthesize relaunchPath = _relaunchPath;
//@synthesize quitMail = _quitMail;
//@synthesize quitManager = _quitManager;

- (id)initWithMailBundle:(MPCMailBundle *)aMailBundle {
    self = [super init];
    if (self) {
        // Initialization code here.
		_mailBundle = [aMailBundle retain];
    }
    
    return self;
}

- (void)dealloc {
	[_mailBundle release];
	_mailBundle = nil;
	[super dealloc];
}

//- (void)postDoneNotification {
//	//	Post a new notification indicating that we are done
//	LKLog(@"Sending Sparkle Done Notification for '%@'", [[self.mailBundle path] lastPathComponent]);
//	[[NSNotificationCenter defaultCenter] postNotificationName:kMPCDoneUpdatingMailBundleNotification object:self.mailBundle];
//}
//
//- (void)updateDriverFinished:(NSNotification *)notification {
//	//	Then remove the observer
//	if (notification != nil) {
//		[[NSNotificationCenter defaultCenter] removeObserver:self name:kMPCSUUpdateDriverAbortNotification object:[notification object]];
//	}
//	[self postDoneNotification];
//}
//
//- (void)updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)update {
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDriverFinished:) name:kMPCSUUpdateDriverAbortNotification object:[updater valueForKey:@"driver"]];
//}
//
//- (void)updaterDidNotFindUpdate:(SUUpdater *)update {
//	//	Post a new notification indicating that we are done
//	[self updateDriverFinished:nil];
//}

//	Always postpone (indefinitely) the relaunch, but send a notification that the update is done.
- (BOOL)updater:(SUUpdater *)updater shouldPostponeRelaunchForUpdate:(SUAppcastItem *)update untilInvoking:(NSInvocation *)invocation {
	//	Change the invocation to set the Relaunch value to NO
	BOOL	relaunch = NO;
	[invocation setArgument:&relaunch atIndex:2];
	[[NSNotificationCenter defaultCenter] postNotificationName:kMPCDoneUpdatingMailBundleNotification object:self.mailBundle userInfo:[NSDictionary dictionaryWithObjectsAndKeys:invocation, @"invoker", nil]];
	return YES;
}

@end
