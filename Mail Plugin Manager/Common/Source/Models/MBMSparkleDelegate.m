//
//  MBMSparkleDelegate.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBMSparkleDelegate.h"

@implementation MBMSparkleDelegate

@synthesize mailBundle = _mailBundle;
//@synthesize relaunchPath = _relaunchPath;
//@synthesize quitMail = _quitMail;
//@synthesize quitManager = _quitManager;

- (id)initWithMailBundle:(MBMMailBundle *)aMailBundle {
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

- (void)postDoneNotification {
	//	Post a new notification indicating that we are done
	[[NSNotificationCenter defaultCenter] postNotificationName:kMBMDoneUpdatingMailBundleNotification object:self.mailBundle];
}

- (void)updateDriverFinished:(NSNotification *)notification {
	
	//	Then reomve the observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kMBMSUUpdateDriverDoneNotification object:[notification object]];
	
	[self postDoneNotification];
}

- (void)updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)update {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDriverFinished:) name:kMBMSUUpdateDriverDoneNotification object:[updater valueForKey:@"driver"]];
}

- (void)updaterDidNotFindUpdate:(SUUpdater *)update {
	//	Post a new notification indicating that we are done
	[self postDoneNotification];
}

// Sent immediately before installing the specified update.
- (void)updater:(SUUpdater *)updater willInstallUpdate:(SUAppcastItem *)update {
	//	If the relaunchPath is for Mail, then quit it here
//		QuitMail();
}

//	Always postpone (indefinitely) the relaunch, but send a notification that the update is done.
- (BOOL)updater:(SUUpdater *)updater shouldPostponeRelaunchForUpdate:(SUAppcastItem *)update untilInvoking:(NSInvocation *)invocation {
	[self postDoneNotification];
	return NO;
}

//	Return nil path for restart
- (NSString *)pathToRelaunchForUpdater:(SUUpdater *)updater {
	return nil;
}

@end
