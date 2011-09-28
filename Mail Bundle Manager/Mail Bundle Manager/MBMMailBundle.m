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
@property	(nonatomic, retain, readwrite)		NSImage			*icon;
@property	(nonatomic, retain, readwrite)		NSBundle		*bundle;
@end

@implementation MBMMailBundle


#pragma mark - Accessors

@synthesize name = _name;
@synthesize icon = _icon;
@synthesize bundle = _bundle;
@synthesize status = _status;
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

- (void)setStatus:(MBMBundleStatus)newStatus {
	//	If there is no change, do nothing
	if (newStatus == _status) {
		return;
	}
	
	//	Default is to *enable* it
	NSString	*fromPath = self.path;
	NSString	*toPath = nil;
	
	//	Change the toPath it we are not enabling it
	switch (newStatus) {
		case kMBMStatusEnabled:
			toPath = [[self class] bundlesPath];
			break;
			
		case kMBMStatusDisabled:
			toPath = [[self class] latestDisabledBundlesPathShouldCreate:YES];
			break;
			
		case kMBMStatusUninstalled:
			toPath = [NSHomeDirectory() stringByAppendingPathComponent:@".Trash"];
			break;
			
			//	For these don't do anything
		case kMBMStatusUnknown:
		default:
			return;
			break;
	}
	
	//	Make the toPath a complete one with the last path component
	toPath = [toPath stringByAppendingPathComponent:[self.path lastPathComponent]];
	
	//	Now do the move
	NSError	*error;
	if (![[NSFileManager defaultManager] moveItemAtPath:fromPath toPath:toPath error:&error]) {
		NSLog(@"Error moving bundle (enable/disable):%@", error);
		return;
	}
	
	//	Then update the bundle
	self.bundle = [NSBundle bundleWithPath:toPath];
	
	//	Save the new status value
	_status = newStatus;
}

- (MBMBundleStatus)status {
	if (_status == kMBMStatusUnknown) {
		//	Have to test disabled first, because the bundles matches as prefix for a disabled
		if ([self isInDisabledBundlesFolder]) {
			_status = kMBMStatusDisabled;
		}
		else if ([self isInActiveBundlesFolder]) {
			_status = kMBMStatusEnabled;
		}
		else {
			_status = kMBMStatusUninstalled;
		}
	}
	return _status;
}


#pragma mark - Memory Management

- (id)initWithPath:(NSString *)bundlePath {
    self = [super init];
    if (self) {
        // Initialization code here.
		self.bundle = [NSBundle bundleWithPath:bundlePath];
		
		//	Get the localized name if there is one
		self.name = [[self.bundle localizedInfoDictionary] valueForKey:(NSString *)kCFBundleNameKey];
		if (self.name == nil) {
			self.name = [[self.bundle infoDictionary] valueForKey:(NSString *)kCFBundleNameKey];
		}
		
		//	Get the image from the icons file
		NSString	*iconFileName = [[self.bundle infoDictionary] valueForKey:@"CFBundleIconFile"];
		self.icon = [[[NSImage alloc] initWithContentsOfFile:[self.bundle pathForImageResource:iconFileName]] autorelease];

    }
    
    return self;
}


- (void)dealloc {
	self.name = nil;
	self.icon = nil;
	self.bundle = nil;
	self.sparkleDelegate = nil;
	[super dealloc];
}



#pragma mark - Testing

- (BOOL)isInActiveBundlesFolder {
	return [[self.path stringByDeletingLastPathComponent] isEqualToString:[[self class] bundlesPath]];
}

- (BOOL)isInDisabledBundlesFolder {
	NSString	*folderPath = [self.path stringByDeletingLastPathComponent];
	for (NSString *disabledPath in [[self class] disabledBundlesPathList]) {
		if ([folderPath isEqualToString:disabledPath]) {
			return YES;
		}
	}
	return NO;
}

- (BOOL)hasLaterVersionNumberThanBundle:(MBMMailBundle *)otherBundle {
	return [self.bundle hasLaterVersionNumberThanBundle:otherBundle.bundle];
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
		self.status = kMBMStatusUninstalled;
	}
	//	Should diable the plugin
	else {
		self.status = kMBMStatusDisabled;
	}
	
	//	Quit this app now
	[NSApp terminate:self];
}

- (void)sendCrashReports {
	//	TODO: Put in the crash reporting
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

+ (NSString *)mailFolderPath {
	return [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:kMBMMailFolderName];
}

+ (NSString *)bundlesPath {
	return [[self mailFolderPath] stringByAppendingPathComponent:kMBMBundleFolderName];;
}

+ (NSString *)latestDisabledBundlesPath {
	return [[self disabledBundlesPathList] lastObject];
}

+ (NSString *)latestDisabledBundlesPathShouldCreate:(BOOL)createNew {
	NSString	*path = [self latestDisabledBundlesPath];
	if (path == nil) {
		NSError		*error;
		if (![[NSFileManager defaultManager] createDirectoryAtPath:[[self mailFolderPath] stringByAppendingPathComponent:[self disabledBundleFolderName]] withIntermediateDirectories:YES attributes:nil error:&error]) {
			LKErr(@"Couldn't create the Disabled Bundle folder:%@", error);
			return nil;
		}
		path = [self latestDisabledBundlesPath];
	}
	return path;
}

+ (NSArray *)disabledBundlesPathList {

	NSError			*error;
	NSMutableArray	*inactiveList = [NSMutableArray array];
	NSFileManager	*manager = [NSFileManager defaultManager];
	NSString		*mailPath = [self mailFolderPath];
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
	
	//	Go through every item in the active bundles folder
	for (NSString *aBundleName in [manager contentsOfDirectoryAtPath:[self bundlesPath] error:&error]) {
		//	If it is really a bundle, create an object and add it to our list
		if ([[aBundleName pathExtension] isEqualToString:kMBMMailBundleExtension]) {
			MBMMailBundle	*mailBundle = [self mailBundleForPath:[[self bundlesPath] stringByAppendingPathComponent:aBundleName]];
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
	
	//	Go through every item in all the disabled bundle folders
	for (NSString *aDisabledFolder in [self disabledBundlesPathList]) {
		for (NSString *aBundleName in [manager contentsOfDirectoryAtPath:aDisabledFolder error:&error]) {
			//	If it is really a bundle, create an object and add it to our dictionary, if it is newer than one already in there, with the same id
			if ([[aBundleName pathExtension] isEqualToString:kMBMMailBundleExtension]) {
				MBMMailBundle	*mailBundle = [self mailBundleForPath:[[self bundlesPath] stringByAppendingPathComponent:aBundleName]];
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

@end
