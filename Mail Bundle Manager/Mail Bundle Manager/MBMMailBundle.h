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
@property	(nonatomic, copy, readonly)		NSString		*identifier;
@property	(nonatomic, copy, readonly)		NSString		*company;
@property	(nonatomic, copy, readonly)		NSString		*companyURL;
@property	(nonatomic, copy, readonly)		NSString		*version;
@property	(nonatomic, copy, readonly)		NSString		*latestVersion;
@property	(nonatomic, copy, readonly)		NSString		*iconPath;
@property	(nonatomic, copy, readonly)		NSString		*incompatibleString;
@property	(nonatomic, retain, readonly)	NSImage			*icon;
@property	(nonatomic, retain, readonly)	NSBundle		*bundle;
@property	(nonatomic, assign, readonly)	BOOL			enabled;
@property	(nonatomic, assign, readonly)	BOOL			canUninstall;
@property	(nonatomic, assign, readonly)	BOOL			inLocalDomain;
@property	(nonatomic, assign, readonly)	BOOL			compatibleWithCurrentMail;
@property	(nonatomic, assign, readonly)	BOOL			usesBundleManager;
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

+ (NSArray *)allMailBundles;
+ (NSArray *)allActiveMailBundles;
+ (NSArray *)allDisabledMailBundles;

+ (NSComparisonResult)compareVersion:(NSString *)first toVersion:(NSString *)second;

- (id)initWithPath:(NSString *)bundlePath;

- (BOOL)isInActiveBundlesFolder;
- (BOOL)isInDisabledBundlesFolder;
- (BOOL)hasLaterVersionNumberThanBundle:(MBMMailBundle *)otherBundle;
- (NSString *)latestOSVersionSupported;

- (void)updateIfNecessary;
- (void)uninstall;
- (void)sendCrashReports;

@end
