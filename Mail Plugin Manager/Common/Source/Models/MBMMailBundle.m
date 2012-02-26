//
//  MBMMailBundle.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBMMailBundle.h"
#import "MBMAppDelegate.h"
#import "MBMCompanyList.h"
#import "MBMUUIDList.h"
#import "NSBundle+MBMAdditions.h"
#import "NSString+LKHelper.h"
#import "NSFileManager+LKAdditions.h"
#import "NSObject+LKObject.h"

typedef enum {
	MBMGenericBundleErrorCode = 500,
	MBMCantCreateDisabledBundleFolderErrorCode = 501,
	
	MBMUnknownBundleCode
} MBMBundleErrorCodes;


@interface MBMMailBundle ()
@property	(nonatomic, copy, readwrite)		NSString		*name;
@property	(nonatomic, copy, readwrite)		NSString		*company;
@property	(nonatomic, copy, readwrite)		NSString		*companyURL;
@property	(nonatomic, copy, readwrite)		NSString		*productURL;
@property	(nonatomic, copy, readwrite)		NSString		*iconPath;
@property	(nonatomic, retain, readwrite)		NSImage			*icon;
@property	(nonatomic, retain, readwrite)		NSBundle		*bundle;
- (void)updateState;
+ (NSString *)mailFolderPathForDomain:(NSSearchPathDomainMask)domain;
+ (NSString *)pathForDomain:(NSSearchPathDomainMask)domain shouldCreate:(BOOL)createNew disabled:(BOOL)disabledPath;
+ (NSArray *)disabledBundlesPathListForDomain:(NSSearchPathDomainMask)domain;
@end

@implementation MBMMailBundle


#pragma mark - Accessors

@synthesize name = _name;
@synthesize company = _company;
@synthesize companyURL = _companyURL;
@synthesize productURL = _productURL;
@synthesize icon = _icon;
@synthesize iconPath = _iconPath;
@synthesize bundle = _bundle;
@synthesize usesBundleManager = _usesBundleManager;
@synthesize incompatibleWithCurrentMail = _incompatibleWithCurrentMail;
@synthesize incompatibleWithFutureMail = _incompatibleWithFutureMail;
@synthesize hasUpdate = _hasUpdate;
@synthesize latestVersion = _latestVersion;
@synthesize enabled = _enabled;
@synthesize installed = _installed;
@synthesize inLocalDomain = _inLocalDomain;
@synthesize sparkleDelegate = _sparkleDelegate;

- (NSString *)path {
	return [self.bundle bundlePath];
}

- (NSString *)identifier {
	return [self.bundle bundleIdentifier];
}

- (NSString *)version {
	return [self.bundle versionString];
}

- (void)setEnabled:(BOOL)enabled {
	//	If there is no change, do nothing
	if (enabled == _enabled) {
		return;
	}
	
	//	Default is to *enable* it
	NSSearchPathDomainMask	domain = self.inLocalDomain?NSLocalDomainMask:NSUserDomainMask;
	NSString	*fromPath = self.path;
	NSString	*toPath = [[[self class] pathForDomain:domain shouldCreate:YES disabled:!enabled] stringByAppendingPathComponent:[self.path lastPathComponent]];
	NSError		*error;
	
	//	Move the plugin to a disabled folder
	if ([[NSFileManager defaultManager] moveWithAuthenticationIfNeededFromPath:fromPath toPath:toPath error:&error]) {
		//	Then update the bundle
		self.bundle = [NSBundle bundleWithPath:toPath];
		
		//	Send a notification
		[[NSNotificationCenter defaultCenter] postNotificationName:kMBMMailBundleDisabledNotification object:self];
	}
	
	//	Always update all the state
	[self updateState];
}

- (void)setInstalled:(BOOL)installed {
	//	If there is no change, do nothing
	if (installed == _installed) {
		return;
	}
	
	//	Only allow a direct uninstall
	if (installed == YES) {
		ALog(@"Don't use the setter on installed to \"install\" - only \"uninstall\"");
		return;
	}
	
	//	Default is to *uninstall* it
	NSString	*fromPath = self.path;
	NSString	*toPath = [[NSHomeDirectory() stringByAppendingPathComponent:@".Trash"] stringByAppendingPathComponent:[self.path lastPathComponent]];
	NSError		*error;
	
	//	Ensure that we have a unique file name for the trash
	NSString	*tempPath = toPath;
	NSInteger	counter = 1;
	while ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
		tempPath = [toPath stringByAppendingFormat:@" %ld", counter++];
	}
	if (toPath != tempPath) {	//	Using pointer equivalence here expressly!!
		toPath = tempPath;
	}
	
	//	Move the plugin to the trash
	if ([[NSFileManager defaultManager] moveWithAuthenticationIfNeededFromPath:fromPath toPath:toPath overwrite:NO error:&error]) {
		//	Then update the bundle
		self.bundle = [NSBundle bundleWithPath:toPath];
		
		//	Send a notification
		[[NSNotificationCenter defaultCenter] postNotificationName:kMBMMailBundleUninstalledNotification object:self];
	}
	
	//	Update all the state
	[self updateState];
	
}

- (void)setInLocalDomain:(BOOL)inLocalDomain {
	//	If there is no change, do nothing
	if (inLocalDomain == _inLocalDomain) {
		return;
	}
	
	//	Set up the paths to use
	NSSearchPathDomainMask	domain = inLocalDomain?NSLocalDomainMask:NSUserDomainMask;
	NSString	*fromPath = self.path;
	NSString	*toPath = [[[self class] pathForDomain:domain shouldCreate:YES disabled:!self.enabled] stringByAppendingPathComponent:[self.path lastPathComponent]];
	NSError		*error;
	
	//	Move the plugin to the other domain
	if ([[NSFileManager defaultManager] moveWithAuthenticationIfNeededFromPath:fromPath toPath:toPath error:&error]) {
		//	Then update the bundle
		self.bundle = [NSBundle bundleWithPath:toPath];
	}

	//	Update all the state
	[self updateState];
}

- (NSString *)company {

	if ([_company isEqualToString:kMBMUnknownCompanyValue]) {
		//	First look for our key
		NSString	*aCompany = [[self.bundle infoDictionary] valueForKey:kMBMCompanyNameKey];
		if (aCompany == nil) {
			
			//	Try our database using the bundleIdentifier
			aCompany = [MBMCompanyList companyNameFromIdentifier:self.identifier];
			
			if (aCompany == nil) {
				aCompany = self.companyURL;
			}
			
			//	If not found parse the Get Info string?
			//			aCompany = [[_bundle infoDictionary] valueForKey:@"CFBundleGetInfoString"];
			
			/*
			 
			 <key>CFBundleGetInfoString</key>
			 <string>1.5.2, ©2002–2011 C-Command Software</string>
			 
			 <key>CFBundleGetInfoString</key>
			 <string>MailTags 3.0 Preview 1(build 1386), Copyright (c) 2006-11 Indev Software</string>
			 
			 
			 */
		}
		
		//	Release the previous value and copy the new one
		[_company release];
		_company = [aCompany copy];
	}
	
	return [[_company retain] autorelease];
}

- (NSString *)companyURL {
	
	if (_companyURL == nil) {
		//	First look for our key
		NSString	*aURL = [[self.bundle infoDictionary] valueForKey:kMBMCompanyURLKey];
		if (aURL == nil) {
			//	Try to get it from our list file
			aURL = [MBMCompanyList companyURLFromIdentifier:self.identifier];
		}
		
		//	Release the previous value and copy the new one
		[_companyURL release];
		_companyURL = [aURL copy];
	}
	
	return [[_companyURL retain] autorelease];
}

- (NSString *)productURL {
	
	if (_productURL == nil) {
		//	First look for our key
		NSString	*aURL = [[self.bundle infoDictionary] valueForKey:kMBMProductURLKey];
		if (aURL == nil) {
			//	Try to get it from our list file
			aURL = [MBMCompanyList productURLFromIdentifier:self.identifier];
		}
		
		//	Release the previous value and copy the new one
		[_productURL release];
		_productURL = [aURL copy];
	}
	
	return [[_productURL retain] autorelease];
}

- (NSString *)incompatibleString {
	return [NSString stringWithFormat:NSLocalizedString(@"Always disabled in Mac OS X > %@", @"A string as short as possible describing that the plugin is only compatible with the OS until version X"), [self latestOSVersionSupported]];
}

#pragma mark - Memory Management

- (id)initWithPath:(NSString *)bundlePath {
	return [self initWithPath:bundlePath shouldLoadUpdateInfo:YES];
}

- (id)initWithPath:(NSString *)bundlePath shouldLoadUpdateInfo:(BOOL)loadInfo {
    self = [super init];
    if (self) {
        // Initialization code here.
		_bundle = [[NSBundle bundleWithPath:bundlePath] retain];
		
		//	Get the localized name if there is one
		NSString	*tempName = [[_bundle localizedInfoDictionary] valueForKey:(NSString *)kCFBundleNameKey];
		if (tempName == nil) {
			tempName = [[_bundle infoDictionary] valueForKey:(NSString *)kCFBundleNameKey];
		}
		_name = [tempName copy];
		
		//	Look to see if it has the key indicating that it uses MBM
		if ([[_bundle infoDictionary] valueForKey:kMBMBundleUsesMBMKey]) {
			_usesBundleManager = [[[_bundle infoDictionary] valueForKey:kMBMBundleUsesMBMKey] boolValue];
		}
		
		//	Set hasUpdate to false and launch the background thread to see if we can get info
		_hasUpdate = NO;
		if (loadInfo) {
			[self performSelector:@selector(loadUpdateInformation) withObject:nil afterDelay:0.1f];
		}
		
		//	Get the image from the icons file
		NSString	*iconFileName = [[_bundle infoDictionary] valueForKey:@"CFBundleIconFile"];
		_iconPath = [[_bundle pathForImageResource:iconFileName] copy];
		if (_iconPath == nil) {
			_iconPath = [[[NSBundle mainBundle] pathForImageResource:kMBMGenericBundleIcon] copy];
		}
		_icon = [[NSImage alloc] initWithContentsOfFile:_iconPath];

		//	Current Dummy value for latestVersion
		_latestVersion = [[NSString alloc] initWithString:@"12.5.8"];
		
		//	Set a fake company name to know when to try and load it
		_company = [[NSString alloc] initWithString:kMBMUnknownCompanyValue];
		
		//	Set the state values
		[self updateState];
		
		//	Set the compatibility flag
		//	Get the values to test
		NSArray		*supportedUUIDs = [[_bundle infoDictionary] valueForKey:kMBMMailBundleUUIDListKey];
		NSString	*mailUUID = [MBMUUIDList currentMailUUID];
		NSString	*messageUUID = [MBMUUIDList currentMessageUUID];
		
		//	Test to ensure that the plugin list contains both the mail and message UUIDs
		if (![supportedUUIDs containsObject:mailUUID] || ![supportedUUIDs containsObject:messageUUID]) {
			_incompatibleWithCurrentMail = YES;
		}
		
		//	See if there is a future incompatibility known
		if ([MBMUUIDList firstUnsupportedOSVersionFromSupportedList:supportedUUIDs]) {
			_incompatibleWithFutureMail = YES;
		}
		
    }
    
    return self;
}


- (void)dealloc {
	self.name = nil;
	self.company = nil;
	self.companyURL = nil;
	self.productURL = nil;
	self.icon = nil;
	self.iconPath = nil;
	self.bundle = nil;
	self.latestVersion = nil;
	self.sparkleDelegate = nil;
	[super dealloc];
}

#pragma mark - Binding Properties

- (NSColor *)nameColor {
	NSColor	*aColor	= [NSColor grayColor];
	if (self.enabled) {
		aColor = [NSColor colorWithDeviceRed:0.290 green:0.459 blue:0.224 alpha:1.000];
	}
	else if (self.incompatibleWithCurrentMail) {
		aColor = [NSColor colorWithDeviceRed:0.654 green:0.099 blue:0.046 alpha:1.000];
	}
	return aColor;
}

- (NSString *)backgroundImagePath {
	NSString	*aPath	= @"";
	if (self.incompatibleWithCurrentMail) {
		aPath = @"Red";
	}
	return [[NSBundle mainBundle] pathForImageResource:[NSString stringWithFormat:@"BundleBackground%@", aPath]];
}


#pragma mark - Testing

- (void)updateState {
	
	[self performBlock:^{
		//	Set the state values
		[self willChangeValueForKey:@"enabled"];
		_enabled = [self isInActiveBundlesFolder];
		[self didChangeValueForKey:@"enabled"];
		[self willChangeValueForKey:@"installed"];
		_installed = [self isInActiveBundlesFolder] || [self isInDisabledBundlesFolder];
		[self didChangeValueForKey:@"installed"];
		[self willChangeValueForKey:@"inLocalDomain"];
		_inLocalDomain = [self.path hasPrefix:[[self class] mailFolderPathLocal]];
		[self didChangeValueForKey:@"inLocalDomain"];
	} afterDelay:0.1f];
	
}

- (BOOL)isInActiveBundlesFolder {
	NSString	*folderPath = [self.path stringByDeletingLastPathComponent];
	return ([folderPath isEqualToString:[[self class] bundlesPathShouldCreate:NO]] || [folderPath isEqualToString:[[self class] bundlesPathLocalShouldCreate:NO]]);
}

- (BOOL)isInDisabledBundlesFolder {
	NSString	*folderPath = [self.path stringByDeletingLastPathComponent];
	//	Check all of the user paths
	for (NSString *disabledPath in [[self class] disabledBundlesPathList]) {
		if ([folderPath isEqualToString:disabledPath]) {
			return YES;
		}
	}
	//	Then check all of the local paths
	for (NSString *disabledPath in [[self class] disabledBundlesPathLocalList]) {
		if ([folderPath isEqualToString:disabledPath]) {
			return YES;
		}
	}
	return NO;
}

- (BOOL)hasLaterVersionNumberThanBundle:(MBMMailBundle *)otherBundle {
	return [self.bundle hasLaterVersionNumberThanBundle:otherBundle.bundle];
}

- (NSString *)latestOSVersionSupported {
	return [MBMUUIDList latestOSVersionFromSupportedList:[[self.bundle infoDictionary] valueForKey:kMBMMailBundleUUIDListKey]];
}

- (NSString *)firstOSVersionUnsupported {
	return [MBMUUIDList firstUnsupportedOSVersionFromSupportedList:[[self.bundle infoDictionary] valueForKey:kMBMMailBundleUUIDListKey]];
}


#pragma mark - Actions

- (void)loadUpdateInformation {
	
	//	Simply use the standard Sparkle behavior (with an instantiation via the path)
	SUUpdater	*updater = nil;
	if ([self supportsSparkleUpdates] && (updater = [SUUpdater updaterForBundle:self.bundle])) {
		[updater setDelegate:self];
		[updater checkForUpdateInformation];
	}
	else {
		self.latestVersion = NSLocalizedString(@"???", @"String indicating that the latest version is not known");
	}
	
}

- (void)updateInteractive {
	
	//	Simply use the standard Sparkle behavior (with an instantiation via the path)
	SUUpdater	*updater = [SUUpdater updaterForBundle:self.bundle];
	if (updater) {
		[updater setDelegate:self];
		[updater checkForUpdates:nil];
	}
}


- (void)updateIfNecessary {
	
	if (![self supportsSparkleUpdates]) {
		return;
	}
	
	//	Simply use the standard Sparkle behavior (with an instantiation via the path)
	SUUpdater	*updater = [SUUpdater updaterForBundle:self.bundle];
	if (updater) {
		self.sparkleDelegate = [[[MBMSparkleDelegate alloc] initWithMailBundle:self] autorelease];
		[updater setDelegate:self.sparkleDelegate];
		
/*		//	Set the Path to relaunch to Mail
		self.sparkleDelegate.relaunchPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:kMBMMailBundleIdentifier];
		
		//	Tell the delegate to quit mail when needed
		self.sparkleDelegate.quitMail = YES;
		//	And also quit this app when done
		self.sparkleDelegate.quitManager = YES;
*/		
		//	Check for an update
		[updater checkForUpdatesInBackground];
	}
	
}

- (void)uninstall {
	
	//	Present a dialog to the user to confirm that they want to remove the plugin
	NSString	*messageText = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to uninstall the %@ Mail Plugin?", @"Question about if the uesr wants to delete the plugin"), self.name];
	NSAlert	*confirmAlert = [NSAlert alertWithMessageText:messageText 
											defaultButton:NSLocalizedString(@"Uninstall", @"Button text to validate uninstall") 
										  alternateButton:NSLocalizedString(@"Cancel", @"Button text to cancel an uninstall") 
											  otherButton:NSLocalizedString(@"Disable", @"Button text that lets the user disable instead of uninstall") 
								informativeTextWithFormat:NSLocalizedString(@"'Uninstall' will put the Plugin into the Trash, 'Disable' will just move it to a location so that Mail will not load it.", @"Text describing the two options")];
	[confirmAlert setIcon:self.icon];
	
	//	Run the alert
	NSInteger	result = [confirmAlert runModal];
	if (result == NSAlertDefaultReturn) {
		self.installed = NO;
	}
	//	Should disable the plugin, instead
	else if (result == NSAlertOtherReturn) {
		self.enabled = NO;
	}
	else {
		//	Send a notification
		[[NSNotificationCenter defaultCenter] postNotificationName:kMBMMailBundleNoActionTakenNotification object:self];
	}
}

- (void)sendCrashReports {
	//	TODO: Put in the crash reporting
}


#pragma mark - Sparkle Methods

#pragma mark Internal

- (BOOL)supportsSparkleUpdates {
	
	NSString	*infoKey = [[self.bundle infoDictionary] valueForKey:@"SUFeedURL"];
	NSString	*defaultsKey = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:self.identifier] valueForKey:@"SUFeedURL"];
	
	return ((infoKey != nil) || (defaultsKey != nil));
}


#pragma mark Delegate

// Sent when a valid update is found by the update driver.
- (void)updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)appcastItem {
	self.latestVersion = [appcastItem displayVersionString];
	self.hasUpdate = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:kMBMDoneLoadingSparkleNotification object:self];
}

// Sent when a valid update is not found.
- (void)updaterDidNotFindUpdate:(SUUpdater *)updater {
	self.latestVersion = self.version;
	self.hasUpdate = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:kMBMDoneLoadingSparkleNotification object:self];
}



#pragma mark - Class Methods

+ (MBMMailBundle *)mailBundleForPath:(NSString *)aBundlePath shouldLoadInfo:(BOOL)loadInfo {
	MBMMailBundle	*newBundle = nil;
	//	Only create a new one if we can load it as a bundle
	if ([NSBundle bundleWithPath:aBundlePath]) {
		newBundle = [[[MBMMailBundle alloc] initWithPath:aBundlePath shouldLoadUpdateInfo:loadInfo] autorelease];
	}
	
	return newBundle;
}

#pragma mark - Paths

+ (NSString *)pathForActiveBundleWithName:(NSString *)aBundleName {
	for (NSString *activeBundlePath in [self allActiveMailBundlesShouldLoadInfo:NO]) {
		if ([[activeBundlePath lastPathComponent] isEqualToString:aBundleName]) {
			return activeBundlePath;
		}
	}
	return nil;
}

#pragma mark Generic Methods

+ (NSString *)mailFolderPathForDomain:(NSSearchPathDomainMask)domain {
	return [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, domain, YES) lastObject] stringByAppendingPathComponent:kMBMMailFolderName];
}

+ (NSString *)pathForDomain:(NSSearchPathDomainMask)domain shouldCreate:(BOOL)createNew disabled:(BOOL)disabledPath {

	//	Designate which path to use
	NSString	*path = [[self mailFolderPathForDomain:domain] stringByAppendingPathComponent:kMBMBundleFolderName];
	if (disabledPath) {
		path = [[self disabledBundlesPathListForDomain:domain] lastObject];
	}
	
	//	Test to see if we need to do anything
	//	If we should create
	if (createNew) {
		
		NSFileManager	*manager = [NSFileManager defaultManager];
		BOOL			shouldCreate = NO;
		
		//	AND either, we're looking for a disabled folder and we have nil
		if (disabledPath && (path == nil)) {
			shouldCreate = YES;
			path = [[self mailFolderPathForDomain:domain] stringByAppendingPathComponent:[self disabledBundleFolderName]];
		}
		//	OR looking for enabled and it doesn't exist
		else if (!disabledPath && ![manager fileExistsAtPath:path]) {
			shouldCreate = YES;
			//	Uses current path
		}
		
		NSError		*error;
		if (shouldCreate && ![manager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) {
			NSDictionary	*theDict = [NSDictionary dictionaryWithObjectsAndKeys:path, kMBMPathKey, error, kMBMErrorKey, nil];
			LKPresentErrorCodeUsingDict(MBMCantCreateDisabledBundleFolderErrorCode, theDict);
			LKErr(@"Couldn't create the Disabled Bundle folder:%@", error);
			return nil;
		}
	}
	return path;
}

+ (NSArray *)disabledBundlesPathListForDomain:(NSSearchPathDomainMask)domain {
	
	NSError			*error;
	NSMutableArray	*inactiveList = [NSMutableArray array];
	NSFileManager	*manager = [NSFileManager defaultManager];
	NSString		*mailPath = [self mailFolderPathForDomain:domain];
	NSArray			*mailFolders = [manager contentsOfDirectoryAtPath:mailPath error:&error];
	for (NSString *subFolder in mailFolders) {
		if ([subFolder hasPrefix:[self disabledBundleFolderPrefix]]) {
			[inactiveList addObject:[mailPath stringByAppendingPathComponent:subFolder]];
		}
	}
	
	//	Sort the list ascending
	[inactiveList sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSDate	*date1 = [[manager attributesOfItemAtPath:obj1 error:NULL] valueForKey:NSFileCreationDate]; 
		NSDate	*date2 = [[manager attributesOfItemAtPath:obj2 error:NULL] valueForKey:NSFileCreationDate]; 
		return [date1 compare:date2];
	}];
	
	return [NSArray arrayWithArray:inactiveList];
}

#pragma mark Local Domain

+ (NSString *)mailFolderPathLocal {
	return [self mailFolderPathForDomain:NSLocalDomainMask];
}

+ (NSString *)bundlesPathLocalShouldCreate:(BOOL)createNew {
	return [self pathForDomain:NSLocalDomainMask shouldCreate:createNew disabled:NO];
}

+ (NSString *)latestDisabledBundlesPathLocalShouldCreate:(BOOL)createNew {
	return [self pathForDomain:NSLocalDomainMask shouldCreate:createNew disabled:YES];
}

+ (NSArray *)disabledBundlesPathLocalList {
	return [self disabledBundlesPathListForDomain:NSLocalDomainMask];
}

#pragma mark User Domain

+ (NSString *)mailFolderPath {
	return [self mailFolderPathForDomain:NSUserDomainMask];
}

+ (NSString *)bundlesPathShouldCreate:(BOOL)createNew {
	return [self pathForDomain:NSUserDomainMask shouldCreate:createNew disabled:NO];
}

+ (NSString *)latestDisabledBundlesPathShouldCreate:(BOOL)createNew {
	return [self pathForDomain:NSUserDomainMask shouldCreate:createNew disabled:YES];
}

+ (NSArray *)disabledBundlesPathList {
	return [self disabledBundlesPathListForDomain:NSUserDomainMask];
}

#pragma mark Localized Values

+ (NSString *)disabledBundleFolderName {
	NSString	*mailPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:kMBMMailBundleIdentifier];
	NSString	*folderName = [[NSBundle bundleWithPath:mailPath] localizedStringForKey:@"DISABLED_PATH_FORMAT" value:@"Bundles (Disabled)" table:@"Alerts"];
	return [NSString stringWithFormat:folderName, kMBMBundleFolderName, @""];
}
	 
+ (NSString *)disabledBundleFolderPrefix {
	NSString	*folderName = [self disabledBundleFolderName];
	return [folderName substringToIndex:[folderName length] - 2];
}

#pragma mark - Getting Bundle Lists

+ (NSArray *)allMailBundles {
	return [[self allActiveMailBundlesShouldLoadInfo:NO] arrayByAddingObjectsFromArray:[self allDisabledMailBundlesShouldLoadInfo:NO]];
}

+ (NSArray *)allMailBundlesLoadInfo {
	return [[self allActiveMailBundlesShouldLoadInfo:YES] arrayByAddingObjectsFromArray:[self allDisabledMailBundlesShouldLoadInfo:YES]];
}

+ (NSArray *)allActiveMailBundlesShouldLoadInfo:(BOOL)loadInfo {
	
	NSMutableArray	*bundleList = [NSMutableArray array];
	NSFileManager	*manager = [NSFileManager defaultManager];
	NSError			*error;
	
	//	Go through every item in the active bundles folder for user
	for (NSString *aBundleName in [manager contentsOfDirectoryAtPath:[self bundlesPathShouldCreate:NO] error:&error]) {
		//	If it is really a bundle, create an object and add it to our list
		if ([[aBundleName pathExtension] isEqualToString:kMBMMailBundleExtension]) {
			MBMMailBundle	*mailBundle = [self mailBundleForPath:[[self bundlesPathShouldCreate:NO] stringByAppendingPathComponent:aBundleName] shouldLoadInfo:loadInfo];
			if (mailBundle) {
				[bundleList addObject:mailBundle];
			}
		}
	}
	
	//	Go through every item in the active bundles folder for local domain
	for (NSString *aBundleName in [manager contentsOfDirectoryAtPath:[self bundlesPathLocalShouldCreate:NO] error:&error]) {
		//	If it is really a bundle, create an object and add it to our list
		if ([[aBundleName pathExtension] isEqualToString:kMBMMailBundleExtension]) {
			MBMMailBundle	*mailBundle = [self mailBundleForPath:[[self bundlesPathLocalShouldCreate:NO] stringByAppendingPathComponent:aBundleName] shouldLoadInfo:loadInfo];
			if (mailBundle) {
				[bundleList addObject:mailBundle];
			}
		}
	}
	
	return [NSArray arrayWithArray:bundleList];
}

+ (NSArray *)allDisabledMailBundlesShouldLoadInfo:(BOOL)loadInfo {

	NSMutableDictionary	*bundleDict = [NSMutableDictionary dictionary];
	NSFileManager		*manager = [NSFileManager defaultManager];
	NSError				*error;
	
	//	Go through every item in all the disabled bundle folders for both domains
	NSArray	*allDisabledPaths = [[self disabledBundlesPathList] arrayByAddingObjectsFromArray:[self disabledBundlesPathLocalList]];
	for (NSString *aDisabledFolder in allDisabledPaths) {
		for (NSString *aBundleName in [manager contentsOfDirectoryAtPath:aDisabledFolder error:&error]) {
			//	If it is really a bundle, create an object and add it to our dictionary, if it is newer than one already in there, with the same id
			if ([[aBundleName pathExtension] isEqualToString:kMBMMailBundleExtension]) {
				MBMMailBundle	*mailBundle = [self mailBundleForPath:[aDisabledFolder stringByAppendingPathComponent:aBundleName] shouldLoadInfo:loadInfo];
				//	If we got a mailBundle, see if we need to update or set
				if (mailBundle) {
					if ([bundleDict valueForKey:mailBundle.identifier]) {
						if ([mailBundle hasLaterVersionNumberThanBundle:(MBMMailBundle *)[bundleDict valueForKey:mailBundle.identifier]]) {
							[bundleDict setObject:mailBundle forKey:mailBundle.identifier];
						}
					}
					else {
						//	Just set it
						[bundleDict setObject:mailBundle forKey:mailBundle.identifier];
					}
				}
			}
		}
	}
	
	return [bundleDict allValues];
}


#pragma mark - Error Delegate Methods

- (NSString *)overrideErrorDomainForCode:(NSInteger)aCode {
	return @"MBMMailBundleErrorDomain";
}



#pragma mark - Comparator

+ (NSComparisonResult)compareVersion:(NSString *)first toVersion:(NSString *)second {
	
	if (first == nil) {
		return NSOrderedAscending;
	}
	
	if (second == nil) {
		return NSOrderedDescending;
	}
	
	if ([first isEqualToString:second]) {
		return NSOrderedSame;
	}
	
	CGFloat	firstValue = [first floatValue];
	CGFloat	secondValue = [second floatValue];
	
	return ((firstValue < secondValue) ? NSOrderedAscending: NSOrderedDescending);
	
}


#pragma mark - KVO Dependence

+ (NSSet *)keyPathsForValuesAffectingPath {
	return [NSSet setWithObject:@"bundle"];
}

+ (NSSet *)keyPathsForValuesAffectingBundleIdentifier {
	return [NSSet setWithObject:@"bundle"];
}

+ (NSSet *)keyPathsForValuesAffectingVersion {
	return [NSSet setWithObject:@"bundle"];
}


#pragma mark - Description

- (NSString *)description {
	NSMutableString	*newString = [NSMutableString string];
	
	[newString appendString:@"\n>>MBMMailBundle Values<<"];
	[newString appendString:@"\nname:"];
	[newString appendString:self.name];
	[newString appendString:@"\npath:"];
	[newString appendString:self.path];
	[newString appendString:@"\nidentifier:"];
	[newString appendString:self.identifier];
	[newString appendString:@"\nversion:"];
	[newString appendString:self.version];
	[newString appendString:@"\nincompatibleString:"];
	[newString appendString:self.incompatibleString];
	[newString appendString:@"\nincompatibleWithCurrentMail:"];
	[newString appendString:self.incompatibleWithCurrentMail?@"YES":@"NO"];
	[newString appendString:@"\nincompatibleWithFutureMail:"];
	[newString appendString:self.incompatibleWithFutureMail?@"YES":@"NO"];
	[newString appendString:@"\nusesBundleManager:"];
	[newString appendString:self.usesBundleManager?@"YES":@"NO"];
	[newString appendString:@"\nenabled:"];
	[newString appendString:self.enabled?@"YES":@"NO"];
	[newString appendString:@"\ninstalled:"];
	[newString appendString:self.installed?@"YES":@"NO"];
	[newString appendString:@"\ninLocalDomain:"];
	[newString appendString:self.inLocalDomain?@"YES":@"NO"];
	[newString appendString:@"\nhasUpdate:"];
	[newString appendString:self.hasUpdate?@"YES":@"NO"];
	[newString appendString:@"\nlatestVersion:"];
	[newString appendString:self.latestVersion];
	
	return [NSString stringWithString:newString];
}

@end
