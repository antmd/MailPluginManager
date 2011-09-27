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

@synthesize name = _name;
@synthesize path = _path;
@synthesize version = _version;
@synthesize icon = _icon;
@synthesize bundle = _bundle;
@synthesize status = _status;
@synthesize sparkleDelegate = _sparkleDelegate;



#pragma marl - Memory Management
			
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



#pragma mark - Accessors

- (void)setStatus:(MBMBundleStatus)newStatus {
	//	If there is no change, do nothing
	if (newStatus == _status) {
		return;
	}
	
	//	If the new status is either enable or disable, then handle that change
	if ((newStatus == kMBMStatusEnabled) || (newStatus == kMBMStatusDisabled)) {
		//	Default is to *enable* it
		NSString	*fromPath = [[self class] bundlesPath];
		NSString	*toPath = self.path;
		
		//	If it is currently enabled, set to change that
		if (_status == kMBMStatusEnabled) {
			fromPath = self.path;
			toPath = [[self class] latestDisabledBundlesPath];
		}
		
		//	Now do the move
		NSError	*error;
		if (![[NSFileManager defaultManager] moveItemAtPath:fromPath toPath:toPath error:&error]) {
			NSLog(@"Error moving bundle (enable/disable):%@", error);
		}
	}
	
	//	Save the new status value
	_status = newStatus;
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
	if (result != NSAlertAlternateReturn) {
		//	If this is the default button, do the remove
		if (result == NSAlertDefaultReturn) {
			
			//	Quit mail
			[MBMAppDelegate quitMail];
			
			//	Move the mailbundle to the trash
			FSRef		bundleSpec;
			OSStatus	specResult = FSPathMakeRef((const UInt8 *)[self.path UTF8String], &bundleSpec, NULL);
			if (specResult == noErr) {
				OSStatus	trashResult = FSMoveObjectToTrashSync(&bundleSpec, NULL, kFSFileOperationDefaultOptions);
				if (trashResult != noErr) {
					LKLog(@"There was an error moving the bundle to the trash, %d", trashResult);
				}
			}
			else {
				LKLog(@"There was an error creating the file spec for the bundle, %d", specResult);
			}
		}
		//	Should diable the plugin
		else {
			self.status = kMBMStatusDisabled;
		}
	}
	
	//	Quit this app now
	[NSApp terminate:self];
}

- (void)sendCrashReports {
	//	TODO: Put in the crash reporting
}

#pragma mark - Class Methods

+ (MBMMailBundle *)mailBundleForIdentifier:(NSString *)aBundleIdentifier {
	
	NSError			*error;
	NSMutableArray	*activeList = [NSMutableArray array];
	NSMutableArray	*inactiveList = [NSMutableArray array];
	
	NSString		*mailPath = [self mailFolderPath];
	NSString		*bundlesPath = [self bundlesPath];
	NSFileManager	*manager = [NSFileManager defaultManager];
	
	//	Build a list of enabled and disabled bundles to look through afterward
	NSArray			*mailFolders = [manager contentsOfDirectoryAtPath:mailPath error:&error];
	for (NSString *subFolder in mailFolders) {
		if ([subFolder isEqualToString:kMBMBundleFolderName]) {
			[activeList addObjectsFromArray:[manager contentsOfDirectoryAtPath:bundlesPath error:&error]];
		}
		else if ([subFolder hasPrefix:kMBMDisabledBundleFolderPrefix]) {
			NSString	*subFolderPath = [mailPath stringByAppendingPathComponent:subFolder];
			for (NSString *disabledItem in [manager contentsOfDirectoryAtPath:[mailPath stringByAppendingPathComponent:subFolder] error:&error]) {
				[inactiveList addObject:[subFolderPath stringByAppendingPathComponent:disabledItem]];
			}
		}
	}
	
	//	Look through the "Mail" folder for all bundles and find either an active one *or* the most recent Disabled one
	MBMMailBundle	*newBundle = nil;
	if ([activeList count] > 0) {
		for (NSString *bundleName in activeList) {
			NSString	*fullBundlePath = [bundlesPath stringByAppendingPathComponent:bundleName];
			NSBundle	*aBundle = [NSBundle bundleWithPath:fullBundlePath];
			if ([[aBundle bundleIdentifier] isEqualToString:aBundleIdentifier]) {
				newBundle = [[[MBMMailBundle alloc] initWithBundleIdentifier:aBundleIdentifier andPath:fullBundlePath] autorelease];
				break;
			}
		}
	}
	
	//	If there is still no bundle, look through disabled items...
	if ((newBundle == nil) && ([inactiveList count] > 0)) {
		NSBundle	*bestBundle = nil;
		for (NSString *inactivePath in inactiveList) {
			NSBundle	*aBundle = [NSBundle bundleWithPath:inactivePath];
			//	Always getting the latest one
			if ([[aBundle bundleIdentifier] isEqualToString:aBundleIdentifier]) {
				if ([aBundle hasLaterVersionNumberThanBundle:bestBundle]) {
					bestBundle = aBundle;
				}
			}
		}
		
		//	If we found one, then use that to create a new instance
		if (bestBundle) {
			newBundle = [[[MBMMailBundle alloc] initWithBundleIdentifier:[bestBundle bundleIdentifier] andPath:[bestBundle bundlePath]] autorelease];
		}
	}
	
	return newBundle;
}

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
	
	//	Sort the list descending
	[inactiveList sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		return [(NSString *)obj1 compare:(NSString *)obj2 options:NSNumericSearch];
	}];

	return [NSArray arrayWithArray:inactiveList];
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
