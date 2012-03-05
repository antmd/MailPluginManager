//
//  MPCRemoteUpdatableList.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 10/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPCRemoteUpdatableList : NSObject {
@private	
	NSDictionary	*_contents;
	NSDate			*_date;
}
@property	(nonatomic, retain)		NSDictionary	*contents;
@property	(nonatomic, retain)		NSDate			*date;
+ (void)loadListFromCloud;
+ (NSString *)filename;
+ (NSString *)localSupportPath;
@end
