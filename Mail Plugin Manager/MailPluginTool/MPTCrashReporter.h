//
//  MPTCrashReporter.h
//  Mail Plugin Manager
//
//  Created by Scott Little on 25/03/2012.
//  Copyright (c) 2012 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MPCMailBundle.h"

typedef enum {
	kMPTReportTypeMail,
	kMPTReportTypePlugin,
	kMPTReportTypeOtherPlugin
} MPTReportType;


@interface MPTCrashReport : NSObject {
	NSString		*_reportPath;
	NSDate			*_reportDate;
	NSString		*_reportContent;
	MPTReportType	_reportType;
@private
	NSString		*_bundleID;
}
@property	(nonatomic, copy, readonly)		NSString		*reportPath;
@property	(nonatomic, retain, readonly)	NSDate			*reportDate;
@property	(nonatomic, copy, readonly)		NSString		*reportContent;
@property	(nonatomic, assign, readonly)	MPTReportType	reportType;
- (id)initWithPath:(NSString *)crashPath forBundleID:(NSString *)aBundleID;
- (NSDictionary *)serializableContents;
@end



@interface MPTCrashReporter : NSObject {
	MPCMailBundle	*_mailBundle;
	MPTCrashReport	*_lastMailReport;
	MPTCrashReport	*_lastPluginReport;
	id				_delegate;
}
@property	(nonatomic, retain, readonly)	MPCMailBundle		*mailBundle;
@property	(nonatomic, retain, readonly)	MPTCrashReport		*lastMailReport;
@property	(nonatomic, retain, readonly)	MPTCrashReport		*lastPluginReport;
@property	(nonatomic, assign)				id					delegate;
- (id)initWithMailBundle:(MPCMailBundle *)aMailBundle;
- (BOOL)sendLatestReports;
@end
