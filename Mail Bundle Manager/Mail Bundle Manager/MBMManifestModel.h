//
//  MBMManifestModel.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MBMActionItem.h"

@interface MBMManifestModel : NSObject

@property	(nonatomic, assign, readonly)	MBMManifestType	manifestType;
@property	(nonatomic, copy, readonly)		NSString		*displayName;
@property	(nonatomic, copy, readonly)		NSString		*backgroundImagePath;
@property	(nonatomic, assign, readonly)	CGFloat			minOSVersion;
@property	(nonatomic, assign, readonly)	CGFloat			maxOSVersion;
@property	(nonatomic, assign, readonly)	CGFloat			minMailVersion;
@property	(assign, readonly)				BOOL			shouldInstallManager;
@property	(nonatomic, retain, readonly)	MBMActionItem	*bundleManager;
@property	(nonatomic, retain, readonly)	NSArray			*confirmationStepList;
@property	(nonatomic, retain, readonly)	NSArray			*actionItemList;
@property	(nonatomic, assign, readonly)	NSUInteger		totalActionItemCount;
@property	(nonatomic, assign, readonly)	NSUInteger		confirmationStepCount;

- (id)initWithPackageAtPath:(NSString *)packageFilePath;

@end

CGFloat macOSXVersion(void);
CGFloat mailVersion(void);
