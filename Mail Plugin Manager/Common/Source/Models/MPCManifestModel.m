//
//  MPCManifestModel.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MPCManifestModel.h"
#import "MPCMailBundle.h"
#import "MPCConfirmationStep.h"


@interface MPCManifestModel ()
@property	(nonatomic, copy, readwrite)	NSString		*displayName;
@property	(nonatomic, copy, readwrite)	NSString		*backgroundImagePath;
@property	(nonatomic, retain, readwrite)	MPCActionItem	*bundleManager;
@property	(nonatomic, retain, readwrite)	NSArray			*confirmationStepList;
@property	(nonatomic, retain, readwrite)	NSArray			*actionItemList;
@property	(nonatomic, assign)				CGFloat			minVersionMinor;
@property	(nonatomic, assign)				NSInteger		minVersionBugFix;
@property	(nonatomic, assign)				CGFloat			maxVersionMinor;
@property	(nonatomic, assign)				NSInteger		maxVersionBugFix;
@end

@implementation MPCManifestModel

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
@synthesize shouldRestartMail = _shouldRestartMail;
@synthesize shouldConfigureMail = _shouldConfigureMail;
@synthesize configureMailVersion = _configureMailVersion;
@synthesize completionMessage = _completionMessage;
@synthesize	minVersionMinor = _minVersionMinor;
@synthesize	minVersionBugFix = _minVersionBugFix;
@synthesize	maxVersionMinor = _maxVersionMinor;
@synthesize	maxVersionBugFix = _maxVersionBugFix;

- (BOOL)shouldInstallManager {
	return !IsEmpty(self.bundleManager.path);
}


#pragma mark - Memory Management

- (id)initWithPackageAtPath:(NSString *)packageFilePath {

	//	If there is no manifest inside, return nil
	NSString	*manifestPath = [[packageFilePath stringByAppendingPathComponent:kMPCManifestName] stringByAppendingPathExtension:kMPCPlistExtension];
	if (![[NSFileManager defaultManager] fileExistsAtPath:manifestPath]) {
		ALog(@"Error: Package doesn't have a %@.%@ file.", kMPCManifestName, kMPCPlistExtension);
		return nil;
	}

	//	Otherwise init as normal
	self = [super init];
	if (self) {
		
		//	Get the installation manifest contents and the items
		NSDictionary	*manifestDict = [NSDictionary dictionaryWithContentsOfFile:manifestPath];
		NSArray			*actionItems = [manifestDict valueForKey:kMPCActionItemsKey];
		NSArray			*confirmationSteps = [manifestDict valueForKey:kMPCConfirmationStepsKey];
		NSMutableArray	*newItems = nil;
		
		//	Set the manifest type first
		if ([[manifestDict valueForKey:kMPCManifestTypeKey] isEqualToString:kMPCManifestTypeInstallValue]) {
			_manifestType = kMPCManifestTypeInstallation;
		}
		else if ([[manifestDict valueForKey:kMPCManifestTypeKey] isEqualToString:kMPCManifestTypeUninstallValue]) {
			_manifestType = kMPCManifestTypeUninstallation;
		}
		
		//	Get the confirmation steps
		//	Create each of the items
		newItems = [NSMutableArray arrayWithCapacity:[confirmationSteps count]];
		for (NSDictionary *itemDict in confirmationSteps) {
			[newItems addObject:[[[MPCConfirmationStep alloc] initWithDictionary:itemDict andPackageFilePath:packageFilePath] autorelease]];
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
			MPCActionItem	*anItem = [[[MPCActionItem alloc] initWithDictionary:itemDict fromPackageFilePath:packageFilePath manifestType:_manifestType] autorelease];
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
		_minOSVersion = nil;
		_maxOSVersion = nil;
		_minVersionMinor = kMPCNoVersionRequirement;
		_maxVersionMinor = kMPCNoVersionRequirement;
		_minMailVersion = kMPCNoVersionRequirement;
		if ([manifestDict valueForKey:kMPCMinOSVersionKey]) {
			_minOSVersion = [[manifestDict valueForKey:kMPCMinOSVersionKey] retain];
			NSScanner	*versionScanner = [NSScanner scannerWithString:_minOSVersion];
			double	scanValue;
			[versionScanner scanDouble:&scanValue];
			_minVersionMinor = (CGFloat)scanValue;
			[versionScanner scanString:@"." intoString:NULL];
			if (![versionScanner isAtEnd]) {
				[versionScanner scanInteger:&_minVersionBugFix];
			}
		}
		if ([manifestDict valueForKey:kMPCMaxOSVersionKey]) {
			_maxOSVersion = [[manifestDict valueForKey:kMPCMaxOSVersionKey] retain];
			NSScanner	*versionScanner = [NSScanner scannerWithString:_maxOSVersion];
			double	scanValue;
			[versionScanner scanDouble:&scanValue];
			_maxVersionMinor = (CGFloat)scanValue;
			[versionScanner scanString:@"." intoString:NULL];
			if (![versionScanner isAtEnd]) {
				[versionScanner scanInteger:&_maxVersionBugFix];
			}
		}
		if ([manifestDict valueForKey:kMPCMinMailVersionKey]) {
			_minMailVersion = [[manifestDict valueForKey:kMPCMinMailVersionKey] floatValue];
		}
		
		//	set the display name and background if there is one
		if ([manifestDict valueForKey:kMPCDisplayNameKey]) {
			_displayName = [MPCLocalizedStringFromPackageFile([manifestDict valueForKey:kMPCDisplayNameKey], packageFilePath) copy];
		}
		if ([manifestDict valueForKey:kMPCBackgroundImagePathKey]) {
			_backgroundImagePath = [[packageFilePath stringByAppendingPathComponent:[manifestDict valueForKey:kMPCBackgroundImagePathKey]] copy];
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
		if ([manifestDict valueForKey:kMPCCanDeleteManagerIfNotUsedByOthersKey]) {
			_canDeleteManagerIfNotUsedByOthers = [[manifestDict valueForKey:kMPCCanDeleteManagerIfNotUsedByOthersKey] boolValue];
		}
		if ([manifestDict valueForKey:kMPCCanDeleteManagerIfNoBundlesKey]) {
			_canDeleteManagerIfNoBundlesLeft = [[manifestDict valueForKey:kMPCCanDeleteManagerIfNoBundlesKey] boolValue];
		}
		
		//	Set values for mail configuration
		_shouldRestartMail = YES;
		_shouldConfigureMail = NO;
		_configureMailVersion = kMPCDefaultMailPluginVersion;
		if ([manifestDict valueForKey:kMPCMinMailBundleVersionKey] != nil) {
			_shouldConfigureMail = YES;
			_configureMailVersion = [[manifestDict valueForKey:kMPCMinMailBundleVersionKey] integerValue];
		}
		if ([manifestDict valueForKey:kMPCDontRestartMailKey] != nil) {
			_shouldRestartMail = [[manifestDict valueForKey:kMPCDontRestartMailKey] boolValue];
		}
		
		//	Set the completion message (default is empty string)
		_completionMessage = @"";
		if ([manifestDict valueForKey:kMPCCompletionMessageKey] != nil) {
			_completionMessage = [[manifestDict valueForKey:kMPCCompletionMessageKey] copy];
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


- (MPCOSSupportResult)supportResultForManifest {
	
	//	Ensure that the versions all check out
	CGFloat		currentVersion = macOSXVersion();
	NSInteger	currentBugFixVersion = macOSXBugFixVersion();
	
	if ((self.minVersionMinor != kMPCNoVersionRequirement) && 
		((currentVersion < self.minVersionMinor) ||
		 ((fabs(currentVersion - self.minVersionMinor) < 0.01f) && (currentBugFixVersion < self.minVersionBugFix)))) {
		return kMPCOSIsTooLow;
	}
	if ((self.maxVersionMinor != kMPCNoVersionRequirement) && 
		((currentVersion > self.maxVersionMinor) || 
		 ((fabs(currentVersion - self.maxVersionMinor) < 0.01f) && (currentBugFixVersion > self.maxVersionBugFix)))) {
		return kMPCOSIsTooHigh;
	}

	return kMPCOSIsSupported;
}

- (NSString *)description {
	NSMutableString	*result = [NSMutableString string];
	
	[result appendFormat:@">%@ [%p]  ", [self className], self];
	[result appendFormat:@"displayName:%@  ", self.displayName];
	[result appendFormat:@"backgroundImagePath:%@\n", self.backgroundImagePath];
	[result appendFormat:@"minOSVersion:%@  ", self.minOSVersion];
	[result appendFormat:@"maxOSVersion:%@  ", self.maxOSVersion];
	[result appendFormat:@"minMailVersion:%3.2f  ", self.minMailVersion];
	[result appendFormat:@"shouldInstallManager:%@\n", [NSString stringWithBool:self.shouldInstallManager]];
	[result appendFormat:@"bundleManager:\n\t(%@)\n", self.bundleManager];
	[result appendFormat:@"totalActionCount:%@  ", [NSNumber numberWithInteger:self.totalActionItemCount]];
	[result appendFormat:@"canDeleteManagerIfNotUsedByOthers:%@\n", [NSString stringWithBool:self.canDeleteManagerIfNotUsedByOthers]];
	[result appendFormat:@"canDeleteManagerIfNoBundlesLeft:%@\n", [NSString stringWithBool:self.canDeleteManagerIfNoBundlesLeft]];
	[result appendFormat:@"shouldConfigureMail:%@\n", [NSString stringWithBool:self.shouldConfigureMail]];
	[result appendFormat:@"configureMailVersion:%@\n", [NSNumber numberWithInteger:self.configureMailVersion ]];
	[result appendString:@"actionItems:{\n"];
	for (MPCActionItem *anItem in self.actionItemList) {
		[result appendFormat:@"\t[%@]\n", anItem];
	}
	[result appendString:@"}"];
	[result appendString:@"confirmationStepList:{\n"];
	for (MPCConfirmationStep *anItem in self.confirmationStepList) {
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

NSInteger macOSXBugFixVersion(void) {
	// use a static because we only really need to get the version once.
	NSInteger	value = 0;
	SInt32 version = 0;
	OSErr err = Gestalt(gestaltSystemVersionBugFix, &version);
	if (!err) {
		value = (NSInteger)version;
	}
	return value;
}

CGFloat mailVersion(void) {
	static CGFloat mailVer = 1.0;
	if (mailVer == 1.0) {
		NSBundle	*mailBundle = [NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:kMPCMailBundleIdentifier]];
		NSString	*mailVersionString = [[mailBundle infoDictionary] valueForKey:(NSString *)kCFBundleVersionKey];
		mailVer = [mailVersionString floatValue];
	}
	return mailVer;
}


