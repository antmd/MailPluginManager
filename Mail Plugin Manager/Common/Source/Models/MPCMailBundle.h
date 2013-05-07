//
//  MPCMailBundle.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MPCSparkleDelegate.h"

@interface MPCMailBundle : NSObject {
@private
	NSString		*_name;
	NSString		*_company;
	NSString		*_companyURL;
	NSString		*_productURL;
	NSString		*_iconPath;
	NSString		*_buildName;
	NSString		*_buildSHA;
	NSImage			*_icon;
	NSBundle		*_bundle;
	BOOL			_incompatibleWithCurrentMail;
	BOOL			_incompatibleWithFutureMail;
	BOOL			_usesBundleManager;
	
	NSString		*_latestVersion;
	NSString		*_latestShortVersion;
	BOOL			_hasUpdate;
	
	BOOL			_enabled;
	BOOL			_installed;
	BOOL			_inLocalDomain;
	BOOL			_updateWaiting;
	
	NSInteger			_initialState;
	MPCSparkleDelegate	*_sparkleDelegate;
	BOOL				_hasBeenUpdated;
	BOOL				_needsMailRestart;
}

@property	(nonatomic, copy, readonly)		NSString		*name;
@property	(nonatomic, copy, readonly)		NSString		*path;
@property	(nonatomic, copy, readonly)		NSString		*anonymousPath;
@property	(nonatomic, copy, readonly)		NSString		*identifier;
@property	(nonatomic, copy, readonly)		NSString		*company;
@property	(nonatomic, copy, readonly)		NSString		*companyURL;
@property	(nonatomic, copy, readonly)		NSString		*productURL;
@property	(nonatomic, copy, readonly)		NSString		*version;
@property	(nonatomic, copy, readonly)		NSString		*shortVersion;
@property	(nonatomic, copy, readonly)		NSString		*iconPath;
@property	(nonatomic, copy, readonly)		NSString		*buildName;
@property	(nonatomic, copy, readonly)		NSString		*buildSHA;
@property	(nonatomic, copy, readonly)		NSString		*incompatibleString;
@property	(nonatomic, copy, readonly)		NSColor			*incompatibleStringColor;
@property	(nonatomic, retain, readonly)	NSImage			*icon;
@property	(nonatomic, retain, readonly)	NSBundle		*bundle;
@property	(nonatomic, assign, readonly)	BOOL			incompatibleWithCurrentMail;
@property	(nonatomic, assign, readonly)	BOOL			incompatibleWithFutureMail;
@property	(nonatomic, assign, readonly)	BOOL			usesBundleManager;

@property	(nonatomic, copy)				NSString		*latestVersion;
@property	(nonatomic, copy)				NSString		*latestShortVersion;
@property	(nonatomic, assign)				BOOL			hasUpdate;

@property	(nonatomic, assign)				BOOL			enabled;
@property	(nonatomic, assign)				BOOL			installed;
@property	(nonatomic, assign)				BOOL			inLocalDomain;
@property	(nonatomic, assign)				BOOL			updateWaiting;
@property	(nonatomic, assign, readonly)	BOOL			enableCheckboxes;
@property	(nonatomic, assign, readonly)	BOOL			enableUpdateButton;

@property	(nonatomic, retain)				MPCSparkleDelegate	*sparkleDelegate;
@property	(nonatomic, assign, readonly)	BOOL				needsMailRestart;

+ (MPCMailBundle *)mailBundleForPath:(NSString *)aBundlePath shouldLoadInfo:(BOOL)loadInfo;

+ (NSString *)pathForActiveBundleWithName:(NSString *)aBundleName;

+ (NSString *)mailFolderPathLocal;
+ (NSString *)bundlesPathLocalShouldCreate:(BOOL)createNew;
+ (NSString *)latestDisabledBundlesPathLocalShouldCreate:(BOOL)createNew;
+ (NSArray *)disabledBundlesPathLocalList;

+ (NSString *)mailFolderPath;
+ (NSString *)bundlesPathShouldCreate:(BOOL)createNew;
+ (NSString *)latestDisabledBundlesPathShouldCreate:(BOOL)createNew;
+ (NSArray *)disabledBundlesPathList;

+ (NSString *)disabledBundleFolderName;
+ (NSString *)disabledBundleFolderPrefix;

+ (NSArray *)allMailBundles;
+ (NSArray *)allMailBundlesLoadInfo;
+ (NSArray *)allActiveMailBundlesShouldLoadInfo:(BOOL)loadInfo;
+ (NSArray *)allDisabledMailBundlesShouldLoadInfo:(BOOL)loadInfo;

+ (NSComparisonResult)compareVersion:(NSString *)first toVersion:(NSString *)second;
+ (NSArray *)bestBundleSortDescriptors;

- (id)initWithPath:(NSString *)bundlePath;
- (id)initWithPath:(NSString *)bundlePath shouldLoadUpdateInfo:(BOOL)loadInfo;

- (NSColor *)nameColor;
- (NSString *)backgroundImagePath;
- (void)resetInitialState;

- (BOOL)isInActiveBundlesFolder;
- (BOOL)isInDisabledBundlesFolder;
- (BOOL)hasLaterVersionNumberThanBundle:(MPCMailBundle *)otherBundle;
- (NSString *)latestOSVersionSupported;
- (NSString *)firstOSVersionUnsupported;
- (BOOL)supportsSparkleUpdates;

- (void)loadUpdateInformation;
- (void)updateIfNecessary;
- (BOOL)uninstall;
//- (void)sendCrashReports;

@end
