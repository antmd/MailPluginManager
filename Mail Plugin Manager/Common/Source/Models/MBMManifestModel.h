//
//  MBMManifestModel.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MBMActionItem.h"

typedef enum {
	kMBMOSIsSupported = 0,
	kMBMOSIsTooLow,
	kMBMOSIsTooHigh
} MBMOSSupportResult;
	

@interface MBMManifestModel : NSObject {
@private	
	MBMManifestType	_manifestType;
	NSString		*_displayName;
	NSString		*_backgroundImagePath;
	NSString		*_minOSVersion;
	NSString		*_maxOSVersion;
	CGFloat			_minMailVersion;
	MBMActionItem	*_bundleManager;
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

	//	Internal only
	CGFloat			_minVersionMinor;
	NSInteger		_minVersionBugFix;
	CGFloat			_maxVersionMinor;
	NSInteger		_maxVersionBugFix;
}

@property	(nonatomic, assign, readonly)	MBMManifestType	manifestType;
@property	(nonatomic, copy, readonly)		NSString		*displayName;
@property	(nonatomic, copy, readonly)		NSString		*backgroundImagePath;
@property	(nonatomic, assign, readonly)	NSString		*minOSVersion;
@property	(nonatomic, assign, readonly)	NSString		*maxOSVersion;
@property	(nonatomic, assign, readonly)	CGFloat			minMailVersion;
@property	(assign, readonly)				BOOL			shouldInstallManager;
@property	(nonatomic, retain, readonly)	MBMActionItem	*bundleManager;
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

- (id)initWithPackageAtPath:(NSString *)packageFilePath;
- (MBMOSSupportResult)supportResultForManifest;

@end

CGFloat macOSXVersion(void);
NSInteger macOSXBugFixVersion(void);
CGFloat mailVersion(void);
