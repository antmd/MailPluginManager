//
//  MBMInstallationModel.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MBMInstallationModel.h"
#import "MBMMailBundle.h"
#import "MBMConfirmationStep.h"


@interface MBMInstallationModel ()
@property	(nonatomic, copy, readwrite)	NSString			*displayName;
@property	(nonatomic, copy, readwrite)	NSString			*backgroundImagePath;
@property	(nonatomic, retain, readwrite)	MBMInstallationItem	*bundleManager;
@property	(nonatomic, retain, readwrite)	NSArray				*confirmationStepList;
@property	(nonatomic, retain, readwrite)	NSArray				*installationItemList;
@end

@implementation MBMInstallationModel

#pragma mark - Accessors

@synthesize displayName = _displayName;
@synthesize backgroundImagePath = _backgroundImagePath;
@synthesize minOSVersion = _minOSVersion;
@synthesize maxOSVersion = _maxOSVersion;
@synthesize minMailVersion = _minMailVersion;
@synthesize bundleManager = _bundleManager;
@synthesize confirmationStepList = _confirmationStepList;
@synthesize installationItemList = _installationItemList;
@synthesize totalInstallationItemCount = _totalInstallationItemCount;
@synthesize confirmationStepCount = _confirmationStepCount;


- (BOOL)shouldInstallManager {
	return !IsEmpty(self.bundleManager.path);
}


#pragma mark - Memory Management

- (id)initWithInstallPackageAtPath:(NSString *)installFilePath {

	//	If there is no installation manifest inside, return nil
	NSString	*manifestPath = [[installFilePath stringByAppendingPathComponent:kMBMManifestName] stringByAppendingPathExtension:kMBMPlistExtension];
	if (![[NSFileManager defaultManager] fileExistsAtPath:manifestPath]) {
		ALog(@"Error: Installation File doesn't have a %@.%@ file.", kMBMManifestName, kMBMPlistExtension);
		return nil;
	}

	//	Otherwise init as normal
	self = [super init];
	if (self) {
		
		//	Get the installation manifest contents and the items
		NSDictionary	*manifestDict = [NSDictionary dictionaryWithContentsOfFile:manifestPath];
		NSArray			*installItems = [manifestDict valueForKey:kMBMActionItemsKey];
		NSArray			*confirmationSteps = [manifestDict valueForKey:kMBMConfirmationStepsKey];
		NSMutableArray	*newItems = nil;
		
		//	Get the confirmation steps
		//	Create each of the items
		newItems = [NSMutableArray arrayWithCapacity:[confirmationSteps count]];
		for (NSDictionary *itemDict in confirmationSteps) {
			[newItems addObject:[[[MBMConfirmationStep alloc] initWithDictionary:itemDict andInstallationFilePath:installFilePath] autorelease]];
		}
		
		//	Set our confirmation list to the new array, but only if it is not nil
		if (newItems) {
			_confirmationStepList = [[NSArray arrayWithArray:newItems] retain];
		}
		_confirmationStepCount = [_confirmationStepList count];
		
		
		//	Get the installation list
		//	Create each of the items
		newItems = [NSMutableArray arrayWithCapacity:[installItems count]];
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
		
		//	set the installation display name and background if there is one
		if ([manifestDict valueForKey:kMBMDisplayNameKey]) {
			_displayName = [[manifestDict valueForKey:kMBMDisplayNameKey] copy];
		}
		if ([manifestDict valueForKey:kMBMBackgroundImagePathKey]) {
			_backgroundImagePath = [[installFilePath stringByAppendingPathComponent:[manifestDict valueForKey:kMBMBackgroundImagePathKey]] copy];
		}
		
		//	Set the installation item total count
		NSInteger	count = [_installationItemList count];
		if (self.shouldInstallManager) {
			count++;
		}
		_totalInstallationItemCount = count;
		
	}
	return self;
}

- (void)dealloc {
	
	self.displayName = nil;
	self.backgroundImagePath = nil;
	self.bundleManager = nil;
	self.confirmationStepList = nil;
	self.installationItemList = nil;

	[super dealloc];
}


#pragma mark - Helpful Methods


- (NSString *)description {
	NSMutableString	*result = [NSMutableString string];
	
	[result appendFormat:@">>MBMInstallationModel [%p]  ", self];
	[result appendFormat:@"displayName:%@  ", self.displayName];
	[result appendFormat:@"backgroundImagePath:%@\n", self.backgroundImagePath];
	[result appendFormat:@"minOSVersion:%3.2f  ", self.minOSVersion];
	[result appendFormat:@"maxOSVersion:%3.2f  ", self.maxOSVersion];
	[result appendFormat:@"minMailVersion:%3.2f  ", self.minMailVersion];
	[result appendFormat:@"shouldInstallManager:%@\n", [NSString stringWithBool:self.shouldInstallManager]];
	[result appendFormat:@"bundleManager:\n\t(%@)\n", self.bundleManager];
	[result appendFormat:@"totalInstallCount:%d  ", self.totalInstallationItemCount];
	[result appendString:@"installItems:{\n"];
	for (MBMInstallationItem *anItem in self.installationItemList) {
		[result appendFormat:@"\t[%@]\n", anItem];
	}
	[result appendString:@"}"];
	[result appendString:@"confirmationStepList:{\n"];
	for (MBMConfirmationStep *anItem in self.confirmationStepList) {
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


