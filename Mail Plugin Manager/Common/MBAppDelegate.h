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
	NSInteger				_maintenanceCounter;
	
	MBMBackgroundableView	*_backgroundView;
	NSScrollView			*_scrollView;
}

@property (assign)				id						bundleUninstallObserver;

@property (assign)	IBOutlet	NSWindow				*window;
@property (assign)	IBOutlet	NSCollectionViewItem	*collectionItem;

@property (retain)				NSViewController		*bundleViewController;
@property (nonatomic, retain)	NSArray					*mailBundleList;
@property (nonatomic, retain)	NSWindowController		*currentController;

@property (nonatomic, assign)	BOOL					isMailRunning;
@property (nonatomic, retain)	NSOperationQueue		*counterQueue;
@property (nonatomic, retain)	NSOperationQueue		*maintenanceQueue;
@property (assign)				NSInteger				maintenanceCounter;

@property (assign)	IBOutlet	MBMBackgroundableView	*backgroundView;
@property (assign)	IBOutlet	NSScrollView			*scrollView;

//	Window management
- (void)showCollectionWindowForBundles:(NSArray *)bundleList;
- (void)adjustWindowSizeForBundleList:(NSArray *)bundleList animate:(BOOL)animate;

//	Maintenance task management
- (void)addOperation:(NSOperation *)operation forQueueNamed:(NSString *)aQueueName;
- (void)addMaintenanceTask:(void (^)(void))block;
- (void)addMaintenanceOperation:(NSOperation *)operation;

//	Quitting only when tasks are completed
- (void)quittingNowIsReasonable;

//	Mail Application Management
- (BOOL)quitMail;
- (BOOL)restartMailWithBlock:(void (^)(void))taskBlock;
- (IBAction)restartMail:(id)sender;

//	Used to set default values directly for the Plugin Manager
- (id)changePluginManagerDefaultValue:(id)value forKey:(NSString *)key;

@end
