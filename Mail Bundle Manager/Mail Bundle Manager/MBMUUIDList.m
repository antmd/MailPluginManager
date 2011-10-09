//
//  MBMUUIDList.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 10/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MBMUUIDList.h"

@interface MBMUUIDList ()
+ (MBMUUIDList *)sharedInstance;
@end

@implementation MBMUUIDList


#pragma Mark - External Methods

+ (void)loadUUIDListFromCloud {
	//	Try to load the plist from the remote server
	NSURL			*theURL = [NSURL URLWithString:@"http://lkslocal/mbm-uuids.plist"];
	[self loadListFromCloudURL:theURL];
}

+ (NSString *)filename {
	return kMBMHistoricalUUIDFileName;
}

#pragma mark - Internal Methods

+ (MBMUUIDList *)sharedInstance {
	static dispatch_once_t	once;
	static MBMUUIDList	*sharedHelper;
	
	dispatch_once(&once, ^{ sharedHelper = [[self alloc] init]; });
	return sharedHelper;
}

@end
