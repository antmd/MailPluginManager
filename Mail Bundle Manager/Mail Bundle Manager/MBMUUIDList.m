//
//  MBMUUIDList.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 10/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MBMUUIDList.h"


@interface MBMUUIDList ()
@property	(nonatomic, copy)	NSString	*mailUUID;
@property	(nonatomic, copy)	NSString	*messageUUID;
+ (MBMUUIDList *)sharedInstance;
+ (NSDictionary *)latestVersionsInList:(NSArray *)uuidList;
+ (NSDictionary *)firstUnsupportedVersionsInList:(NSArray *)uuidList;
@end

@implementation MBMUUIDList

@synthesize mailUUID = _mailUUID;
@synthesize messageUUID = _messageUUID;


#pragma mark - External Methods

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

+ (NSString *)latestOSVersionFromSupportedList:(NSArray *)supportedUUIDs {
	NSString		*latestSupported = NSLocalizedString(@"Unknown", @"Text indicating that we couldn't determine the latest version of the OS that this plugin supports");
	NSDictionary	*latestDict = [self latestUUIDDictFromSupportedList:supportedUUIDs];
	if (latestDict) {
		latestSupported = [latestDict valueForKey:kMBMUUIDLatestOSVersionDisplayKey];
	}
	
	return latestSupported;
}

+ (NSString *)firstUnsupportedOSVersionFromSupportedList:(NSArray *)supportedUUIDs {
	NSString		*firstUnsupported = NSLocalizedString(@"None", @"Text indicating that we couldn't find any version of the OS that this plugin does not support");
	NSDictionary	*firstUnsupportedDict = [self firstUnsupportedUUIDDictFromSupportedList:supportedUUIDs];
	if (firstUnsupportedDict) {
		firstUnsupported = [firstUnsupportedDict valueForKey:kMBMUUIDLatestOSVersionDisplayKey];
	}
	
	return firstUnsupported;
}

+ (NSDictionary *)latestUUIDDictFromSupportedList:(NSArray *)supportedUUIDs {
	NSDictionary	*latestDicts = [self latestVersionsInList:supportedUUIDs];
	NSDictionary	*mailDict = [latestDicts valueForKey:kMBMUUIDTypeValueMail];
	NSDictionary	*messageDict = [latestDicts valueForKey:kMBMUUIDTypeValueMessage];
	
	//	If either is nil, we can't determine
	if ((mailDict == nil) || (messageDict == nil)) {
		return nil;
	}
	
	//	Then between the two of those, which is the earliest
	if ([[messageDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] > [[mailDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue]) {
		return messageDict;
	}
	else {
		return mailDict;
	}
}

+ (NSDictionary *)firstUnsupportedUUIDDictFromSupportedList:(NSArray *)supportedUUIDs {
	NSDictionary	*latestDicts = [self firstUnsupportedVersionsInList:supportedUUIDs];
	NSDictionary	*lowestFutureMailDict = [latestDicts valueForKey:kMBMUUIDTypeValueMail];
	NSDictionary	*lowestFutureMessageDict = [latestDicts valueForKey:kMBMUUIDTypeValueMessage];
	
	//	If either is nil, we can't determine
	if ((lowestFutureMailDict == nil) || (lowestFutureMessageDict == nil)) {
		return nil;
	}
	
	//	Then between the two of those, which is the earliest
	if ([[lowestFutureMessageDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] < [[lowestFutureMailDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue]) {
		return lowestFutureMessageDict;
	}
	else {
		return lowestFutureMailDict;
	}
}


+ (NSDictionary *)fullUUIDListFromSupportedList:(NSArray *)supportedUUIDs {
	NSMutableDictionary	*fullDict = [NSMutableDictionary dictionaryWithCapacity:3];
	[fullDict setObject:[self sharedInstance].contents forKey:kMBMUUIDAllUUIDListKey];
	NSDictionary	*aUUIDDict = [self latestUUIDDictFromSupportedList:supportedUUIDs];
	if (aUUIDDict) {
		[fullDict setObject:aUUIDDict forKey:kMBMUUIDLatestUUIDDictKey];
	}
	aUUIDDict = [self firstUnsupportedUUIDDictFromSupportedList:supportedUUIDs];
	if (aUUIDDict) {
		[fullDict setObject:aUUIDDict forKey:kMBMUUIDFirstUnsupportedUUIDDictKey];
	}
	return [NSDictionary dictionaryWithDictionary:fullDict];
}

+ (NSDictionary *)fullUUIDListFromBundle:(NSBundle *)pluginBundle {
	return [self fullUUIDListFromSupportedList:[[pluginBundle infoDictionary] valueForKey:kMBMMailBundleUUIDListKey]];
}


#pragma mark - Action Methods

+ (void)loadUUIDListFromCloud {
	//	Try to load the plist from the remote server
	NSURL			*theURL = [NSURL URLWithString:@"http://lkslocal/mbm-uuids.plist"];
	[self loadListFromCloudURL:theURL];
}

+ (NSString *)filename {
	return kMBMUUIDListFileName;
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
	
	return [NSDictionary dictionaryWithObjectsAndKeys:mailDict, kMBMUUIDTypeValueMail, messageDict, kMBMUUIDTypeValueMessage, nil];
}

+ (NSDictionary *)firstUnsupportedVersionsInList:(NSArray *)uuidList {
	NSDictionary	*latestDicts = [self latestVersionsInList:uuidList];
	NSDictionary	*latestMailDict = [latestDicts valueForKey:kMBMUUIDTypeValueMail];
	NSDictionary	*latestMessageDict = [latestDicts valueForKey:kMBMUUIDTypeValueMessage];
	NSDictionary	*lowestFutureMailDict = nil;
	NSDictionary	*lowestFutureMessageDict = nil;

	//	Look though all the defined UUIDs in our file
	NSDictionary	*allContents = [self sharedInstance].contents;
	for (NSString *aUUID in [allContents allKeys]) {
		NSDictionary	*uuidDict = [allContents valueForKey:aUUID];
		
		//	For each type save the one that is greater than the latest from the list, but less that any already saved
		if ([[uuidDict valueForKey:kMBMUUIDTypeKey] isEqualToString:kMBMUUIDTypeValueMail]) {
			if (((lowestFutureMailDict == nil) &&
				 ([[uuidDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] > [[latestMailDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue])) ||
				(([[uuidDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] > [[latestMailDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue]) &&
				 ([[uuidDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] < [[lowestFutureMailDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue]))) {
					lowestFutureMailDict = uuidDict;
				}
		}
		else if ([[uuidDict valueForKey:kMBMUUIDTypeKey] isEqualToString:kMBMUUIDTypeValueMessage]) {
			if (((lowestFutureMessageDict == nil) &&
				 ([[uuidDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] > [[latestMessageDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue])) ||
				(([[uuidDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] > [[latestMessageDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue]) &&
				 ([[uuidDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] < [[lowestFutureMessageDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue]))) {
					lowestFutureMessageDict = uuidDict;
				}
		}
	}
	
	return [NSDictionary dictionaryWithObjectsAndKeys:lowestFutureMailDict, kMBMUUIDTypeValueMail, lowestFutureMessageDict, kMBMUUIDTypeValueMessage, nil];
}

+ (MBMUUIDList *)sharedInstance {
	static dispatch_once_t	once;
	static MBMUUIDList	*sharedHelper;
	
	dispatch_once(&once, ^{ sharedHelper = [[self alloc] init]; });
	return sharedHelper;
}

@end
