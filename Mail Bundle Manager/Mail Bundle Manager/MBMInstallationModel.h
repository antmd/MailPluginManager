//
//  MBMInstallationModel.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MBMInstallationItem.h"

@interface MBMInstallationModel : NSObject

@property	(nonatomic, copy, readonly)		NSString			*displayName;
@property	(nonatomic, copy, readonly)		NSString			*backgroundImagePath;
@property	(nonatomic, assign, readonly)	CGFloat				minOSVersion;
@property	(nonatomic, assign, readonly)	CGFloat				maxOSVersion;
@property	(nonatomic, assign, readonly)	CGFloat				minMailVersion;
@property	(assign, readonly)				BOOL				shouldInstallManager;
@property	(nonatomic, retain, readonly)	MBMInstallationItem	*bundleManager;
@property	(nonatomic, retain, readonly)	NSArray				*confirmationStepList;
@property	(nonatomic, retain, readonly)	NSArray				*installationItemList;
@property	(nonatomic, assign, readonly)	NSInteger			totalInstallationItemCount;

- (id)initWithInstallPackageAtPath:(NSString *)installFilePath;

@end

CGFloat macOSXVersion(void);
CGFloat mailVersion(void);
