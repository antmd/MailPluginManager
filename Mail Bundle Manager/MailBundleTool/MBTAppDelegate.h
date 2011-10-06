//
//  MBTAppDelegate.h
//  MailBundleTool
//
//  Created by Scott Little on 28/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MBMManifestModel.h"

@interface MBTAppDelegate : NSObject <NSApplicationDelegate> {
}

@property (assign) IBOutlet NSWindow *window;

@property (nonatomic, retain)	NSWindowController	*currentController;
@property (nonatomic, assign)	BOOL				isMailRunning;
@property (nonatomic, retain)	NSOperationQueue	*maintenanceQueue;
@property (assign)				NSInteger			maintenanceCounter;
@property (assign)				BOOL				canQuitAccordingToMaintenance;

//	Maintenance task management
- (void)addMaintenanceTask:(void (^)(void))block;
- (void)startMaintenance;
- (void)endMaintenance;

//	Mail Application Management
- (BOOL)quitMail;
- (void)restartMail;

//	Quitting only when tasks are completed
- (void)quittingNowIsReasonable;

@end
