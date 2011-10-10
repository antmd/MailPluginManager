//
//  MBMUUIDList.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 10/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MBMUUIDList.h"


#define LATEST_MAIL_KEY		@"latest-mail"
#define LATEST_MESSAGE_KEY	@"latest-message"

@interface MBMUUIDList ()
@property	(nonatomic, copy)	NSString	*mailUUID;
@property	(nonatomic, copy)	NSString	*messageUUID;
+ (MBMUUIDList *)sharedInstance;
+ (NSDictionary *)latestVersionsInList:(NSArray *)uuidList;
@end

@implementation MBMUUIDList

@synthesize mailUUID = _mailUUID;
@synthesize messageUUID = _messageUUID;

#pragma Mark - External Methods

+ (void)loadUUIDListFromCloud {
	//	Try to load the plist from the remote server
	NSURL			*theURL = [NSURL URLWithString:@"http://lkslocal/mbm-uuids.plist"];
	[self loadListFromCloudURL:theURL];
}

+ (NSString *)latestOSVersionInSupportedList:(NSArray *)supportedUUIDs {
	NSString		*latestSupported = NSLocalizedString(@"Unknown", @"Text indicating that we couldn't determine the latest version of the OS that this plugin supports");
	NSDictionary	*latestDicts = [self latestVersionsInList:supportedUUIDs];
	NSDictionary	*mailDict = [latestDicts valueForKey:LATEST_MAIL_KEY];
	NSDictionary	*messageDict = [latestDicts valueForKey:LATEST_MESSAGE_KEY];
	
	//	If either is nil, we can't determine
	if ((mailDict == nil) || (messageDict == nil)) {
		return latestSupported;
	}
	
	//	Then between the two of those, which is the earliest
	if ([[messageDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] > [[mailDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue]) {
		latestSupported = [messageDict valueForKey:kMBMUUIDLatestVersionKey];
	}
	else {
		latestSupported = [mailDict valueForKey:kMBMUUIDLatestVersionKey];
	}
	
	return latestSupported;
}

+ (NSString *)firstUnsupportedOSVersionFromList:(NSArray *)supportedUUIDs {
	NSString		*firstUnsupported = NSLocalizedString(@"None", @"Text indicating that we couldn't find any version of the OS that this plugin does not support");
	NSDictionary	*latestDicts = [self latestVersionsInList:supportedUUIDs];
	NSDictionary	*latestMailDict = [latestDicts valueForKey:LATEST_MAIL_KEY];
	NSDictionary	*latestMessageDict = [latestDicts valueForKey:LATEST_MESSAGE_KEY];
	NSDictionary	*lowestFutureMailDict = nil;
	NSDictionary	*lowestFutureMessageDict = nil;
	
	//	Look though all the defined UUIDs in our file
	NSDictionary	*allContents = [self sharedInstance].contents;
	for (NSString *aUUID in [allContents allKeys]) {
		NSDictionary	*uuidDict = [allContents valueForKey:aUUID];
		
		//	For each type save the one that is greater than the latest from the list, but less that any already saved
		if ([[uuidDict valueForKey:kMBMUUIDTypeKey] isEqualToString:kMBMUUIDTypeValueMail]) {
			if ((lowestFutureMailDict == nil) ||
				(([[uuidDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] > [[latestMailDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue]) &&
				([[uuidDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] < [[lowestFutureMailDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue]))) {
					lowestFutureMailDict = uuidDict;
			}
		}
		else if ([[uuidDict valueForKey:kMBMUUIDTypeKey] isEqualToString:kMBMUUIDTypeValueMessage]) {
			if ((lowestFutureMessageDict == nil) ||
				(([[uuidDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] > [[latestMessageDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue]) &&
				 ([[uuidDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] < [[lowestFutureMessageDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue]))) {
					lowestFutureMessageDict = uuidDict;
			}
		}
	}
	
	//	If either is nil, we can't determine
	if ((lowestFutureMailDict == nil) || (lowestFutureMessageDict == nil)) {
		return firstUnsupported;
	}
	
	//	Then between the two of those, which is the earliest
	if ([[lowestFutureMessageDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] < [[lowestFutureMailDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue]) {
		firstUnsupported = [lowestFutureMessageDict valueForKey:kMBMUUIDLatestVersionKey];
	}
	else {
		firstUnsupported = [lowestFutureMailDict valueForKey:kMBMUUIDLatestVersionKey];
	}
	
	return firstUnsupported;
}

+ (NSString *)currentMailUUID {
	if ([self sharedInstance].mailUUID == nil) {
		NSBundle	*aBundle = [NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:kMBMMailBundleIdentifier]];
		[self sharedInstance].mailUUID = [[aBundle infoDictionary] valueForKey:kMBMMailBundleUUIDKey];
	}
	return [self sharedInstance].mailUUID;
}

+ (NSString *)currentMessageUUID {
	if ([self sharedInstance].messageUUID == nil) {
		NSString	*messageBundlePath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSSystemDomainMask, NO) lastObject] stringByAppendingPathComponent:kMBMMessageBundlePath];
		NSBundle	*aBundle = [NSBundle bundleWithPath:messageBundlePath];
		[self sharedInstance].messageUUID = [[aBundle infoDictionary] valueForKey:kMBMMailBundleUUIDKey];
	}
	return [self sharedInstance].messageUUID;
}

+ (NSString *)filename {
	return kMBMHistoricalUUIDFileName;
}

#pragma mark - Internal Methods

+ (NSDictionary *)latestVersionsInList:(NSArray *)uuidList {
	
	NSDictionary	*mailDict = nil;
	NSDictionary	*messageDict = nil;
	//	Look through all supported values, each time saving the later one
	for (NSString *aUUIDValue in uuidList) {
		NSDictionary	*anInfoDict = [[self sharedInstance].contents valueForKey:aUUIDValue];
		if ([[anInfoDict valueForKey:kMBMUUIDTypeKey] isEqualToString:kMBMUUIDTypeValueMail]) {
			if ((mailDict == nil) || 
				([[anInfoDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] > [[mailDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue])) {
				mailDict = anInfoDict;
			}
		}
		else if ([[anInfoDict valueForKey:kMBMUUIDTypeKey] isEqualToString:kMBMUUIDTypeValueMessage])  {
			if ((messageDict == nil) || 
				([[anInfoDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] > [[messageDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue])) {
				messageDict = anInfoDict;
			}
		}
	}
	
	return [NSDictionary dictionaryWithObjectsAndKeys:mailDict, LATEST_MAIL_KEY, messageDict, LATEST_MESSAGE_KEY, nil];
}

+ (MBMUUIDList *)sharedInstance {
	static dispatch_once_t	once;
	static MBMUUIDList	*sharedHelper;
	
	dispatch_once(&once, ^{ sharedHelper = [[self alloc] init]; });
	return sharedHelper;
}

@end
