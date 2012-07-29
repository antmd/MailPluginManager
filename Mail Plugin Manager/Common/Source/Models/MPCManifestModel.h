//
//  MPCManifestModel.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MPCActionItem.h"

typedef enum {
	kMPCOSIsSupported = 0,
	kMPCOSIsTooLow,
	kMPCOSIsTooHigh
} MPCOSSupportResult;
	

@interface MPCManifestModel : NSObject {
@private	
	MPCManifestType	_manifestType;
	NSString		*_displayName;
	NSString		*_backgroundImagePath;
	NSString		*_minOSVersion;
	NSString		*_maxOSVersion;
	CGFloat			_minMailVersion;
	MPCActionItem	*_bundleManager;
	NSArray			*_confirmationStepList;
	NSArray			*_actionItemList;
	NSUInteger		_totalActionItemCount;
	NSUInteger		_confirmationStepCount;
	BOOL			_canDeleteManagerIfNotUsedByOthers;	//	Default is NO
	BOOL			_canDeleteManagerIfNoBundlesLeft;	//	Default is YES
	BOOL			_shouldRestartMail;		//	Default is YES
	BOOL			_shouldConfigureMail;	//	Default is NO
	NSUInteger		_configureMailVersion;
	NSString		*_completionMessage;		//	Default is @""
	MPCMailBundle	*_packageMailBundle;

	//	Internal only
	CGFloat			_minVersionMinor;
	NSInteger		_minVersionBugFix;
	CGFloat			_maxVersionMinor;
	NSInteger		_maxVersionBugFix;
}

@property	(nonatomic, assign, readonly)	MPCManifestType	manifestType;
@property	(nonatomic, copy, readonly)		NSString		*displayName;
@property	(nonatomic, copy, readonly)		NSString		*backgroundImagePath;
@property	(nonatomic, assign, readonly)	NSString		*minOSVersion;
@property	(nonatomic, assign, readonly)	NSString		*maxOSVersion;
@property	(nonatomic, assign, readonly)	CGFloat			minMailVersion;
@property	(assign, readonly)				BOOL			shouldInstallManager;
@property	(nonatomic, retain, readonly)	MPCActionItem	*bundleManager;
@property	(nonatomic, retain, readonly)	NSArray			*confirmationStepList;
@property	(nonatomic, retain, readonly)	NSArray			*actionItemList;
@property	(nonatomic, assign, readonly)	NSUInteger		totalActionItemCount;
@property	(nonatomic, assign, readonly)	NSUInteger		confirmationStepCount;
@property	(nonatomic, assign, readonly)	BOOL			canDeleteManagerIfNotUsedByOthers;	//	Default is NO
@property	(nonatomic, assign, readonly)	BOOL			canDeleteManagerIfNoBundlesLeft;	//	Default is YES
@property	(nonatomic, assign, readonly)	BOOL			shouldRestartMail;		//	Default is YES
@property	(nonatomic, assign, readonly)	BOOL			shouldConfigureMail;	//	Default is NO
@property	(nonatomic, assign, readonly)	NSUInteger		configureMailVersion;
@property	(nonatomic, copy, readonly)		NSString		*completionMessage;		//	Default is @""
@property	(nonatomic, retain, readonly)	MPCMailBundle	*packageMailBundle;

- (id)initWithPackageAtPath:(NSString *)packageFilePath;
- (MPCOSSupportResult)supportResultForManifest;

@end

CGFloat macOSXVersion(void);
NSInteger macOSXBugFixVersion(void);
CGFloat mailVersion(void);
