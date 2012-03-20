//
//  MPCSparkleDelegate.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MPCSparkleDelegate.h"
#import "MPCSystemInfo.h"

@implementation MPCSparkleDelegate

@synthesize mailBundle = _mailBundle;
//@synthesize relaunchPath = _relaunchPath;
//@synthesize quitMail = _quitMail;
//@synthesize quitManager = _quitManager;

- (id)initWithMailBundle:(MPCMailBundle *)aMailBundle {
    self = [super init];
    if (self) {
        // Initialization code here.
		_mailBundle = [aMailBundle retain];
    }
    
    return self;
}

- (void)dealloc {
	[_mailBundle release];
	_mailBundle = nil;
	[super dealloc];
}

- (void)updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)update {
	//	Post a distributed notification indicating that the bundle is up-to-date
	NSDistributedNotificationCenter	*center = [NSDistributedNotificationCenter defaultCenter];
	[center postNotificationName:kMPCBundleUpdateStatusDistNotification object:self.mailBundle.identifier userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"uptodate"] deliverImmediately:NO];
}

- (void)updaterDidNotFindUpdate:(SUUpdater *)update {
	//	Post a distributed notification indicating that the bundle is up-to-date
	NSDistributedNotificationCenter	*center = [NSDistributedNotificationCenter defaultCenter];
	[center postNotificationName:kMPCBundleUpdateStatusDistNotification object:self.mailBundle.identifier userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"uptodate"] deliverImmediately:NO];
}

//	Always postpone (indefinitely) the relaunch, but send a notification that the update is done.
- (BOOL)updater:(SUUpdater *)updater shouldPostponeRelaunchForUpdate:(SUAppcastItem *)update untilInvoking:(NSInvocation *)invocation {
	//	Change the invocation to set the Relaunch value to NO
	BOOL	relaunch = NO;
	[invocation setArgument:&relaunch atIndex:2];
	[[NSNotificationCenter defaultCenter] postNotificationName:kMPCDoneUpdatingMailBundleNotification object:self.mailBundle userInfo:[NSDictionary dictionaryWithObjectsAndKeys:invocation, @"invoker", nil]];
	return YES;
}

- (NSArray *)feedParametersForUpdater:(SUUpdater *)updater sendingSystemProfile:(BOOL)sendingProfile {
	if (sendingProfile) {
		NSMutableArray	*params = [NSMutableArray arrayWithCapacity:4];
		[params addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"mv", @"key", [MPCSystemInfo mailVersion], @"value", @"Mail Version", @"displayKey", [MPCSystemInfo mailVersion], @"displayValue", nil]];
		[params addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"msv", @"key", [MPCSystemInfo mailShortVersion], @"value", @"Mail Short Version", @"displayKey", [MPCSystemInfo mailShortVersion], @"displayValue", nil]];
		[params addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"mfv", @"key", [MPCSystemInfo messageVersion], @"value", @"Message Framework Version", @"displayKey", [MPCSystemInfo messageVersion], @"displayValue", nil]];
		[params addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"mfsv", @"key", [MPCSystemInfo messageShortVersion], @"value", @"Message Framework Short Version", @"displayKey", [MPCSystemInfo messageShortVersion], @"displayValue", nil]];
		
		NSDictionary	*infoDict = [self.mailBundle.bundle infoDictionary];
		[params addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"pv", @"key", [infoDict valueForKey:(NSString *)kCFBundleVersionKey], @"value", @"Plugin Version", @"displayKey", [infoDict valueForKey:(NSString *)kCFBundleVersionKey], @"displayValue", nil]];
		[params addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"psv", @"key", [infoDict valueForKey:@"CFBundleShortVersionString"], @"value", @"Plugin Short Version", @"displayKey", [infoDict valueForKey:@"CFBundleShortVersionString"], @"displayValue", nil]];
		
		NSArray		*supplementalItems = [infoDict valueForKey:kMPCSupplementalSparkleFeedParametersKey];
		NSInteger	suppCounter = 1;
		for (NSString *aKey in supplementalItems) {
			if (!IsEmpty(aKey)) {
				NSString	*value = [infoDict valueForKey:aKey];
				if (!IsEmpty(value)) {
					[params addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"sup%d", suppCounter], @"key", value, @"value", [NSString stringWithFormat:@"Supplement %d Key", suppCounter], @"displayKey", value, @"displayValue", nil]];
				}
			}
			suppCounter++;
		}
		
		return params;
	}
	return nil;
}


@end
