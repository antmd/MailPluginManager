//
//  MPCUUIDList.m
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
		NSBundle	*aBundle = [NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:kMPCMailBundleIdentifier]];
		[self sharedInstance].mailUUID = [[aBundle infoDictionary] valueForKey:kMPCMailBundleUUIDKey];
	}
	return [self sharedInstance].mailUUID;
}

+ (NSString *)currentMessageUUID {
	if ([self sharedInstance].messageUUID == nil) {
		NSString	*messageBundlePath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSSystemDomainMask, NO) lastObject] stringByAppendingPathComponent:kMPCMessageBundlePath];
		NSBundle	*aBundle = [NSBundle bundleWithPath:messageBundlePath];
		[self sharedInstance].messageUUID = [[aBundle infoDictionary] valueForKey:kMPCMailBundleUUIDKey];
	}
	return [self sharedInstance].messageUUID;
}

+ (NSString *)latestOSVersionFromSupportedList:(NSArray *)supportedUUIDs {
	NSDictionary	*latestDict = [self latestUUIDDictFromSupportedList:supportedUUIDs];
	return [latestDict valueForKey:kMPCUUIDLatestOSVersionDisplayKey];
}

+ (NSString *)firstUnsupportedOSVersionFromSupportedList:(NSArray *)supportedUUIDs {
	NSDictionary	*firstUnsupportedDict = [self firstUnsupportedUUIDDictFromSupportedList:supportedUUIDs];
	return [firstUnsupportedDict valueForKey:kMPCUUIDLatestOSVersionDisplayKey];
}

+ (NSDictionary *)latestUUIDDictFromSupportedList:(NSArray *)supportedUUIDs {
	NSDictionary	*latestDicts = [self latestVersionsInList:supportedUUIDs];
	NSDictionary	*mailDict = [latestDicts valueForKey:kMPCUUIDTypeValueMail];
	NSDictionary	*messageDict = [latestDicts valueForKey:kMPCUUIDTypeValueMessage];
	
	//	If either is nil, we can't determine
	if ((mailDict == nil) || (messageDict == nil)) {
		return nil;
	}
	
	//	Then between the two of those, which is the earliest
	if ([[messageDict valueForKey:kMPCUUIDLatestVersionTestKey] integerValue] < [[mailDict valueForKey:kMPCUUIDLatestVersionTestKey] integerValue]) {
		return messageDict;
	}
	else {
		return mailDict;
	}
}

+ (NSDictionary *)firstUnsupportedUUIDDictFromSupportedList:(NSArray *)supportedUUIDs {
	NSDictionary	*latestDicts = [self firstUnsupportedVersionsInList:supportedUUIDs];
	NSDictionary	*lowestFutureMailDict = [latestDicts valueForKey:kMPCUUIDTypeValueMail];
	NSDictionary	*lowestFutureMessageDict = [latestDicts valueForKey:kMPCUUIDTypeValueMessage];
	
	//	If either is nil, we can't determine
	if ((lowestFutureMailDict == nil) || (lowestFutureMessageDict == nil)) {
		return (lowestFutureMailDict != nil)?lowestFutureMailDict:lowestFutureMessageDict;
	}
	
	//	Then between the two of those, which is the earliest
	if ([[lowestFutureMessageDict valueForKey:kMPCUUIDEarliestOSVersionKey] integerValue] < [[lowestFutureMailDict valueForKey:kMPCUUIDEarliestOSVersionKey] integerValue]) {
		return lowestFutureMessageDict;
	}
	else {
		return lowestFutureMailDict;
	}
}


+ (NSDictionary *)fullUUIDListFromSupportedList:(NSArray *)supportedUUIDs {
	NSMutableDictionary	*fullDict = [NSMutableDictionary dictionaryWithCapacity:3];
	[fullDict setObject:[self sharedInstance].contents forKey:kMPCUUIDAllUUIDListKey];
	NSDictionary	*aUUIDDict = [self latestUUIDDictFromSupportedList:supportedUUIDs];
	if (aUUIDDict) {
		[fullDict setObject:aUUIDDict forKey:kMPCUUIDLatestUUIDDictKey];
	}
	aUUIDDict = [self firstUnsupportedUUIDDictFromSupportedList:supportedUUIDs];
	if (aUUIDDict) {
		[fullDict setObject:aUUIDDict forKey:kMPCUUIDFirstUnsupportedUUIDDictKey];
	}
	return [NSDictionary dictionaryWithDictionary:fullDict];
}

+ (NSDictionary *)fullUUIDListFromBundle:(NSBundle *)pluginBundle {
	return [self fullUUIDListFromSupportedList:[[pluginBundle infoDictionary] valueForKey:kMPCMailBundleUUIDListKey]];
}


#pragma mark - Action Methods

+ (NSString *)filename {
	return kMPCUUIDListFileName;
}


#pragma mark - Internal Methods

+ (NSArray *)sortedKeysLatestFirst {
	
	NSArray		*sortedKeysLatestFirstList = [[self sharedInstance].contents keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSComparisonResult	normalResult = [[obj1 valueForKey:kMPCUUIDLatestVersionTestKey] compare:[obj2 valueForKey:kMPCUUIDLatestVersionTestKey]];
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
			([[anInfoDict valueForKey:kMPCUUIDTypeKey] isEqualToString:kMPCUUIDTypeValueMail]) && 
			([uuidList containsObject:uuidValue])) {
			
			mailDict = anInfoDict;
		}
		else if ((messageDict == nil) && 
			([[anInfoDict valueForKey:kMPCUUIDTypeKey] isEqualToString:kMPCUUIDTypeValueMessage]) && 
			([uuidList containsObject:uuidValue])) {
			
			messageDict = anInfoDict;
		}
		if ((mailDict != nil) && (messageDict != nil)) {
			break;
		}
	}
	
	return [NSDictionary dictionaryWithObjectsAndKeys:mailDict, kMPCUUIDTypeValueMail, messageDict, kMPCUUIDTypeValueMessage, nil];
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
		if ([[uuidDict valueForKey:kMPCUUIDTypeKey] isEqualToString:kMPCUUIDTypeValueMail]) {
			if ([uuidList containsObject:uuidKey]) {
				mailMatched = YES;
			}
			else if (!mailMatched) {
				lowestFutureMailDict = uuidDict;
			}
		}
		else if ([[uuidDict valueForKey:kMPCUUIDTypeKey] isEqualToString:kMPCUUIDTypeValueMessage]) {
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
	
	return [NSDictionary dictionaryWithObjectsAndKeys:lowestFutureMailDict, kMPCUUIDTypeValueMail, lowestFutureMessageDict, kMPCUUIDTypeValueMessage, nil];
}

+ (MPCUUIDList *)sharedInstance {
	static dispatch_once_t	once;
	static MPCUUIDList	*sharedHelper;
	
	dispatch_once(&once, ^{ sharedHelper = [[self alloc] init]; });
	return sharedHelper;
}

@end
