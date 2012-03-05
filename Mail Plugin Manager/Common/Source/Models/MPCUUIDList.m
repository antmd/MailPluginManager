//
//  MBMUUIDList.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 10/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MPCUUIDList.h"


@interface MPCUUIDList ()
@property	(nonatomic, copy)	NSString	*mailUUID;
@property	(nonatomic, copy)	NSString	*messageUUID;
+ (MPCUUIDList *)sharedInstance;
+ (NSArray *)sortedKeysLatestFirst;
+ (NSDictionary *)latestVersionsInList:(NSArray *)uuidList;
+ (NSDictionary *)firstUnsupportedVersionsInList:(NSArray *)uuidList;
@end

@implementation MPCUUIDList

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
	NSDictionary	*latestDict = [self latestUUIDDictFromSupportedList:supportedUUIDs];
	return [latestDict valueForKey:kMBMUUIDLatestOSVersionDisplayKey];
}

+ (NSString *)firstUnsupportedOSVersionFromSupportedList:(NSArray *)supportedUUIDs {
	NSDictionary	*firstUnsupportedDict = [self firstUnsupportedUUIDDictFromSupportedList:supportedUUIDs];
	return [firstUnsupportedDict valueForKey:kMBMUUIDLatestOSVersionDisplayKey];
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
	if ([[messageDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] < [[mailDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue]) {
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
		return (lowestFutureMailDict != nil)?lowestFutureMailDict:lowestFutureMessageDict;
	}
	
	//	Then between the two of those, which is the earliest
	if ([[lowestFutureMessageDict valueForKey:kMBMUUIDEarliestOSVersionKey] integerValue] < [[lowestFutureMailDict valueForKey:kMBMUUIDEarliestOSVersionKey] integerValue]) {
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

+ (NSString *)filename {
	return kMBMUUIDListFileName;
}


#pragma mark - Internal Methods

+ (NSArray *)sortedKeysLatestFirst {
	
	NSArray		*sortedKeysLatestFirstList = [[self sharedInstance].contents keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSComparisonResult	normalResult = [[obj1 valueForKey:kMBMUUIDLatestVersionTestKey] compare:[obj2 valueForKey:kMBMUUIDLatestVersionTestKey]];
		return (normalResult==NSOrderedSame?NSOrderedSame:(normalResult==NSOrderedAscending?NSOrderedDescending:NSOrderedAscending));
	}];
	
	return sortedKeysLatestFirstList;
}

+ (NSDictionary *)latestVersionsInList:(NSArray *)uuidList {
	
	NSDictionary	*mailDict = nil;
	NSDictionary	*messageDict = nil;
	NSArray			*sortedKeysLatestFirst = [MPCUUIDList sortedKeysLatestFirst];
	//	Look through the sorted keys until we find matches
	for (NSString *uuidValue in sortedKeysLatestFirst) {
		NSDictionary	*anInfoDict = [[self sharedInstance].contents valueForKey:uuidValue];
		if ((mailDict == nil) && 
			([[anInfoDict valueForKey:kMBMUUIDTypeKey] isEqualToString:kMBMUUIDTypeValueMail]) && 
			([uuidList containsObject:uuidValue])) {
			
			mailDict = anInfoDict;
		}
		else if ((messageDict == nil) && 
			([[anInfoDict valueForKey:kMBMUUIDTypeKey] isEqualToString:kMBMUUIDTypeValueMessage]) && 
			([uuidList containsObject:uuidValue])) {
			
			messageDict = anInfoDict;
		}
		if ((mailDict != nil) && (messageDict != nil)) {
			break;
		}
	}
	
	return [NSDictionary dictionaryWithObjectsAndKeys:mailDict, kMBMUUIDTypeValueMail, messageDict, kMBMUUIDTypeValueMessage, nil];
}

+ (NSDictionary *)firstUnsupportedVersionsInList:(NSArray *)uuidList {
	NSDictionary	*lowestFutureMailDict = nil;
	NSDictionary	*lowestFutureMessageDict = nil;

	//	Look though all the defined UUIDs in our file
	NSDictionary	*allContents = [self sharedInstance].contents;
	NSArray		*sortedKeysLatestFirst = [MPCUUIDList sortedKeysLatestFirst];
	BOOL		mailMatched = NO;
	BOOL		messageMatched = NO;
	for (NSString *uuidKey in sortedKeysLatestFirst) {
		NSDictionary	*uuidDict = [allContents valueForKey:uuidKey];
		if ([[uuidDict valueForKey:kMBMUUIDTypeKey] isEqualToString:kMBMUUIDTypeValueMail]) {
			if ([uuidList containsObject:uuidKey]) {
				mailMatched = YES;
			}
			else if (!mailMatched) {
				lowestFutureMailDict = uuidDict;
			}
		}
		else if ([[uuidDict valueForKey:kMBMUUIDTypeKey] isEqualToString:kMBMUUIDTypeValueMessage]) {
			if ([uuidList containsObject:uuidKey]) {
				messageMatched = YES;
			}
			else if (!messageMatched) {
				lowestFutureMessageDict = uuidDict;
			}
		}
		if (mailMatched && messageMatched) {
			break;
		}
	}
	
	return [NSDictionary dictionaryWithObjectsAndKeys:lowestFutureMailDict, kMBMUUIDTypeValueMail, lowestFutureMessageDict, kMBMUUIDTypeValueMessage, nil];
}

+ (MPCUUIDList *)sharedInstance {
	static dispatch_once_t	once;
	static MPCUUIDList	*sharedHelper;
	
	dispatch_once(&once, ^{ sharedHelper = [[self alloc] init]; });
	return sharedHelper;
}

@end
