//
//  MBMRemoteUpdatableList.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 10/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MBMRemoteUpdatableList.h"
#import "NSString+LKHelper.h"


#define DATE_KEY		@"date"
#define CONTENTS_KEY	@"contents"
#define ONE_DAY_AGO		(-1 * 60 * 60 * 24)

@implementation MBMRemoteUpdatableList

@synthesize contents = _contents;
@synthesize date = _date;


+ (void)loadListFromCloud {
	
	NSURL			*theURL = [NSURL URLWithString:[[kMBMRemoteUpdateableListPathURL stringByAppendingPathComponent:[self filename]] stringByAppendingPathExtension:kMBMPlistExtension]];

	NSFileManager	*manager = [NSFileManager defaultManager];
	NSString		*localFilePath = [self localSupportPath];
	NSError			*theError = nil;
	
	//	See if we even have a local file already
	if (![manager fileExistsAtPath:localFilePath]) {
		//	If not, ensure we have the folder, create it if necessary
		BOOL	isDir;
		if (![manager fileExistsAtPath:[localFilePath stringByDeletingLastPathComponent] isDirectory:&isDir]) {
			if (![manager createDirectoryAtPath:[localFilePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&theError]) {
				ALog(@"Couldn't create the application support folder:%@", theError);
				return;
			}
		}
		else if (!isDir) {
			ALog(@"The application support path exists and is not a folder");
			return;
		}
		
		//	Then copy over the default one from the package
		NSString	*packageCompanyFile = [[NSBundle mainBundle] pathForResource:[self filename] ofType:kMBMPlistExtension];
		if (![manager copyItemAtPath:packageCompanyFile toPath:localFilePath error:&theError]) {
			ALog(@"Couldn't put a copy of the default %@ file into place:%@" , [localFilePath lastPathComponent], theError);
			return;
		}
	}
	
	//	Test to see if the last load was within our time limit.
	NSDictionary	*defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:kMBMUserDefaultSharedDomainName];
	NSDate	*previousLoad = [defaults objectForKey:[theURL absoluteString]];
	if ((previousLoad != nil) && [previousLoad laterDate:[NSDate dateWithTimeIntervalSinceNow:ONE_DAY_AGO]]) {
		return;
	}
	
		//	Try to load the plist from the remote server
	NSDictionary	*remoteContents = [NSDictionary dictionaryWithContentsOfURL:theURL];
	
	//	If we got something, then compare the date of that to the one in the App Support folder
	if (remoteContents != nil) {
		NSDate	*remoteDate = [remoteContents valueForKey:DATE_KEY];
		NSDate	*localDate = [[NSDictionary dictionaryWithContentsOfFile:localFilePath] valueForKey:DATE_KEY];
		
		//	If the remote contents are newer than ours, save it
		if ([remoteDate laterDate:localDate]) {
			[remoteContents writeToFile:localFilePath atomically:NO]; 
		}
		
		//	Note that we have loaded this file in the user defaults
		NSMutableDictionary	*changedDefaults = [defaults mutableCopy];
		[changedDefaults setObject:[NSDate date] forKey:[theURL absoluteString]];
		[[NSUserDefaults standardUserDefaults] setPersistentDomain:changedDefaults forName:kMBMUserDefaultSharedDomainName];
		[changedDefaults release];
	}
}

#pragma mark - Internal Methods

- (id)init {
	self = [super init];
	if (self) {
		NSDictionary	*dict = [NSDictionary dictionaryWithContentsOfFile:[[self class] localSupportPath]];
		_contents = [[dict valueForKey:CONTENTS_KEY] retain];
		_date = [[dict valueForKey:DATE_KEY] retain];
	}
	return self;
}

- (void)dealloc {
	self.contents = nil;
	
	[super dealloc];
}

+ (NSString *)filename {
	ALog(@"This should be overriden by the subclass!");
	return nil;
}

+ (NSString *)localSupportPath {
	//	Always use App Support Folder of user
	NSString	*appSupportFolder = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString	*fileName = [[self filename] stringByAppendingPathExtension:kMBMPlistExtension];
	NSString	*localFilePath = [[appSupportFolder stringByAppendingPathComponent:kMBMAppSupportFolderName] stringByAppendingPathComponent:fileName];
	return localFilePath;
}


@end
