//
//  NSUserDefaults+MPCShared.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "NSUserDefaults+MPCShared.h"

@implementation NSUserDefaults (MPCShared)


- (NSDictionary *)defaultsForMailBundle:(MPCMailBundle *)mailBundle {
	//	Get the defaults from the shared domain name and return the value for the bundle
	NSDictionary	*defaultsDict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:kMPCUserDefaultSharedDomainName];
	NSDictionary	*bundleDefaults = [defaultsDict valueForKey:mailBundle.identifier];
	if (bundleDefaults == nil) {
		bundleDefaults = [NSDictionary dictionary];
	}
	return bundleDefaults;
}

- (NSMutableDictionary *)mutableDefaultsForMailBundle:(MPCMailBundle *)mailBundle {
	return [[[self defaultsForMailBundle:mailBundle] mutableCopy] autorelease];
}

- (void)setDefaults:(NSDictionary *)newValues forMailBundle:(MPCMailBundle *)mailBundle {
	//	Update user defaults with new values
	NSMutableDictionary	*changedDefaults = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:kMPCUserDefaultSharedDomainName] mutableCopy];
	[changedDefaults setObject:newValues forKey:mailBundle.identifier];
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:changedDefaults forName:kMPCUserDefaultSharedDomainName];
	[changedDefaults release];
}

@end
