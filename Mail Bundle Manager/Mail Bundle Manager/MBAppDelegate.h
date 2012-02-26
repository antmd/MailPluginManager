//
//  MBAppDelegate.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 07/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MBMBackgroundableView.h"

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

@property (assign)	IBOutlet	MBMBackgroundableView	*backgroundView;
@property (assign)	IBOutlet	NSScrollView			*scrollView;

//	Window management
- (void)showCollectionWindowForBundles:(NSArray *)bundleList;
- (void)adjustWindowSizeForBundleList:(NSArray *)bundleList animate:(BOOL)animate;

//	Maintenance task management
- (void)addMaintenanceTask:(void (^)(void))block;
- (void)addMaintenanceOperation:(NSOperation *)operation;
- (void)startMaintenance;
- (void)endMaintenance;
- (void)performWhenMaintenanceIsFinishedUsingBlock:(void(^)(void))block;
- (void)performBlock:(void(^)(void))block whenNotificationsReceived:(NSArray *)notificationList testType:(MBMNotificationsReceivedTestType)testType;

//	Mail Application Management
- (BOOL)quitMail;
- (BOOL)restartMailWithBlock:(void (^)(void))taskBlock;
- (IBAction)restartMail:(id)sender;

//	Quitting only when tasks are completed
- (void)quittingNowIsReasonable;
- (void)quitAfterReceivingNotifications:(NSArray *)notificationList;
- (void)quitAfterReceivingNotifications:(NSArray *)notificationList testType:(MBMNotificationsReceivedTestType)testType;
- (void)quitAfterReceivingNotificationNames:(NSArray *)notificationNames onObject:(NSObject *)object testType:(MBMNotificationsReceivedTestType)testType;

@end
