//
//  MBMSparkleDelegate.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBMSparkleDelegate.h"

#import "MBMAppDelegate.h"

@implementation MBMSparkleDelegate

@synthesize relaunchPath = _relaunchPath;
@synthesize quitMail = _quitMail;
@synthesize quitManager = _quitManager;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc {
	self.relaunchPath = nil;
	
	[super dealloc];
}

// Sent immediately before installing the specified update.
- (void)updater:(SUUpdater *)updater willInstallUpdate:(SUAppcastItem *)update {
	
	//	If the relaunchPath is for Mail, then quit it here
	if (self.quitMail) {
		QuitMail();
	}
}

// Called immediately before relaunching.
- (void)updaterWillRelaunchApplication:(SUUpdater *)updater {
	
	//	Are we supposed to quit this app?
	if (self.quitManager) {
		//	 If so, then wait a second and then do it.
		[NSApp performSelector:@selector(terminate:) withObject:self afterDelay:1.0];
	}
}

- (NSString *)pathToRelaunchForUpdater:(SUUpdater *)updater {
	return self.relaunchPath;
}

@end
