//
//  MBMMailBundle.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MBMSparkleDelegate.h"

@interface MBMMailBundle : NSObject

@property	(nonatomic, copy, readonly)		NSString		*name;
@property	(nonatomic, copy, readonly)		NSString		*path;
@property	(nonatomic, copy, readonly)		NSString		*version;
@property	(nonatomic, retain, readonly)	NSImage			*icon;
@property	(nonatomic, retain, readonly)	NSBundle		*bundle;
@property	(nonatomic, assign)				MBMBundleStatus	status;

@property	(nonatomic, retain)				MBMSparkleDelegate	*sparkleDelegate;

+ (MBMMailBundle *)mailBundleForPath:(NSString *)aBundlePath;
+ (NSString *)mailFolderPath;
+ (NSString *)bundlesPath;
+ (NSString *)latestDisabledBundlesPath;
+ (NSString *)latestDisabledBundlesPathShouldCreate:(BOOL)createNew;
+ (NSArray *)disabledBundlesPathList;
+ (NSString *)disabledBundleFolderName;
+ (NSString *)disabledBundleFolderPrefix;
+ (NSComparisonResult)compareVersion:(NSString *)first toVersion:(NSString *)second;

- (id)initWithBundleIdentifier:(NSString *)aBundleIdentifier andPath:(NSString *)bundlePath;

- (BOOL)isInActiveBundlesFolder;
- (BOOL)isInDisabledBundlesFolder;

- (void)updateIfNecessary;
- (void)uninstall;
- (void)sendCrashReports;

@end
