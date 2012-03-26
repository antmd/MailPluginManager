//
//  MPTPluginCrashReporter.h
//  Mail Plugin Manager
//
//  Created by Scott Little on 27/03/2012.
//  Copyright (c) 2012 Little Known Software. All rights reserved.
//

#import "MPTCrashReporter.h"

#import "MPCMailBundle.h"

typedef enum {
	kMPTReportTypeMail,
	kMPTReportTypePlugin,
	kMPTReportTypeOtherPlugin
} MPTReportType;

@interface MPTPluginCrashReport : MPTCrashReport {
	MPTReportType	_reportType;
}
@property	(nonatomic, assign, readonly)	MPTReportType	reportType;

@end


@interface MPTPluginCrashReporter : MPTCrashReporter {
	MPCMailBundle	*_mailBundle;
}
@property	(nonatomic, retain, readonly)	MPCMailBundle		*mailBundle;
- (id)initWithMailBundle:(MPCMailBundle *)aMailBundle;
@end
