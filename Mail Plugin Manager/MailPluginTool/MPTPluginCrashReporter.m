//
//  MPTPluginCrashReporter.m
//  Mail Plugin Manager
//
//  Created by Scott Little on 27/03/2012.
//  Copyright (c) 2012 Little Known Software. All rights reserved.
//

#import "MPTPluginCrashReporter.h"


@interface MPTPluginCrashReport ()
@property	(nonatomic, assign, readwrite)	MPTReportType	reportType;
@end

@implementation MPTPluginCrashReport

@synthesize reportType = _reportType;


#pragma mark - Memory Management

- (id)initWithPath:(NSString *)crashPath forBundleID:(NSString *)aBundleID {
	self = [super initWithPath:crashPath forBundleID:aBundleID];
	if (self) {
		
		//	Set the type, default is mail
		_reportType = kMPTReportTypeMail;
		NSString	*pluginIndicator = @"PlugIn Identifier";
		NSString	*plugInSeachString = [NSString stringWithFormat:@"%@: %@", pluginIndicator, aBundleID];
		if ([_reportContent rangeOfString:plugInSeachString].location != NSNotFound) {
			_reportType = kMPTReportTypePlugin;
		}
		else if ([_reportContent rangeOfString:pluginIndicator].location != NSNotFound) {
			_reportType = kMPTReportTypeOtherPlugin;
		}
		
	}
	return self;
}

#pragma mark - Content Method

- (NSDictionary *)serializableContents {
	NSMutableDictionary	*contents = [[[super serializableContents] mutableCopy] autorelease];
	
	[contents setValue:((self.reportType == kMPTReportTypeMail)?@"mail":@"plugin") forKey:@"type"];
	
	return [NSDictionary dictionaryWithDictionary:contents];
}

@end


@interface MPTPluginCrashReporter ()
@property	(nonatomic, retain, readwrite)	MPCMailBundle		*mailBundle;
@end


@implementation MPTPluginCrashReporter
@synthesize mailBundle = _mailBundle;

#pragma mark - Memory Management

- (id)initWithMailBundle:(MPCMailBundle *)aMailBundle {
	self = [super initWithBundle:aMailBundle.bundle];
	if (self) {
		_mailBundle = [aMailBundle retain];
	}
	return self;
}

- (void)dealloc {
	self.mailBundle = nil;
	
	[super dealloc];
}



#pragma mark - Methods to Override

- (NSDictionary *)otherValuesForReport {
	return [NSDictionary dictionary];
}

- (MPTCrashReport *)validCrashReportWithPath:(NSString *)crashPath {
	//	Parse the report
	MPTPluginCrashReport	*report = [[[MPTPluginCrashReport alloc] initWithPath:crashPath forBundleID:self.mailBundle.identifier] autorelease];
	//	Add it to our list, if it is not some other plugin's report
	if (report.reportType != kMPTReportTypeOtherPlugin) {
		return report;
	}
	return nil;
}

- (NSString *)mainApplicationName {
	return [[[NSBundle bundleWithIdentifier:kMPCMailBundleIdentifier] infoDictionary] objectForKey: @"CFBundleExecutable"];
}



@end
