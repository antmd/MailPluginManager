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
@property	(nonatomic, copy, readwrite)	NSString			*displayName;
@property	(nonatomic, copy, readwrite)	NSString			*backgroundImagePath;
@property	(nonatomic, retain, readwrite)	MBMInstallationItem	*bundleManager;
@property	(nonatomic, retain, readwrite)	NSArray				*confirmationStepList;
@property	(nonatomic, retain, readwrite)	NSArray				*installationItemList;

- (NSString *)localizeString:(NSString *)inString forInstallFile:(NSString *)installFilePath;
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


- (BOOL)shouldInstallManager {
	return !IsEmpty(self.bundleManager.path);
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
		NSArray			*confirmationSteps = [manifestDict valueForKey:kMBMConfirmationStepsKey];
		NSMutableArray	*newItems = nil;
		
		//	Get the confirmation steps
		//	Create each of the items
		newItems = [NSMutableArray arrayWithCapacity:[confirmationSteps count]];
		for (NSDictionary *itemDict in confirmationSteps) {
			
			//	Update some contents of the dictionary for later use
			NSMutableDictionary	*convertedDict = [itemDict mutableCopy];
			
			//	Set the flag for is the content of this part html
			BOOL	isHTML = [[[itemDict valueForKey:kMBMPathKey] pathExtension] isEqualToString:@"html"];
			[convertedDict setValue:[NSNumber numberWithBool:isHTML] forKey:kMBMPathIsHTMLKey];
			
			//	If it is html, ensure it has a full URL
			if (isHTML) {
				//	Update the path to include the installFilePath, and make it a full URL
				if (![[convertedDict valueForKey:kMBMPathKey] hasPrefix:@"http"]) {
					[convertedDict setValue:[NSString stringWithFormat:@"file://%@", [installFilePath stringByAppendingPathComponent:[convertedDict valueForKey:kMBMPathKey]]] forKey:kMBMPathKey];
				}
			}
			//	Otherwise if there is a path just make it a full path
			else if ([convertedDict valueForKey:kMBMPathKey]) {
				[convertedDict setValue:[installFilePath stringByAppendingPathComponent:[convertedDict valueForKey:kMBMPathKey]] forKey:kMBMPathKey];
			}
			
			//	Localized the two titles
			NSString	*localizedTitle = [self localizeString:[convertedDict valueForKey:kMBMConfirmationTitleKey] forInstallFile:installFilePath];
			[convertedDict setValue:localizedTitle forKey:kMBMConfirmationLocalizedTitleKey];
			if ([convertedDict valueForKey:kMBMConfirmationBulletTitleKey]) {
				[convertedDict setValue:[self localizeString:[convertedDict valueForKey:kMBMConfirmationBulletTitleKey] forInstallFile:installFilePath] forKey:kMBMConfirmationLocalizedBulletTitleKey];
			}
			else {
				[convertedDict setValue:localizedTitle forKey:kMBMConfirmationLocalizedTitleKey];
			}
			[newItems addObject:[NSDictionary dictionaryWithDictionary:convertedDict]];
			[convertedDict release];
		}
		
		//	Set our confirmation list to the new array, but only if it is not nil
		if (newItems) {
			_confirmationStepList = [[NSArray arrayWithArray:newItems] retain];
		}
		
		
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
		if ([manifestDict valueForKey:kMBMInstallDisplayNameKey]) {
			_displayName = [[manifestDict valueForKey:kMBMInstallDisplayNameKey] copy];
		}
		if ([manifestDict valueForKey:kMBMInstallBGImagePathKey]) {
			_backgroundImagePath = [[installFilePath stringByAppendingPathComponent:[manifestDict valueForKey:kMBMInstallBGImagePathKey]] copy];
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

- (NSString *)localizeString:(NSString *)inString forInstallFile:(NSString *)installFilePath {
	return NSLocalizedStringFromTableInBundle(inString, nil, [NSBundle bundleWithPath:installFilePath], @"");
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


