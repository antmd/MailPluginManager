//
//  MPCCompanyList.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 09/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MPCCompanyList.h"


#define CANONICAL_KEY	@"canonical"
#define URL_KEY			@"url"


@interface MPCCompanyList ()
+ (MPCCompanyList *)sharedInstance;
+ (NSDictionary *)companyDictForIdentifier:(NSString *)companyRDN;
@end

@implementation MPCCompanyList


#pragma Mark - External Methods

+ (NSString *)companyNameFromIdentifier:(NSString *)identifier {
	return [[self companyDictForIdentifier:identifier] valueForKey:kMPCNameKey];
}

+ (NSString *)companyURLFromIdentifier:(NSString *)identifier {
	NSString	*url = [[self companyDictForIdentifier:identifier] valueForKey:URL_KEY];
	if (url == nil) {
		NSArray	*parts = [identifier componentsSeparatedByString:@"."];
		url = [NSString stringWithFormat:@"http://www.%@.%@", [parts objectAtIndex:1], [parts objectAtIndex:0]];
	}
	return url;
}

+ (NSString *)productURLFromIdentifier:(NSString *)identifier {
	return [[self companyDictForIdentifier:identifier] valueForKey:identifier];
}

+ (NSString *)filename {
	return kMPCCompaniesInfoFileName;
}

#pragma mark - Internal Methods

+ (MPCCompanyList *)sharedInstance {
	static dispatch_once_t	once;
	static MPCCompanyList	*sharedHelper;
	
	dispatch_once(&once, ^{ sharedHelper = [[self alloc] init]; });
	return sharedHelper;
}

+ (NSDictionary *)companyDictForIdentifier:(NSString *)identifier {
	NSDictionary	*list = [[self sharedInstance] contents];
	
	NSArray			*parts = [identifier componentsSeparatedByString:@"."];
	NSString		*companyRDN = [NSString stringWithFormat:@"%@.%@", [parts objectAtIndex:0], [parts objectAtIndex:1]];
	NSDictionary	*theCompany = [list valueForKey:companyRDN];
	if ([theCompany valueForKey:CANONICAL_KEY]) {
		theCompany = [list valueForKey:[theCompany valueForKey:CANONICAL_KEY]];
	}
	return theCompany;
}

@end
