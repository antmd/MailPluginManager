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
@property	(nonatomic, copy, readwrite)		NSString		*path;
@property	(nonatomic, copy, readwrite)		NSString		*version;
@property	(nonatomic, retain, readwrite)		NSImage			*icon;
@property	(nonatomic, retain, readwrite)		NSBundle		*bundle;
@end

@implementation MBMMailBundle


#pragma mark - Accessors

@synthesize name = _name;
@synthesize path = _path;
@synthesize version = _version;
@synthesize icon = _icon;
@synthesize bundle = _bundle;
@synthesize status = _status;
@synthesize sparkleDelegate = _sparkleDelegate;

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
	
	//	Then update the path
	self.path = toPath;
	
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

- (id)initWithBundleIdentifier:(NSString *)aBundleIdentifier andPath:(NSString *)bundlePath {
    self = [super init];
    if (self) {
        // Initialization code here.
		self.bundle = [NSBundle bundleWithPath:bundlePath];
		self.path = bundlePath;
		self.version = [self.bundle versionString];
		
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
	self.path = nil;
	self.version = nil;
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
	NSBundle		*bundle = [NSBundle bundleWithPath:aBundlePath];
	if (bundle) {
		newBundle = [[[MBMMailBundle alloc] initWithBundleIdentifier:[bundle bundleIdentifier] andPath:[bundle bundlePath]] autorelease];
	}
	
	return newBundle;
}

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
		if ([subFolder hasPrefix:kMBMDisabledBundleFolderPrefix]) {
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
	return [NSString stringWithFormat:folderName, @"Bundles", @""];
}


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
