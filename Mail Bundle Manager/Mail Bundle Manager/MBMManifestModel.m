//
//  MBMManifestModel.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MBMManifestModel.h"
#import "MBMMailBundle.h"
#import "MBMConfirmationStep.h"


@interface MBMManifestModel ()
@property	(nonatomic, copy, readwrite)	NSString		*displayName;
@property	(nonatomic, copy, readwrite)	NSString		*backgroundImagePath;
@property	(nonatomic, retain, readwrite)	MBMActionItem	*bundleManager;
@property	(nonatomic, retain, readwrite)	NSArray			*confirmationStepList;
@property	(nonatomic, retain, readwrite)	NSArray			*actionItemList;
@end

@implementation MBMManifestModel

#pragma mark - Accessors

@synthesize manifestType = _manifestType;
@synthesize displayName = _displayName;
@synthesize backgroundImagePath = _backgroundImagePath;
@synthesize minOSVersion = _minOSVersion;
@synthesize maxOSVersion = _maxOSVersion;
@synthesize minMailVersion = _minMailVersion;
@synthesize bundleManager = _bundleManager;
@synthesize confirmationStepList = _confirmationStepList;
@synthesize actionItemList = _actionItemList;
@synthesize totalActionItemCount = _totalActionItemCount;
@synthesize confirmationStepCount = _confirmationStepCount;
@synthesize canDeleteManagerIfNotUsedByOthers = _canDeleteManagerIfNotUsedByOthers;
@synthesize canDeleteManagerIfNoBundlesLeft = _canDeleteManagerIfNoBundlesLeft;


- (BOOL)shouldInstallManager {
	return !IsEmpty(self.bundleManager.path);
}


#pragma mark - Memory Management

- (id)initWithPackageAtPath:(NSString *)packageFilePath {

	//	If there is no manifest inside, return nil
	NSString	*manifestPath = [[packageFilePath stringByAppendingPathComponent:kMBMManifestName] stringByAppendingPathExtension:kMBMPlistExtension];
	if (![[NSFileManager defaultManager] fileExistsAtPath:manifestPath]) {
		ALog(@"Error: Package doesn't have a %@.%@ file.", kMBMManifestName, kMBMPlistExtension);
		return nil;
	}

	//	Otherwise init as normal
	self = [super init];
	if (self) {
		
		//	Get the installation manifest contents and the items
		NSDictionary	*manifestDict = [NSDictionary dictionaryWithContentsOfFile:manifestPath];
		NSArray			*actionItems = [manifestDict valueForKey:kMBMActionItemsKey];
		NSArray			*confirmationSteps = [manifestDict valueForKey:kMBMConfirmationStepsKey];
		NSMutableArray	*newItems = nil;
		
		//	Set the manifest type first
		if ([[manifestDict valueForKey:kMBMManifestTypeKey] isEqualToString:kMBMManifestTypeInstallValue]) {
			_manifestType = kMBMManifestTypeInstallation;
		}
		else if ([[manifestDict valueForKey:kMBMManifestTypeKey] isEqualToString:kMBMManifestTypeUninstallValue]) {
			_manifestType = kMBMManifestTypeUninstallation;
		}
		
		//	Get the confirmation steps
		//	Create each of the items
		newItems = [NSMutableArray arrayWithCapacity:[confirmationSteps count]];
		for (NSDictionary *itemDict in confirmationSteps) {
			[newItems addObject:[[[MBMConfirmationStep alloc] initWithDictionary:itemDict andPackageFilePath:packageFilePath] autorelease]];
		}
		
		//	Set our confirmation list to the new array, but only if it is not nil
		if (newItems) {
			_confirmationStepList = [[NSArray arrayWithArray:newItems] retain];
		}
		_confirmationStepCount = [_confirmationStepList count];
		
		
		//	Get the installation list
		//	Create each of the items
		newItems = [NSMutableArray arrayWithCapacity:[actionItems count]];
		for (NSDictionary *itemDict in actionItems) {
			MBMActionItem	*anItem = [[[MBMActionItem alloc] initWithDictionary:itemDict fromPackageFilePath:packageFilePath manifestType:_manifestType] autorelease];
			if (anItem.isBundleManager) {
				_bundleManager = [anItem retain];
			}
			else {
				[newItems addObject:anItem];
			}
		}
		
		//	Set our items list to the new array
		_actionItemList = [[NSArray arrayWithArray:newItems] retain];
		
		
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
		
		//	set the display name and background if there is one
		if ([manifestDict valueForKey:kMBMDisplayNameKey]) {
			_displayName = [[manifestDict valueForKey:kMBMDisplayNameKey] copy];
		}
		if ([manifestDict valueForKey:kMBMBackgroundImagePathKey]) {
			_backgroundImagePath = [[packageFilePath stringByAppendingPathComponent:[manifestDict valueForKey:kMBMBackgroundImagePathKey]] copy];
		}
		
		//	Set the action item total count
		NSInteger	count = [_actionItemList count];
		if (self.shouldInstallManager) {
			count++;
		}
		_totalActionItemCount = count;
		
		//	Set manager deletion flags
		_canDeleteManagerIfNotUsedByOthers = NO;
		_canDeleteManagerIfNoBundlesLeft = YES;
		if ([manifestDict valueForKey:kMBMCanDeleteManagerIfNotUsedByOthersKey]) {
			_canDeleteManagerIfNotUsedByOthers = [[manifestDict valueForKey:kMBMCanDeleteManagerIfNotUsedByOthersKey] boolValue];
		}
		if ([manifestDict valueForKey:kMBMCanDeleteManagerIfNoBundlesKey]) {
			_canDeleteManagerIfNoBundlesLeft = [[manifestDict valueForKey:kMBMCanDeleteManagerIfNoBundlesKey] boolValue];
		}
		
	}
	return self;
}

- (void)dealloc {
	
	self.displayName = nil;
	self.backgroundImagePath = nil;
	self.bundleManager = nil;
	self.confirmationStepList = nil;
	self.actionItemList = nil;

	[super dealloc];
}


#pragma mark - Helpful Methods


- (NSString *)description {
	NSMutableString	*result = [NSMutableString string];
	
	[result appendFormat:@">%@ [%p]  ", [self className], self];
	[result appendFormat:@"displayName:%@  ", self.displayName];
	[result appendFormat:@"backgroundImagePath:%@\n", self.backgroundImagePath];
	[result appendFormat:@"minOSVersion:%3.2f  ", self.minOSVersion];
	[result appendFormat:@"maxOSVersion:%3.2f  ", self.maxOSVersion];
	[result appendFormat:@"minMailVersion:%3.2f  ", self.minMailVersion];
	[result appendFormat:@"shouldInstallManager:%@\n", [NSString stringWithBool:self.shouldInstallManager]];
	[result appendFormat:@"bundleManager:\n\t(%@)\n", self.bundleManager];
	[result appendFormat:@"totalActionCount:%d  ", self.totalActionItemCount];
	[result appendString:@"actionItems:{\n"];
	for (MBMActionItem *anItem in self.actionItemList) {
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

