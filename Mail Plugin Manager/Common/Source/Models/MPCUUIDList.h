//
//  MPCUUIDList.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 10/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MPCRemoteUpdatableList.h"

@interface MPCUUIDList : MPCRemoteUpdatableList {
@private	
	NSString	*_mailUUID;
	NSString	*_messageUUID;
}
+ (NSString *)currentMailUUID;
+ (NSString *)currentMessageUUID;
+ (NSString *)latestOSVersionFromSupportedList:(NSArray *)supportedUUIDs;
+ (NSString *)firstUnsupportedOSVersionFromSupportedList:(NSArray *)supportedUUIDs;
+ (NSDictionary *)latestUUIDDictFromSupportedList:(NSArray *)supportedUUIDs;
+ (NSDictionary *)firstUnsupportedUUIDDictFromSupportedList:(NSArray *)supportedUUIDs;
+ (NSDictionary *)fullUUIDListFromSupportedList:(NSArray *)supportedUUIDs;
+ (NSDictionary *)fullUUIDListFromBundle:(NSBundle *)pluginBundle;
@end
