//
//  MBMRemoteUpdatableList.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 10/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBMRemoteUpdatableList : NSObject
@property	(nonatomic, retain)		NSDictionary	*contents;
@property	(nonatomic, retain)		NSDate			*date;
+ (void)loadListFromCloudURL:(NSURL *)theURL;
+ (NSString *)filename;
+ (NSString *)localSupportPath;
@end
