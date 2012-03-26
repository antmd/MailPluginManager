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
@property	(nonatomic, assign, readwrite)	MPTReportType	reportType;
@property	(nonatomic, copy)				NSString		*bundleID;
@end

@implementation MPTCrashReport
@synthesize reportPath = _reportPath;
@synthesize reportDate = _reportDate;
@synthesize reportContent = _reportContent;
@synthesize reportType = _reportType;
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
		
		//	Set the type, default is mail
		_reportType = kMPTReportTypeMail;
		NSString *plugInSeachString = [NSString stringWithFormat:@"PlugIn Identifier: %@", aBundleID];
		if ([_reportContent rangeOfString:plugInSeachString].location != NSNotFound) {
			_reportType = kMPTReportTypePlugin;
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
	
	[contents setValue:self.reportDate forKey:@"date"];
	[contents setValue:((self.reportType == kMPTReportTypeMail)?@"mail":@"plugin") forKey:@"type"];
	[contents setValue:self.reportContent forKey:@"report"];
	
	return [NSDictionary dictionaryWithDictionary:contents];
}

@end



@interface MPTCrashReporter ()
@property	(nonatomic, retain, readwrite)	MPCMailBundle		*mailBundle;
@property	(nonatomic, retain, readwrite)	MPTCrashReport		*lastMailReport;
@property	(nonatomic, retain, readwrite)	MPTCrashReport		*lastPluginReport;
- (NSArray *)listOfReportsSince:(NSDate *)lastSentDate;
@end

@implementation MPTCrashReporter
@synthesize mailBundle = _mailBundle;
@synthesize lastMailReport = _lastMailReport;
@synthesize lastPluginReport = _lastPluginReport;
@synthesize delegate = _delegate;

#pragma mark - Memory Management

- (id)initWithMailBundle:(MPCMailBundle *)aMailBundle {
	self = [super init];
	if (self) {
		_mailBundle = [aMailBundle retain];
	}
	return self;
}

- (void)dealloc {
	self.mailBundle = nil;
	self.lastMailReport = nil;
	self.lastPluginReport = nil;

	[super dealloc];
}


#pragma mark - Main Sender

- (void)sendLatestReports {
	
	NSMutableDictionary	*contentsToSend = [NSMutableDictionary dictionary];
	
	NSDictionary	*pluginDefaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:self.mailBundle.identifier];
	NSTimeInterval	lastCrashReportInterval = [[pluginDefaults valueForKey:kMPTLastReportDatePrefKey] floatValue];
	NSDate			*lastTimeCrashReported = [NSDate dateWithTimeIntervalSince1970:lastCrashReportInterval];

	//	Add all of the reports
	NSMutableArray	*reportList = [NSMutableArray array];
	for (MPTCrashReport *report in [self listOfReportsSince:lastTimeCrashReported]) {
		//	Add a report content to our list for sending
		[reportList addObject:[report serializableContents]];
	}
	LKLog(@"Report count=%d", [reportList count]);
	
	//	If we found some reports, try to send them
	if (!IsEmpty(reportList)) {
		[contentsToSend setValue:reportList forKey:kMPTReportListKey];
		
		//	Add the system info to the package
		[contentsToSend setValue:[MPCSystemInfo completeInfo] forKey:kMPCSysInfoKey];
		
		//	Determine what the url is to call
		NSURL	*crashReportURL = [NSURL URLWithString:[[self.mailBundle.bundle infoDictionary] valueForKey:kMPCCrashReportURLKey]];
		if (crashReportURL != nil) {
			//	Send the package as JSON
			NSData	*sendData = [contentsToSend JSONData];
			LKLog(@"Data made:%p", sendData);

			NSURLRequest		*theRequest = [NSURLRequest requestWithURL:crashReportURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0f];
			NSURLConnection		*myConnection = [NSURLConnection connectionWithRequest:theRequest delegate:(self.delegate==nil?self:self.delegate)];
			if (myConnection == nil) {
				LKErr(@"Could not create the connection for request: %@", theRequest);
			}
			
		}
		else {
			LKInfo(@"There is no Crash Report URL for plugin:%@", self.mailBundle.name);
			return;
		}
	}

	//	Update the user defs for the plugin
//	NSMutableDictionary	*newDefaults = [pluginDefaults copy];
//	[newDefaults setValue:[NSNumber numberWithFloat:[[NSDate date] timeIntervalSince1970]] forKey:kMPTLastReportDatePrefKey];
//	[[NSUserDefaults standardUserDefaults] setPersistentDomain:newDefaults forName:self.mailBundle.identifier];
//	[[NSUserDefaults standardUserDefaults] synchronize];
//	[newDefaults release];

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


#pragma mark - Methods

- (NSArray *)listOfReportsSince:(NSDate *)lastSentDate {
	
	NSMutableArray	*reports = [NSMutableArray array];
	
	// Get the log file, its last change date and last report date:
	NSString	*mailAppName = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleExecutable"];
	NSString	*crashLogsFolder = [@"~/Library/Logs/CrashReporter/" stringByExpandingTildeInPath];

	
	NSDirectoryEnumerator*	enny = [[NSFileManager defaultManager] enumeratorAtPath:crashLogsFolder];
	NSString	*currName = nil;
	NSString	*crashLogPrefix = [NSString stringWithFormat: @"%@_", mailAppName];
	NSString	*crashLogSuffix = @".crash";
	
	//	Look through all of the crash files of our mail app that are after our date
	while ((currName = [enny nextObject])) {
		if ([currName hasPrefix:crashLogPrefix] && [currName hasSuffix:crashLogSuffix] && 
			[[[enny fileAttributes] fileModificationDate] isGreaterThan:lastSentDate]) {
			//	Add it to our list
			[reports addObject:[[[MPTCrashReport alloc] initWithPath:[crashLogsFolder stringByAppendingPathComponent:currName] forBundleID:self.mailBundle.identifier] autorelease]];
		}
	}
	
	//	Sort the reports
	NSSortDescriptor	*dateSort = [NSSortDescriptor sortDescriptorWithKey:@"reportDate" ascending:YES];
	[reports sortUsingDescriptors:[NSArray arrayWithObject:dateSort]];
	
	return [NSArray arrayWithArray:reports];
	
}

@end
