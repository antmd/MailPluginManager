//
//  MBMSystemInfo.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 11/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBMSystemInfo : NSObject {
@private	
	NSString		*_systemVersion;
	NSString		*_systemBuild;
	NSString		*_mailShortVersion;
	NSString		*_mailVersion;
	NSString		*_messageShortVersion;
	NSString		*_messageVersion;
	NSString		*_hardware;
	NSDictionary	*_completeInfo;
}
+ (NSString *)systemVersion;
+ (NSString *)systemBuild;
+ (NSString *)mailShortVersion;
+ (NSString *)mailVersion;
+ (NSString *)messageShortVersion;
+ (NSString *)messageVersion;
+ (NSString *)hardware;
+ (NSDictionary *)completeInfo;
@end