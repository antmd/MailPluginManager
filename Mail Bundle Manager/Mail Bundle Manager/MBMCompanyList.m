//
//  MBMCompanyList.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 09/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import "MBMCompanyList.h"


#define DATE_KEY		@"date"
#define CANONICAL_KEY	@"canonical"
#define URL_KEY			@"url"


@interface MBMCompanyList ()
@property	(nonatomic, retain)		NSDictionary	*contents;
+ (MBMCompanyList *)sharedInstance;
+ (NSString *)localPath;
+ (NSDictionary *)companyDictForIdentifier:(NSString *)companyRDN;
@end

@implementation MBMCompanyList

@synthesize contents = _contents;


#pragma Mark - External Methods

+ (void)loadCompanyListFromCloud {
	//	Try to load the plist from the remote server
	NSURL			*theURL = [NSURL URLWithString:@"http://lkslocal/mbm-companies.plist"];
	NSDictionary	*theCompanies = [NSDictionary dictionaryWithContentsOfURL:theURL];
	
	NSFileManager	*manager = [NSFileManager defaultManager];
	NSString		*localFilePath = [self localPath];
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
		NSString	*packageCompanyFile = [[NSBundle mainBundle] pathForResource:kMBMCompaniesInfoFileName ofType:kMBMPlistExtension];
		if (![manager copyItemAtPath:packageCompanyFile toPath:localFilePath error:&theError]) {
			ALog(@"Couldn't put a copy of the default %@ file into place:%@" , [localFilePath lastPathComponent], theError);
			return;
		}
	}
	
	//	Then load the local file contents
	NSDictionary	*localCompanies = [NSDictionary dictionaryWithContentsOfFile:localFilePath];
	
	//	If we got something, then compare the date of that to the one in the App Support folder
	if (theCompanies != nil) {
		NSDate	*remoteDate = [theCompanies valueForKey:DATE_KEY];
		NSDate	*localDate = [localCompanies valueForKey:DATE_KEY];
		
		//	If the remote contents are newer than ours, save it
		if ([remoteDate laterDate:localDate]) {
			[theCompanies writeToFile:localFilePath atomically:NO]; 
		}
	}
}


#pragma mark Value Getters

+ (NSString *)companyNameFromIdentifier:(NSString *)identifier {
	return [[self companyDictForIdentifier:identifier] valueForKey:kMBMNameKey];
}

+ (NSString *)companyURLFromIdentifier:(NSString *)identifier {
	NSString	*url = [[self companyDictForIdentifier:identifier] valueForKey:URL_KEY];
	if (url == nil) {
		NSArray	*parts = [identifier componentsSeparatedByString:@"."];
		url = [NSString stringWithFormat:@"http://www.%@.%@", [parts objectAtIndex:1], [parts objectAtIndex:0]];
	}
	return url;
}

+ (NSString *)productURLFromIdentifier:(NSString *)identifier {
	return [[self companyDictForIdentifier:identifier] valueForKey:identifier];
}


#pragma mark - Internal Methods

- (id)init {
	self = [super init];
	if (self) {
		self.contents = [NSDictionary dictionaryWithContentsOfFile:[[self class] localPath]];
	}
	return self;
}

- (void)dealloc {
	self.contents = nil;

	[super dealloc];
}

+ (MBMCompanyList *)sharedInstance {
	static dispatch_once_t	once;
	static MBMCompanyList	*sharedHelper;
	
	dispatch_once(&once, ^{ sharedHelper = [[self alloc] init]; });
	return sharedHelper;
}

+ (NSString *)localPath {
	NSString		*appSupportFolder = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, NO) lastObject];
	NSString		*fileName = [kMBMCompaniesInfoFileName stringByAppendingPathExtension:kMBMPlistExtension];
	NSString		*localFilePath = [[appSupportFolder stringByAppendingPathComponent:kMBMAppSupportFolderName] stringByAppendingPathComponent:fileName];
	return localFilePath;
}

+ (NSDictionary *)companyDictForIdentifier:(NSString *)identifier {
	NSDictionary	*list = [[self sharedInstance] contents];
	
	NSArray			*parts = [identifier componentsSeparatedByString:@"."];
	NSString		*companyRDN = [NSString stringWithFormat:@"%@.%@", [parts objectAtIndex:0], [parts objectAtIndex:1]];
	NSDictionary	*theCompany = [list valueForKey:companyRDN];
	if ([theCompany valueForKey:CANONICAL_KEY]) {
		theCompany = [list valueForKey:[theCompany valueForKey:CANONICAL_KEY]];
	}
	return theCompany;
}

@end
