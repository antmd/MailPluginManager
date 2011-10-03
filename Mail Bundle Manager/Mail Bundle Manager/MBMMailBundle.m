//
//  MBMMailBundle.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBMMailBundle.h"
#import "MBMAppDelegate.h"

#import "NSBundle+MBMAdditions.h"

@interface MBMMailBundle ()
@property	(nonatomic, copy, readwrite)		NSString		*name;
@property	(nonatomic, copy, readwrite)		NSString		*company;
@property	(nonatomic, copy, readwrite)		NSString		*companyURL;
@property	(nonatomic, copy, readwrite)		NSString		*latestVersion;
@property	(nonatomic, copy, readwrite)		NSString		*iconPath;
@property	(nonatomic, retain, readwrite)		NSImage			*icon;
@property	(nonatomic, retain, readwrite)		NSBundle		*bundle;
@property	(nonatomic, assign, readwrite)		BOOL			hasUpdate;
- (void)updateState;
- (NSString *)companyFromIdentifier;
+ (NSString *)mailFolderPathForDomain:(NSSearchPathDomainMask)domain;
+ (NSString *)pathForDomain:(NSSearchPathDomainMask)domain shouldCreate:(BOOL)createNew disabled:(BOOL)disabledPath;
+ (NSArray *)disabledBundlesPathListForDomain:(NSSearchPathDomainMask)domain;
- (BOOL)supportsSparkleUpdates;
- (void)loadUpdateInformation;
@end

@implementation MBMMailBundle


#pragma mark - Accessors

@synthesize name = _name;
@synthesize company = _company;
@synthesize companyURL = _companyURL;
@synthesize icon = _icon;
@synthesize iconPath = _iconPath;
@synthesize bundle = _bundle;
@synthesize usesBundleManager = _usesBundleManager;
@synthesize latestVersion = _latestVersion;
@synthesize compatibleWithCurrentMail = _compatibleWithCurrentMail;
@synthesize hasUpdate = _hasUpdate;
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
	
	//	Now do the move
	NSError	*error;
	if (![[NSFileManager defaultManager] moveItemAtPath:fromPath toPath:toPath error:&error]) {
		NSLog(@"Error moving bundle (enable/disable):%@", error);
		return;
	}
	
	//	Then update the bundle
	self.bundle = [NSBundle bundleWithPath:toPath];
	
	//	Update all the state
	[self updateState];
}

- (void)setInstalled:(BOOL)installed {
	//	If there is no change, do nothing
	if (installed == _installed) {
		return;
	}
	
	//	Only allow a direct uninstall
	if (installed == YES) {
		ALog(@"Don't use the setter on installed to \"install\" only \"uninstall\"");
		return;
	}
	
	//	Default is to *install* it
	NSString	*fromPath = self.path;
	NSString	*toPath = [[NSHomeDirectory() stringByAppendingPathComponent:@".Trash"] stringByAppendingPathComponent:[self.path lastPathComponent]];
	
	//	Now do the move
	NSError	*error;
	if (![[NSFileManager defaultManager] moveItemAtPath:fromPath toPath:toPath error:&error]) {
		NSLog(@"Error moving bundle (install/trash):%@", error);
		return;
	}
	
	//	Send a notification
	[[NSNotificationCenter defaultCenter] postNotificationName:kMBMMailBundleUninstalledNotification object:self];
	
	//	Then update the bundle
	self.bundle = [NSBundle bundleWithPath:toPath];
	
	//	Update all the state
	[self updateState];
}

- (void)setInLocalDomain:(BOOL)inLocalDomain {
	//	If there is no change or it is installed and not enabled, do nothing
	if ((inLocalDomain == _inLocalDomain) || (_installed && !_enabled)) {
		return;
	}
	
	//	Always putting it into the active bundles for domain
	NSSearchPathDomainMask	domain = inLocalDomain?NSLocalDomainMask:NSUserDomainMask;
	NSString	*fromPath = self.path;
	NSString	*toPath = [[[self class] pathForDomain:domain shouldCreate:YES disabled:NO] stringByAppendingPathComponent:[self.path lastPathComponent]];
	
	//	Now do the move
	NSError	*error;
	if (![[NSFileManager defaultManager] moveItemAtPath:fromPath toPath:toPath error:&error]) {
		NSLog(@"Error moving bundle (domain change):%@", error);
		return;
	}
	
	//	Then update the bundle
	self.bundle = [NSBundle bundleWithPath:toPath];
	
	//	Update all the state
	[self updateState];
}

- (NSString *)company {

	if ([_company isEqualToString:kMBMUnknownCompanyValue]) {
		//	First look for our key
		NSString	*aCompany = [[self.bundle infoDictionary] valueForKey:kMBMCompanyNameKey];
		if (aCompany == nil) {
			
			//	Try our database using the bundleIdentifier
			aCompany = [self companyFromIdentifier];
			
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
			
			//	Get the identifier parts and make the URL
			NSArray		*parts = [self.identifier componentsSeparatedByString:@"."];
			
			NSString	*companyRDN = [NSString stringWithFormat:@"[url]%@.%@", [parts objectAtIndex:0], [parts objectAtIndex:1]];
			aURL = NSLocalizedStringFromTable(companyRDN, kMBMCompaniesInfoFileName, @"");
			if ([aURL isEqualToString:companyRDN]) {
				aURL = [NSString stringWithFormat:@"http://www.%@.%@", [parts objectAtIndex:1], [parts objectAtIndex:0]];
			}
			
		}
		
		//	Release the previous value and copy the new one
		[_companyURL release];
		_companyURL = [aURL copy];
	}
	
	return [[_companyURL retain] autorelease];
}

- (NSString *)companyFromIdentifier {
	NSArray		*parts = [self.identifier componentsSeparatedByString:@"."];
	NSString	*companyRDN = [NSString stringWithFormat:@"%@.%@", [parts objectAtIndex:0], [parts objectAtIndex:1]];
	NSString	*theCompany = NSLocalizedStringFromTable(companyRDN, kMBMCompaniesInfoFileName, @"");
	if ([theCompany isEqualToString:companyRDN]) {
		theCompany = nil;
	}
	return theCompany;
}

- (NSString *)incompatibleString {
	return [NSString stringWithFormat:NSLocalizedString(@"Always disabled in Mac OS X > %@", @"A string as short as possible describing that the plugin is only compatible with the OS until version X"), [self latestOSVersionSupported]];
}

#pragma mark - Memory Management

- (id)initWithPath:(NSString *)bundlePath {
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
		[self performSelector:@selector(loadUpdateInformation) withObject:nil afterDelay:0.1f];
		
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
		NSString	*mailUUID = CurrentMailUUID();
		NSString	*messageUUID = CurrentMessageUUID();
		
		//	Test to ensure that the plugin list contains both the mail and message UUIDs
		if ([supportedUUIDs containsObject:mailUUID] && [supportedUUIDs containsObject:messageUUID]) {
			_compatibleWithCurrentMail = YES;
		}
		
    }
    
    return self;
}


- (void)dealloc {
	self.name = nil;
	self.company = nil;
	self.companyURL = nil;
	self.icon = nil;
	self.iconPath = nil;
	self.bundle = nil;
	self.sparkleDelegate = nil;
	[super dealloc];
}



#pragma mark - Testing

- (void)updateState {
	
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
	NSString		*latestSupported = NSLocalizedString(@"Unknown", @"Text indicating that we couldn't determine the latest version of the OS that this plugin supports");
	NSDictionary	*mailDict = nil;
	NSDictionary	*messageDict = nil;
	NSDictionary	*historicalUUIDs = HistoricalUUIDInformation();
	
	//	Look through all supported values, each time saving the later one
	for (NSString *aUUIDValue in [[[NSBundle bundleWithPath:self.path] infoDictionary] valueForKey:kMBMMailBundleUUIDListKey]) {
		NSDictionary	*anInfoDict = [historicalUUIDs valueForKey:aUUIDValue];
		if ([[anInfoDict valueForKey:kMBMUUIDTypeKey] isEqualToString:kMBMUUIDTypeValueMail]) {
			if ((mailDict == nil) || 
				([[anInfoDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] > [[mailDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue])) {
				mailDict = anInfoDict;
			}
		}
		else if ([[anInfoDict valueForKey:kMBMUUIDTypeKey] isEqualToString:kMBMUUIDTypeValueMessage])  {
			if ((messageDict == nil) || 
				([[anInfoDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] > [[messageDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue])) {
				messageDict = anInfoDict;
			}
		}
	}
	
	//	If either is nil, we can't determine
	if ((mailDict == nil) || (messageDict == nil)) {
		return latestSupported;
	}
	
	//	Then between the two of those, which is the earliest
	if ([[messageDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue] > [[mailDict valueForKey:kMBMUUIDLatestVersionTestKey] integerValue]) {
		latestSupported = [messageDict valueForKey:kMBMUUIDLatestVersionKey];
	}
	else {
		latestSupported = [mailDict valueForKey:kMBMUUIDLatestVersionKey];
	}
	
	return latestSupported;
}

#pragma mark - Actions


- (void)updateIfNecessary {
	
	//	Simply use the standard Sparkle behavior (with an instantiation via the path)
	SUUpdater	*updater = [SUUpdater updaterForBundle:self.bundle];
	if (updater) {
		self.sparkleDelegate = [[[MBMSparkleDelegate alloc] init] autorelease];
		[updater setDelegate:self.sparkleDelegate];
		
		//	Set the Path to relaunch to Mail
		self.sparkleDelegate.relaunchPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:kMBMMailBundleIdentifier];
		
		//	Tell the delegate to quit mail when needed
		self.sparkleDelegate.quitMail = YES;
		//	And also quit this app when done
		self.sparkleDelegate.quitManager = YES;
		
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
	else {
		self.enabled = NO;
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

#pragma mark Delegate

// Sent when a valid update is found by the update driver.
- (void)updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)appcastItem {
	self.latestVersion = [appcastItem displayVersionString];
	self.hasUpdate = YES;
}

// Sent when a valid update is not found.
- (void)updaterDidNotFindUpdate:(SUUpdater *)updater {
	self.latestVersion = self.version;
	self.hasUpdate = NO;
}



#pragma mark - Class Methods

+ (MBMMailBundle *)mailBundleForPath:(NSString *)aBundlePath {
	MBMMailBundle	*newBundle = nil;
	//	Only create a new one if we can load it as a bundle
	if ([NSBundle bundleWithPath:aBundlePath]) {
		newBundle = [[[MBMMailBundle alloc] initWithPath:aBundlePath] autorelease];
	}
	
	return newBundle;
}

#pragma mark - Paths

+ (NSString *)pathForActiveBundleWithName:(NSString *)aBundleName {
	for (NSString *activeBundlePath in [self allActiveMailBundles]) {
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
	return [[self allActiveMailBundles] arrayByAddingObjectsFromArray:[self allDisabledMailBundles]];
}

+ (NSArray *)allActiveMailBundles {
	
	NSMutableArray	*bundleList = [NSMutableArray array];
	NSFileManager	*manager = [NSFileManager defaultManager];
	NSError			*error;
	
	//	Go through every item in the active bundles folder for user
	for (NSString *aBundleName in [manager contentsOfDirectoryAtPath:[self bundlesPathShouldCreate:NO] error:&error]) {
		//	If it is really a bundle, create an object and add it to our list
		if ([[aBundleName pathExtension] isEqualToString:kMBMMailBundleExtension]) {
			MBMMailBundle	*mailBundle = [self mailBundleForPath:[[self bundlesPathShouldCreate:NO] stringByAppendingPathComponent:aBundleName]];
			if (mailBundle) {
				[bundleList addObject:mailBundle];
			}
		}
	}
	
	//	Go through every item in the active bundles folder for local domain
	for (NSString *aBundleName in [manager contentsOfDirectoryAtPath:[self bundlesPathLocalShouldCreate:NO] error:&error]) {
		//	If it is really a bundle, create an object and add it to our list
		if ([[aBundleName pathExtension] isEqualToString:kMBMMailBundleExtension]) {
			MBMMailBundle	*mailBundle = [self mailBundleForPath:[[self bundlesPathLocalShouldCreate:NO] stringByAppendingPathComponent:aBundleName]];
			if (mailBundle) {
				[bundleList addObject:mailBundle];
			}
		}
	}
	
	return [NSArray arrayWithArray:bundleList];
}

+ (NSArray *)allDisabledMailBundles {

	NSMutableDictionary	*bundleDict = [NSMutableDictionary dictionary];
	NSFileManager		*manager = [NSFileManager defaultManager];
	NSError				*error;
	
	//	Go through every item in all the disabled bundle folders for both domains
	NSArray	*allDisabledPaths = [[self disabledBundlesPathList] arrayByAddingObjectsFromArray:[self disabledBundlesPathLocalList]];
	for (NSString *aDisabledFolder in allDisabledPaths) {
		for (NSString *aBundleName in [manager contentsOfDirectoryAtPath:aDisabledFolder error:&error]) {
			//	If it is really a bundle, create an object and add it to our dictionary, if it is newer than one already in there, with the same id
			if ([[aBundleName pathExtension] isEqualToString:kMBMMailBundleExtension]) {
				MBMMailBundle	*mailBundle = [self mailBundleForPath:[aDisabledFolder stringByAppendingPathComponent:aBundleName]];
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

@end
