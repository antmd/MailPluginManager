//
//  MPCSystemInfo.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 11/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPCSystemInfo : NSObject {
@private
	NSString		*_hashedNetworkAddress;
	NSString		*_systemVersion;
	NSString		*_systemBuild;
	NSString		*_mailShortVersion;
	NSString		*_mailVersion;
	NSString		*_messageShortVersion;
	NSString		*_messageVersion;
	NSString		*_hardware;
	NSDictionary	*_completeInfo;
}
+ (NSString *)hashedNetworkAddress;
+ (NSString *)systemVersion;
+ (NSString *)systemBuild;
+ (NSString *)mailShortVersion;
+ (NSString *)mailVersion;
+ (NSString *)messageShortVersion;
+ (NSString *)messageVersion;
+ (NSString *)hardware;
+ (NSDictionary *)completeInfo;
@end
