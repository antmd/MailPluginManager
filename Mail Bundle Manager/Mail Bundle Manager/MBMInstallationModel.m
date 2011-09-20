//
//  MBMInstallationModel.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MBMInstallationModel.h"
#import "MBMMailBundle.h"


@interface MBMInstallationModel ()
- (BOOL)installItem:(MBMInstallationItem *)anItem;
@end

@implementation MBMInstallationModel

#pragma mark - Accessors

@synthesize minOSVersion = _minOSVersion;
@synthesize maxOSVersion = _maxOSVersion;
@synthesize minMailVersion = _minMailVersion;
@synthesize bundleManager = _bundleManager;
@synthesize installationItemList = _installationItemList;

- (BOOL)shouldInstallManager {
	return !IsEmpty(self.bundleManager.path);
}


#pragma mark - Installer Methods

- (BOOL)installAll {
	
	CGFloat	temp = kMBMNoVersionRequirement;
	NSLog(@"%.2f", temp);
	
	//	Ensure that the versions all check out
	CGFloat	currentVersion = macOSXVersion();
	if ((self.minOSVersion != kMBMNoVersionRequirement) && (currentVersion < self.minOSVersion)) {
			LKLog(@"ERROR:Minimum OS version (%3.2f) requirement not met (%3.2f)", self.minOSVersion, currentVersion);
			return NO;
	}
	if ((self.maxOSVersion != kMBMNoVersionRequirement) && (currentVersion > self.maxOSVersion)) {
		LKLog(@"ERROR:Maximum OS version (%3.2f) requirement not met (%3.2f)", self.maxOSVersion, currentVersion);
		return NO;
	}
	if (self.minMailVersion != kMBMNoVersionRequirement) {
		currentVersion = mailVersion();
		if (currentVersion > self.minMailVersion) {
			LKLog(@"ERROR:Minimum Mail version (%3.2f) requirement not met (%3.2f)", self.minMailVersion, currentVersion);
			return NO;
		}
	}
	
	BOOL	result = [self installBundleManager];
	if (result) {
		result = [self installItems];
	}
	return result;
}

- (BOOL)installItems {
	
	NSFileManager	*manager = [NSFileManager defaultManager];

	//	First just ensure that the all items are there to copy
	for (MBMInstallationItem *anItem in self.installationItemList) {
		if (![manager fileExistsAtPath:anItem.path]) {
			ALog(@"ERROR:The source path for the item (%@) [%@] is invalid.", anItem.name, anItem.path);
			return NO;
		}
	}
	
	//	Then install each one
	for (MBMInstallationItem *anItem in self.installationItemList) {
		[self installItem:anItem];
	}
	
	return YES;
}

- (BOOL)installBundleManager {
	
	NSFileManager	*manager = [NSFileManager defaultManager];
	NSWorkspace		*workspace = [NSWorkspace sharedWorkspace];
	
	//	Ensure that the source bundle is where we think it is
	if (![manager fileExistsAtPath:self.bundleManager.path] || ![workspace isFilePackageAtPath:self.bundleManager.path]) {
		ALog(@"ERROR:The source path for the bundle manager (%@) is invalid.", self.bundleManager.path);
		return NO;
	}
	
	//	First get any existing bundle at the destination
	NSBundle	*destBundle = nil;
	if ([manager fileExistsAtPath:self.bundleManager.destinationPath]) {
		//	Then ensure that it is a package
		if ([workspace isFilePackageAtPath:self.bundleManager.destinationPath]) {
			destBundle = [NSBundle bundleWithPath:self.bundleManager.destinationPath];
		}
	}
	//	If there is a destination already, check it's bundle id matches and version is < installing one
	if (destBundle) {
		NSBundle	*sourceBundle = [NSBundle bundleWithPath:self.bundleManager.path];
		
		BOOL		isSameBundleID = [[sourceBundle bundleIdentifier] isEqualToString:[destBundle bundleIdentifier]];
		BOOL		isSourceVersionGreater = ([MBMMailBundle compareVersion:[[sourceBundle infoDictionary] valueForKey:(NSString *)kCFBundleVersionKey] toVersion:[[destBundle infoDictionary] valueForKey:(NSString *)kCFBundleVersionKey]] == NSOrderedDescending);
		
		//	There is a serious problem if the bundle ids are different
		if (!isSameBundleID) {
			
			ALog(@"ERROR:Trying to install a bundle manager (%@) with different BundleID [%@] over existing app (%@) [%@]", [[sourceBundle infoDictionary] valueForKey:(NSString *)kCFBundleNameKey], [sourceBundle bundleIdentifier], [[destBundle infoDictionary] valueForKey:(NSString *)kCFBundleNameKey], [destBundle bundleIdentifier]);
			return NO;
		}
		
		//	If the source version is not greater then just return yes and leave the existing one
		if (!isSourceVersionGreater) {
			LKLog(@"Not actually copying the Bundle Manager since a recent version is already at destination");
			return YES;
		}
	}
	
	//	Install the bundle
	return [self installItem:self.bundleManager];
}

- (BOOL)installItem:(MBMInstallationItem *)anItem {
	
	NSFileManager	*manager = [NSFileManager defaultManager];
	
	//	Before installing an actual mail bundle, ensure that the plugin is actaully update to date
	if (anItem.isMailBundle) {
		//	Get the values to test
		NSBundle	*aBundle = [NSBundle bundleWithPath:anItem.path];
		NSArray		*supportedUUIDs = [[aBundle infoDictionary] valueForKey:kMBMMailBundleUUIDListKey];
		aBundle = [NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:kMBMMailBundleIdentifier]];
		NSString	*mailUUID = [[aBundle infoDictionary] valueForKey:kMBMMailBundleUUIDKey];
		NSString	*messageBundlePath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSSystemDomainMask, NO) lastObject];
		messageBundlePath = [messageBundlePath stringByAppendingPathComponent:kMBMMessageBundlePath];
		aBundle = [NSBundle bundleWithPath:messageBundlePath];
		NSString	*messageUUID = [[aBundle infoDictionary] valueForKey:kMBMMailBundleUUIDKey];
		
		//	Test to ensure that the plugin list contains both the mail and message UUIDs
		if (![supportedUUIDs containsObject:mailUUID] || ![supportedUUIDs containsObject:messageUUID]) {
			LKLog(@"This Mail Plugin will not work with this version of Mail");
			return NO;
		}
	}

	//	Make sure that the destination folder exists
	NSError	*error;
	if (![manager fileExistsAtPath:[anItem.destinationPath stringByDeletingLastPathComponent]]) {
		if (![manager createDirectoryAtPath:[anItem.destinationPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error]) {
			ALog(@"ERROR:Couldn't create folder to copy item '%@' into:%@", anItem.name, error);
			return NO;
		}
	}

	BOOL	isFolder;
	[manager fileExistsAtPath:[anItem.destinationPath stringByDeletingLastPathComponent] isDirectory:&isFolder];
	if (!isFolder) {
		ALog(@"ERROR:Can't copy item '%@' to location that is actually a file:%@", anItem.name, [anItem.destinationPath stringByDeletingLastPathComponent]);
		return NO;
	}
	
	//	Now do the copy, replacing anything that is already there
	if (![manager copyItemAtPath:anItem.path toPath:anItem.destinationPath error:&error]) {
		ALog(@"ERROR:Unable to copy item '%@' to %@\n%@", anItem.name, anItem.destinationPath, error);
		return NO;
	}
	
	return YES;
}


#pragma mark - Memory Management

- (id)initWithInstallPackageAtPath:(NSString *)installFilePath {

	//	If there is no installation manifest inside, return nil
	NSString	*manifestPath = [[installFilePath stringByAppendingPathComponent:kMBMInstallManifestName] stringByAppendingPathExtension:kMBMPlistExtension];
	if (![[NSFileManager defaultManager] fileExistsAtPath:manifestPath]) {
		ALog(@"Error: Installation File doesn't have a %@.%@ file.", kMBMInstallManifestName, kMBMPlistExtension);
		return nil;
	}

	//	Otherwise init as normal
	self = [super init];
	if (self) {
		
		//	Get the installation manifest contents and the items
		NSDictionary	*manifestDict = [NSDictionary dictionaryWithContentsOfFile:manifestPath];
		NSArray			*installItems = [manifestDict valueForKey:kMBMInstallItemsKey];
		NSMutableArray	*newItems = [NSMutableArray arrayWithCapacity:[installItems count]];
		
		//	Create each of the items
		for (NSDictionary *itemDict in installItems) {
			MBMInstallationItem	*anItem = [[[MBMInstallationItem alloc] initWithDictionary:itemDict fromInstallationFilePath:installFilePath] autorelease];
			if (anItem.isBundleManager) {
				_bundleManager = [anItem retain];
			}
			else {
				[newItems addObject:anItem];
			}
		}
		
		//	Set our items list to the new array
		_installationItemList = [[NSArray arrayWithArray:newItems] retain];
		
		//	See if there are any version requirements - set defaults first
		_minOSVersion = kMBMNoVersionRequirement;
		_maxOSVersion = kMBMNoVersionRequirement;
		_minMailVersion = kMBMNoVersionRequirement;
		if ([manifestDict valueForKey:kMBMMinOSVersionKey]) {
			_minOSVersion = [[manifestDict valueForKey:kMBMMinOSVersionKey] floatValue];
		}
		if ([manifestDict valueForKey:kMBMMaxOSVersionKey]) {
			_maxOSVersion = [[manifestDict valueForKey:kMBMMaxOSVersionKey] floatValue];
		}
		if ([manifestDict valueForKey:kMBMMinMailVersionKey]) {
			_minMailVersion = [[manifestDict valueForKey:kMBMMinMailVersionKey] floatValue];
		}
		
	}
	return self;
}

- (void)dealloc {
	[_bundleManager release];
	_bundleManager = nil;
	[_installationItemList release];
	_installationItemList = nil;

	[super dealloc];
}


- (NSString *)description {
	NSMutableString	*result = [NSMutableString string];
	
	[result appendFormat:@">>MBMInstallationModel [%p]  ", self];
	[result appendFormat:@"minOSVersion:%3.2f  ", self.minOSVersion];
	[result appendFormat:@"maxOSVersion:%3.2f  ", self.maxOSVersion];
	[result appendFormat:@"minMailVersion:%3.2f  ", self.minMailVersion];
	[result appendFormat:@"shouldInstallManager:%@\n", [NSString stringWithBool:self.shouldInstallManager]];
	[result appendFormat:@"bundleManager:\n\t(%@)\n", self.bundleManager];
	[result appendString:@"installItems:{\n"];
	for (MBMInstallationItem *anItem in self.installationItemList) {
		[result appendFormat:@"\t[%@]\n", anItem];
	}
	[result appendString:@"}"];
	
	return [NSString stringWithString:result];
}

@end


CGFloat macOSXVersion(void) {
	// use a static because we only really need to get the version once.
	static CGFloat minorVer = 1.0;
	if (minorVer == 1.0) {
		SInt32 version = 0;
		OSErr err = Gestalt(gestaltSystemVersionMinor, &version);
		if (!err) {
			minorVer = 10.0 + (0.1 * version);
		}
	}
	return minorVer;
}

CGFloat mailVersion(void) {
	static CGFloat mailVer = 1.0;
	if (mailVer == 1.0) {
		NSBundle	*mailBundle = [NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:kMBMMailBundleIdentifier]];
		NSString	*mailVersionString = [[mailBundle infoDictionary] valueForKey:(NSString *)kCFBundleVersionKey];
		mailVer = [mailVersionString floatValue];
	}
	return mailVer;
}


