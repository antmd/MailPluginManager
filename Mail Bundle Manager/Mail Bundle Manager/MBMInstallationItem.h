//
//  MBMInstallationItem.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 14/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBMInstallationItem : NSObject

@property	(nonatomic, copy, readonly)		NSString	*name;
@property	(nonatomic, copy, readonly)		NSString	*itemDescription;
@property	(nonatomic, copy, readonly)		NSArray		*permissions;
@property	(nonatomic, copy, readonly)		NSString	*path;
@property	(nonatomic, copy, readonly)		NSString	*destinationPath;
@property	(nonatomic, assign, readonly)	BOOL		isMailBundle;
@property	(nonatomic, assign, readonly)	BOOL		isBundleManager;

- (id)initWithDictionary:(NSDictionary *)itemDictionary fromInstallationFilePath:(NSString *)installFilePath;

@end

