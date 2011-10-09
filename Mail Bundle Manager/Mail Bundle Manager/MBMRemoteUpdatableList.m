//
//  MBMRemoteUpdatableList.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 10/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MBMRemoteUpdatableList.h"


#define DATE_KEY		@"date"

@implementation MBMRemoteUpdatableList

@synthesize contents = _contents;

+ (void)loadListFromCloudURL:(NSURL *)theURL {
	//	Try to load the plist from the remote server
	NSDictionary	*remoteContents = [NSDictionary dictionaryWithContentsOfURL:theURL];
	
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
	
	//	Then load the local file contents
	NSDictionary	*localContents = [NSDictionary dictionaryWithContentsOfFile:localFilePath];
	
	//	If we got something, then compare the date of that to the one in the App Support folder
	if (remoteContents != nil) {
		NSDate	*remoteDate = [remoteContents valueForKey:DATE_KEY];
		NSDate	*localDate = [localContents valueForKey:DATE_KEY];
		
		//	If the remote contents are newer than ours, save it
		if ([remoteDate laterDate:localDate]) {
			[remoteContents writeToFile:localFilePath atomically:NO]; 
		}
	}
}

#pragma mark - Internal Methods

- (id)init {
	self = [super init];
	if (self) {
		self.contents = [NSDictionary dictionaryWithContentsOfFile:[[self class] localSupportPath]];
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
	NSString		*appSupportFolder = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
	NSString		*fileName = [[self filename] stringByAppendingPathExtension:kMBMPlistExtension];
	NSString		*localFilePath = [[appSupportFolder stringByAppendingPathComponent:kMBMAppSupportFolderName] stringByAppendingPathComponent:fileName];
	return localFilePath;
}


@end
