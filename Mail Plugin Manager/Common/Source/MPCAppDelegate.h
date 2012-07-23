//
//  MBAppDelegate.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 07/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MPCBackgroundableView.h"
#import "MPCMailBundle.h"
#import "MPCRestartAsyncOperation.h"


@interface MPCAppDelegate : NSObject <NSApplicationDelegate> {
@private
	id						_bundleUninstallObserver;
	
	NSWindow				*_window;
	NSCollectionViewItem	*_collectionItem;
	
	NSViewController		*_bundleViewController;
	NSArray					*_mailBundleList;
	NSWindowController		*_currentController;
	
	BOOL					_isMailRunning;
	NSOperationQueue		*_counterQueue;
	NSOperationQueue		*_maintenanceQueue;
	NSOperationQueue		*_activityQueue;
	NSOperationQueue		*_finalizeQueue;
	BOOL					_finalizeQueueRequiresExplicitRelease;
	BOOL					_finalizedQueueReleased;
	
	NSMutableArray			*_bundleSparkleOperations;
	
	MPCBackgroundableView	*_backgroundView;
	NSScrollView			*_scrollView;
	NSButton				*_quitButton;
	NSProgressIndicator		*_quitingIndicator;
	NSTextField				*_quittingNotice;
	
}

@property (assign)				id						bundleUninstallObserver;

@property (assign)	IBOutlet	NSWindow				*window;
@property (assign)	IBOutlet	NSCollectionViewItem	*collectionItem;

@property (retain)				NSViewController		*bundleViewController;
@property (nonatomic, retain)	NSArray					*mailBundleList;
@property (nonatomic, retain)	NSWindowController		*currentController;

@property (nonatomic, assign)	BOOL					isMailRunning;
@property (nonatomic, assign)	BOOL					finalizeQueueRequiresExplicitRelease;

@property (assign)	IBOutlet	MPCBackgroundableView	*backgroundView;
@property (assign)	IBOutlet	NSScrollView			*scrollView;
@property (assign)	IBOutlet	NSButton				*quitButton;
@property (assign)	IBOutlet	NSProgressIndicator		*quittingIndicator;
@property (assign)	IBOutlet	NSTextField				*quittingNotice;


//	Window management
- (void)showCollectionWindowForBundles:(NSArray *)bundleList;
- (void)adjustWindowSizeForBundleList:(NSArray *)bundleList animate:(BOOL)animate;

//	Action
- (IBAction)showURL:(id)sender;
- (IBAction)finishApplication:(id)sender;

//	Bundle Management
- (void)updateMailBundle:(MPCMailBundle *)mailBundle force:(BOOL)flag;

//	Queue management tasks
- (void)addMaintenanceTask:(void (^)(void))block;
- (void)addMaintenanceOperation:(NSOperation *)operation;
- (void)addActivityTask:(void (^)(void))block;
- (void)addActivityOperation:(NSOperation *)operation;
- (void)addFinalizeTask:(void (^)(void))block;
- (void)addFinalizeOperation:(NSOperation *)operation;
- (void)releaseActivityQueue;
- (void)releaseFinalizeQueue;

//	Quitting only when tasks are completed
- (void)quittingNowIsReasonable;

//	launchd management
- (BOOL)installStartupLaunchdConfig;
- (BOOL)installToolWatchLaunchdConfig;

//	Mail Application Management
- (BOOL)quitMail;
- (void)restartMailExecutingBlock:(MPCAsyncRestartBlock)taskBlock;
- (BOOL)askToRestartMailWithBlock:(void (^)(void))taskBlock usingIcon:(NSImage *)iconImage;

//	Used to set default values directly for the Plugin Manager
- (id)changePluginManagerDefaultValue:(id)value forKey:(NSString *)key;

@end
