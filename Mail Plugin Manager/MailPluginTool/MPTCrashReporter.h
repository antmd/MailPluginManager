//
//  MPTCrashReporter.h
//  Mail Plugin Manager
//
//  Created by Scott Little on 25/03/2012.
//  Copyright (c) 2012 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MPTCrashReport : NSObject {
	NSString		*_reportPath;
	NSDate			*_reportDate;
	NSString		*_reportContent;
@private
	NSString		*_bundleID;
}
@property	(nonatomic, copy, readonly)		NSString		*reportPath;
@property	(nonatomic, retain, readonly)	NSDate			*reportDate;
@property	(nonatomic, copy, readonly)		NSString		*reportContent;
- (id)initWithPath:(NSString *)crashPath forBundleID:(NSString *)aBundleID;
- (NSDictionary *)serializableContents;
@end


@interface MPTCrashReporter : NSObject {
	NSBundle	*_bundle;
	id			_delegate;
}
@property	(nonatomic, retain, readonly)	NSBundle	*bundle;
@property	(nonatomic, assign)				id			delegate;
- (id)initWithBundle:(NSBundle *)aBundle;
- (BOOL)sendLatestReports;
- (NSString *)mainApplicationName;
- (MPTCrashReport *)validCrashReportWithPath:(NSString *)crashPath;
@end
