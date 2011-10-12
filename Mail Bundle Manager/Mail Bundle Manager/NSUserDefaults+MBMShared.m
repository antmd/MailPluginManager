//
//  NSUserDefaults+MBMShared.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "NSUserDefaults+MBMShared.h"

@implementation NSUserDefaults (MBMShared)


- (NSDictionary *)defaultsForMailBundle:(MBMMailBundle *)mailBundle {
	//	Get the defaults from the shared domain name nand return the value for the bundle
	NSDictionary	*defaultsDict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:kMBMUserDefaultSharedDomainName];
	return [defaultsDict valueForKey:mailBundle.identifier];
}

- (NSMutableDictionary *)mutableDefaultsForMailBundle:(MBMMailBundle *)mailBundle {
	return [[[self defaultsForMailBundle:mailBundle] mutableCopy] autorelease];
}

- (void)setDefaults:(NSDictionary *)newValues forMailBundle:(MBMMailBundle *)mailBundle {
	//	Update user defaults with new values
	NSMutableDictionary	*changedDefaults = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:kMBMUserDefaultSharedDomainName] mutableCopy];
	[changedDefaults setObject:newValues forKey:mailBundle.identifier];
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:changedDefaults forName:kMBMUserDefaultSharedDomainName];
	[changedDefaults release];
}

@end
