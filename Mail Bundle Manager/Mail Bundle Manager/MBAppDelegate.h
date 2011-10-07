//
//  MBAppDelegate.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 07/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBAppDelegate : NSObject <NSApplicationDelegate> {
}

@property (assign)				id						bundleUnistallObserver;

@property (assign)	IBOutlet	NSWindow				*window;
@property (assign)	IBOutlet	NSCollectionViewItem	*collectionItem;

@property (retain)				NSViewController		*bundleViewController;
@property (nonatomic, retain)	NSArray					*mailBundleList;
@property (nonatomic, retain)	NSWindowController		*currentController;

@property (nonatomic, assign)	BOOL					isMailRunning;
@property (nonatomic, retain)	NSOperationQueue		*maintenanceCounterQueue;
@property (nonatomic, retain)	NSOperationQueue		*maintenanceQueue;
@property (assign)				NSInteger				maintenanceCounter;
@property (assign)				BOOL					canQuitAccordingToMaintenance;


//	Maintenance task management
- (void)addMaintenanceTask:(void (^)(void))block;
- (void)startMaintenance;
- (void)endMaintenance;

//	Mail Application Management
- (BOOL)quitMail;
- (IBAction)restartMail:(id)sender;

//	Quitting only when tasks are completed
- (void)quittingNowIsReasonable;

@end
