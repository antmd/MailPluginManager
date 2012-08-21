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
	if (changedDefaults == nil) {
		changedDefaults = [[NSMutableDictionary alloc] initWithCapacity:1];
	}
	[changedDefaults setObject:newValues forKey:mailBundle.identifier];
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:changedDefaults forName:kMPCUserDefaultSharedDomainName];
	[changedDefaults release];
}


- (NSDictionary *)sandboxedDomainInMailForName:(NSString *)domainName {
	
	NSDictionary	*defs = [NSDictionary dictionary];
	
	//	Check to see if we are on ML or greater
	if (IsMountainLionOrGreater()) {
	
		//	If so look for prefs in Mail's sandbox and read them in as a dict
		NSFileManager	*manager = [[[NSFileManager alloc] init] autorelease];
		NSString		*sandboxPrefsPath = [[[[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:kMPCContainersPathFormat, kMPCMailBundleIdentifier]] stringByAppendingPathComponent:kMPCPreferencesFolderName] stringByAppendingPathComponent:[domainName stringByAppendingPathExtension:kMPCPlistExtension]];
		
		if ([manager fileExistsAtPath:sandboxPrefsPath]) {
			//	Read in the file contents
			defs = [NSDictionary dictionaryWithContentsOfFile:sandboxPrefsPath];
		}
		
	}
	//	Else use persistentDomainForName
	else {
		defs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:domainName];
	}
	
	return defs;
}

- (NSMutableDictionary *)mutableSandboxedDomainInMailForName:(NSString *)domainName {
	return [[[self sandboxedDomainInMailForName:domainName] mutableCopy] autorelease];
}

- (void)setSandboxedDomain:(NSDictionary *)domainDict InMailForName:(NSString *)domainName {
	
	//	Check to see if we are on ML or greater
	if (IsMountainLionOrGreater()) {
		
		//	If so set prefs in Mail's sandbox and write them in as a dict
		NSString		*sandboxPrefsPath = [[[[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:kMPCContainersPathFormat, kMPCMailBundleIdentifier]] stringByAppendingPathComponent:kMPCPreferencesFolderName] stringByAppendingPathComponent:[domainName stringByAppendingPathExtension:kMPCPlistExtension]];
		
		if (![domainDict writeToFile:sandboxPrefsPath atomically:YES]) {
			LKErr(@"Couldn't write the plugin prefs for '%@'", domainName);
		}
		
	}
	//	Else use setPersistentDomainForName
	else {
		[[NSUserDefaults standardUserDefaults] setPersistentDomain:domainDict forName:domainName];
	}
	
}

@end
