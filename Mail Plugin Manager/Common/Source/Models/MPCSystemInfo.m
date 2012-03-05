//
//  MBMSystemInfo.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 11/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MPCSystemInfo.h"
#import "MPCMailBundle.h"
#import "MPCUUIDList.h"

#import <sys/sysctl.h>

@interface MPCSystemInfo ()
@property	(nonatomic, copy)	NSString		*systemVersion;
@property	(nonatomic, copy)	NSString		*systemBuild;
@property	(nonatomic, copy)	NSString		*mailShortVersion;
@property	(nonatomic, copy)	NSString		*mailVersion;
@property	(nonatomic, copy)	NSString		*messageShortVersion;
@property	(nonatomic, copy)	NSString		*messageVersion;
@property	(nonatomic, copy)	NSString		*hardware;
@property	(nonatomic, retain)	NSDictionary	*completeInfo;

+ (MPCSystemInfo *)sharedInstance;
@end

@implementation MPCSystemInfo

@synthesize systemVersion = _systemVersion;
@synthesize systemBuild = _systemBuild;
@synthesize mailShortVersion = _mailShortVersion;
@synthesize mailVersion = _mailVersion;
@synthesize messageShortVersion = _messageShortVersion;
@synthesize messageVersion = _messageVersion;
@synthesize hardware = _hardware;
@synthesize completeInfo = _completeInfo;


- (NSString *)systemVersion {
	if (_systemVersion == nil) {
		SInt32	versionMajor, versionMinor, versionBugFix;
		Gestalt(gestaltSystemVersionMajor, &versionMajor);
		Gestalt(gestaltSystemVersionMinor, &versionMinor);
		Gestalt(gestaltSystemVersionBugFix, &versionBugFix);
		_systemVersion = [[NSString stringWithFormat:@"%d.%d.%d", versionMajor, versionMinor, versionBugFix] retain];
	}
	return _systemVersion;
}

- (NSString *)systemBuild {
	if (_systemBuild == nil) {
		NSDictionary *systemVersionPlist = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
		_systemBuild = [[NSString alloc] initWithString:[systemVersionPlist objectForKey:@"ProductBuildVersion"]];
	}
	return _systemBuild;
}

- (NSString *)mailShortVersion {
	if (_mailShortVersion == nil) {
		NSBundle	*aBundle = [NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:kMBMMailBundleIdentifier]];
		_mailShortVersion = [[NSString alloc] initWithString:[[aBundle infoDictionary] valueForKey:@"CFBundleShortVersionString"]];
	}
	return _mailShortVersion;
}

- (NSString *)mailVersion {
	if (_mailVersion == nil) {
		NSBundle	*aBundle = [NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:kMBMMailBundleIdentifier]];
		_mailVersion = [[NSString alloc] initWithString:[[aBundle infoDictionary] valueForKey:@"CFBundleVersion"]];
	}
	return _mailVersion;
}

- (NSString *)messageShortVersion {
	if (_messageShortVersion == nil) {
		NSString	*frameworkPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSSystemDomainMask, NO) lastObject] stringByAppendingPathComponent:kMBMMessageBundlePath];
		NSBundle	*aBundle = [NSBundle bundleWithPath:frameworkPath];
		_messageShortVersion = [[NSString alloc] initWithString:[[aBundle infoDictionary] valueForKey:@"CFBundleShortVersionString"]];
	}
	return _messageShortVersion;
}

- (NSString *)messageVersion {
	if (_messageVersion == nil) {
		NSString	*frameworkPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSSystemDomainMask, NO) lastObject] stringByAppendingPathComponent:kMBMMessageBundlePath];
		NSBundle	*aBundle = [NSBundle bundleWithPath:frameworkPath];
		_messageVersion = [[NSString alloc] initWithString:[[aBundle infoDictionary] valueForKey:@"CFBundleVersion"]];
	}
	return _messageVersion;
}

- (NSString *)hardware {
	if (_hardware == nil) {
		int        modelInfo[2] = { CTL_HW, HW_MODEL };
		size_t     modelSize;
		
		if (sysctl(modelInfo, 2, NULL, &modelSize, NULL, 0) == 0) {
			
			void	*modelData = malloc(modelSize);
			if (modelData) {
				if (sysctl(modelInfo, 2, modelData, &modelSize, NULL, 0) == 0) {
					_hardware = [[NSString alloc] initWithUTF8String:modelData];
				}
				free(modelData);
			}
		}
	}
	return _hardware;
}

- (NSDictionary *)completeInfo {
	if (_completeInfo == nil) {
		NSMutableDictionary	*sysInfo = [NSMutableDictionary dictionaryWithCapacity:6];
		
		//	[System, Mail, Message.framework (version & build)], hardware device, [plugins installed, plugins disabled (including paths)]
		[sysInfo setObject:[NSDictionary dictionaryWithObjectsAndKeys:[self systemVersion], kMBMSysInfoVersionKey, [self systemBuild], kMBMSysInfoBuildKey, nil] forKey:kMBMSysInfoSystemKey];
		[sysInfo setObject:[NSDictionary dictionaryWithObjectsAndKeys:[self mailShortVersion], kMBMSysInfoVersionKey, [self mailVersion], kMBMSysInfoBuildKey, [MPCUUIDList currentMailUUID], kMBMSysInfoUUIDKey, nil] forKey:kMBMSysInfoMailKey];
		[sysInfo setObject:[NSDictionary dictionaryWithObjectsAndKeys:[self messageShortVersion], kMBMSysInfoVersionKey, [self messageVersion], kMBMSysInfoBuildKey, [MPCUUIDList currentMessageUUID], kMBMSysInfoUUIDKey, nil] forKey:kMBMSysInfoMessageKey];
		[sysInfo setObject:[self hardware] forKey:kMBMSysInfoHardwareKey];
		NSArray				*bundles = [MPCMailBundle allActiveMailBundlesShouldLoadInfo:NO];
		NSMutableArray		*bundleInfoList = [NSMutableArray arrayWithCapacity:[bundles count]];
		for (MPCMailBundle *aBundle in bundles) {
			[bundleInfoList addObject:[NSDictionary dictionaryWithObjectsAndKeys:aBundle.path, kMBMPathKey, aBundle.version, kMBMVersionKey, aBundle.name, kMBMNameKey, nil]];
		}
		[sysInfo setObject:bundleInfoList forKey:kMBMSysInfoInstalledMailPluginsKey];
		bundles = [MPCMailBundle allDisabledMailBundlesShouldLoadInfo:NO];
		bundleInfoList = [NSMutableArray arrayWithCapacity:[bundles count]];
		for (MPCMailBundle *aBundle in bundles) {
			[bundleInfoList addObject:[NSDictionary dictionaryWithObjectsAndKeys:aBundle.path, kMBMPathKey, aBundle.version, kMBMVersionKey, aBundle.name, kMBMNameKey, nil]];
		}
		[sysInfo setObject:bundleInfoList forKey:kMBMSysInfoDisabledMailPluginsKey];
		
		_completeInfo = [[NSDictionary alloc] initWithDictionary:sysInfo];
	}
	return _completeInfo;
}


#pragma mark - Class Methods

+ (MPCSystemInfo *)sharedInstance {
	static dispatch_once_t	once;
	static MPCSystemInfo	*sharedHelper;
	
	dispatch_once(&once, ^{ sharedHelper = [[self alloc] init]; });
	return sharedHelper;
}

+ (NSString *)systemVersion {
	return [[self sharedInstance] systemVersion];
}

+ (NSString *)systemBuild {
	return [[self sharedInstance] systemBuild];
}

+ (NSString *)mailShortVersion {
	return [[self sharedInstance] mailShortVersion];
}

+ (NSString *)mailVersion {
	return [[self sharedInstance] mailVersion];
}

+ (NSString *)messageShortVersion {
	return [[self sharedInstance] messageShortVersion];
}

+ (NSString *)messageVersion {
	return [[self sharedInstance] messageVersion];
}

+ (NSString *)hardware {
	return [[self sharedInstance] hardware];
}

+ (NSDictionary *)completeInfo {
	return [[self sharedInstance] completeInfo];
}





@end
