//
//  MPTCrashReporter.m
//  Mail Plugin Manager
//
//  Created by Scott Little on 25/03/2012.
//  Copyright (c) 2012 Little Known Software. All rights reserved.
//

#import "MPTCrashReporter.h"
#import "MPCSystemInfo.h"
#import "JSONKit.h"

@interface MPTCrashReport ()
@property	(nonatomic, copy, readwrite)	NSString		*reportPath;
@property	(nonatomic, retain, readwrite)	NSDate			*reportDate;
@property	(nonatomic, copy, readwrite)	NSString		*reportContent;
@property	(nonatomic, copy)				NSString		*bundleID;
@end

@implementation MPTCrashReport
@synthesize reportPath = _reportPath;
@synthesize reportDate = _reportDate;
@synthesize reportContent = _reportContent;
@synthesize bundleID = _bundleID;

#pragma mark - Memory Management

- (id)initWithPath:(NSString *)crashPath forBundleID:(NSString *)aBundleID {
	self = [super init];
	if (self) {
		_reportPath = [crashPath copy];
		_bundleID = [aBundleID copy];
		
		// Fetch the newest report from the log:
		NSError		*error;
		NSString	*crashLog = [NSString stringWithContentsOfFile:_reportPath encoding:NSUTF8StringEncoding error:&error];
		NSArray		*separateReports = [crashLog componentsSeparatedByString: @"\n\n**********\n\n"];
		
		//	Save the contents if there is something valid
		if ([separateReports count] > 0) {
			_reportContent = [[separateReports lastObject] copy];
		}
		
		//	Get it's date
		NSDictionary	*fileAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:_reportPath error:&error];
		if (fileAttrs != nil) {
			_reportDate = [fileAttrs fileModificationDate];
		}
		
	}
	return self;
}

- (void)dealloc {
	self.reportPath = nil;
	self.reportDate = nil;
	self.reportContent = nil;
	
	[super dealloc];
}


#pragma mark - Content Method

- (NSDictionary *)serializableContents {
	NSMutableDictionary	*contents = [NSMutableDictionary dictionary];
	
	[contents setValue:[NSString stringWithFormat:@"%@", self.reportDate] forKey:@"date"];
	[contents setValue:@"app" forKey:@"type"];
	[contents setValue:self.bundleID forKey:@"bundle"];
	[contents setValue:self.reportContent forKey:@"report"];
	
	return [NSDictionary dictionaryWithDictionary:contents];
}

@end



@interface MPTCrashReporter ()
@property	(nonatomic, retain, readwrite)	NSBundle		*bundle;
- (NSArray *)listOfReportsSince:(NSDate *)lastSentDate;
@end

@implementation MPTCrashReporter
@synthesize bundle = _bundle;
@synthesize delegate = _delegate;

#pragma mark - Memory Management

- (id)initWithBundle:(NSBundle *)aBundle {
	self = [super init];
	if (self) {
		_bundle = [aBundle retain];
	}
	return self;
}

- (void)dealloc {
	self.bundle = nil;

	[super dealloc];
}


#pragma mar - Abstraction Methods

- (NSDate *)lastCrashReportDate {
	LKLog(@"Getting lastCrashReportDate for:%@", [self.bundle bundleIdentifier]);
	
	NSDictionary	*pluginDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:[self.bundle bundleIdentifier]];
	NSTimeInterval	lastCrashReportInterval = [[pluginDefaults valueForKey:kMPTLastReportDatePrefKey] floatValue];
	return [NSDate dateWithTimeIntervalSince1970:lastCrashReportInterval];
}

- (void)saveNewCrashReportDate {
	//	Update the user defs for the plugin
	NSMutableDictionary	*newDefaults = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:[self.bundle bundleIdentifier]] mutableCopy];
	if (newDefaults == nil) {
		newDefaults = [[NSMutableDictionary alloc] initWithCapacity:1];
	}
	[newDefaults setValue:[NSNumber numberWithFloat:[[NSDate date] timeIntervalSince1970]] forKey:kMPTLastReportDatePrefKey];
	[[NSUserDefaults standardUserDefaults] setPersistentDomain:newDefaults forName:[self.bundle bundleIdentifier]];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[newDefaults release];
}

- (NSURL *)reportURL {
	return [NSURL URLWithString:[[self.bundle infoDictionary] valueForKey:kMPCCrashReportURLKey]];
}

- (NSArray *)listOfReportsSince:(NSDate *)lastSentDate {
	
	NSMutableArray	*reports = [NSMutableArray array];
	
	// Get the log file, its last change date and last report date:
	NSString	*appName = [self mainApplicationName];
	NSString	*crashLogsFolder = [@"~/Library/Logs/DiagnosticReports/" stringByExpandingTildeInPath];
	
	NSDirectoryEnumerator*	enny = [[NSFileManager defaultManager] enumeratorAtPath:crashLogsFolder];
	NSString	*currName = nil;
	NSString	*crashLogPrefix = [NSString stringWithFormat: @"%@_", appName];
	NSString	*crashLogSuffix = @".crash";
	
	//	Look through all of the crash files of our app that are after our date
	while ((currName = [enny nextObject])) {
		if ([currName hasPrefix:crashLogPrefix] && [currName hasSuffix:crashLogSuffix] && 
			[[[enny fileAttributes] fileCreationDate] isGreaterThan:lastSentDate]) {
			
			//	Parse the report and add it if it is not nil
			MPTCrashReport	*report = [self validCrashReportWithPath:[crashLogsFolder stringByAppendingPathComponent:currName]];
			if (report != nil) {
				[reports addObject:report];
			}
		}
	}
	
	//	Sort the reports
	NSSortDescriptor	*dateSort = [NSSortDescriptor sortDescriptorWithKey:@"reportDate" ascending:NO];
	[reports sortUsingDescriptors:[NSArray arrayWithObject:dateSort]];
	
	return [NSArray arrayWithArray:reports];
	
}


#pragma mark - Methods to Override

- (MPTCrashReport *)validCrashReportWithPath:(NSString *)crashPath {
	//	Parse the report
	return [[[MPTCrashReport alloc] initWithPath:crashPath forBundleID:[self.bundle bundleIdentifier]] autorelease];
}

- (NSString *)mainApplicationName {
	return [[self.bundle infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey];
}


#pragma mark - Main Sender

- (BOOL)sendLatestReports {
	
	NSMutableDictionary	*contentsToSend = [NSMutableDictionary dictionary];
	
	NSDate			*lastTimeCrashReported = [self lastCrashReportDate];

	//	Add up to 10 of the reports (to avoid issues with server max post issue)
	NSArray			*allReports = [self listOfReportsSince:lastTimeCrashReported];
	NSUInteger		reportCount = [[[self.bundle infoDictionary] valueForKey:kMPCMaxCrashReportCountKey] integerValue];
	if (reportCount == 0) {
		reportCount = 20;
	}
	NSMutableArray	*reportList = [NSMutableArray array];
	for (MPTCrashReport *report in allReports) {
		//	Add a report content to our list for sending
		[reportList addObject:[report serializableContents]];
		reportCount--;
		if (reportCount == 0) {
			break;
		}
	}
	LKLog(@"Total Report count=%d", [allReports count]);
	
	//	If we didn't find any reports we are done
	if (IsEmpty(reportList)) {
		return NO;
	}
	//	Otherwise send them
	else {
		[contentsToSend setValue:[NSNumber numberWithInteger:[allReports count]] forKey:@"total-report-count"];
		[contentsToSend setValue:reportList forKey:kMPTReportListKey];
		
		//	Add the system info to the package
		[contentsToSend setValue:[MPCSystemInfo completeInfo] forKey:kMPCSysInfoKey];
		
		//	Determine what the url is to call
		NSURL	*crashReportURL = [self reportURL];
		if (crashReportURL != nil) {

			//	Send the package as JSON
			NSData	*sendData = [contentsToSend JSONData];

			NSMutableURLRequest		*theRequest = [NSMutableURLRequest requestWithURL:crashReportURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0f];
			[theRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
			[theRequest setHTTPMethod:@"POST"];
			[theRequest setHTTPBody:sendData];
			NSURLConnection		*myConnection = [NSURLConnection connectionWithRequest:theRequest delegate:(self.delegate==nil?self:self.delegate)];
			if (myConnection == nil) {
				LKErr(@"Could not create the connection for request: %@", theRequest);
				return NO;
			}
			
		}
		else {
			LKInfo(@"There is no Crash Report URL for bundle:%@", [[self.bundle localizedInfoDictionary] valueForKey:(NSString *)kCFBundleExecutableKey]);
			return NO;
		}
	}

	//	Update the user defs for the plugin
	[self saveNewCrashReportDate];

	return YES;
}

#pragma mark - NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	LKErr(@"Send Crash Connection [%@]: %@", connection, error);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSHTTPURLResponse	*httpResponse = (NSHTTPURLResponse *)response;
	if ([httpResponse statusCode] != 200) {
		//	Something went weird
		LKErr(@"Reponse from Send Crash:%@", httpResponse);
	}
}


@end
