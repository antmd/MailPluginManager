//
//  UKCrashReporter.m
//  NiftyFeatures
//
//  Created by Uli Kusterer on Sat Feb 04 2006.
//  Copyright (c) 2006 Uli Kusterer.
//
//	This software is provided 'as-is', without any express or implied
//	warranty. In no event will the authors be held liable for any damages
//	arising from the use of this software.
//
//	Permission is granted to anyone to use this software for any purpose,
//	including commercial applications, and to alter it and redistribute it
//	freely, subject to the following restrictions:
//
//	   1. The origin of this software must not be misrepresented; you must not
//	   claim that you wrote the original software. If you use this software
//	   in a product, an acknowledgment in the product documentation would be
//	   appreciated but is not required.
//
//	   2. Altered source versions must be plainly marked as such, and must not be
//	   misrepresented as being the original software.
//
//	   3. This notice may not be removed or altered from any source
//	   distribution.
//

// -----------------------------------------------------------------------------
//	Headers:
// -----------------------------------------------------------------------------

#import "UKCrashReporter.h"

// -----------------------------------------------------------------------------
//	UKCrashReporterCheckForCrash:
//		This submits the crash report to a CGI form as a POST request by
//		passing it as the request variable "crashlog".
//	
//		KNOWN LIMITATION:	If the app crashes several times in a row, only the
//							last crash report will be sent because this doesn't
//							walk through the log files to try and determine the
//							dates of all reports.
//
//		This is written so it works back to OS X 10.2, or at least gracefully
//		fails by just doing nothing on such older OSs. This also should never
//		throw exceptions or anything on failure. This is an additional service
//		for the developer and *mustn't* interfere with regular operation of the
//		application.
// -----------------------------------------------------------------------------

NSString*	UKCrashReporterCheckForCrash(NSString *plugInIdentifier)
{
	NSAutoreleasePool*	pool = [[NSAutoreleasePool alloc] init];
	NSString *latestCrashReport = nil;
    
	NS_DURING
		SInt32	sysvMajor = 0, sysvMinor = 0, sysvBugfix = 0;
        Gestalt( gestaltSystemVersionMajor, &sysvMajor );
        Gestalt( gestaltSystemVersionMinor, &sysvMinor );
        Gestalt( gestaltSystemVersionBugFix, &sysvBugfix );
		BOOL	isTenFiveOrBetter = sysvMajor >= 10 && sysvMinor >= 5;
		
		// Get the log file, its last change date and last report date:
		NSString*		appName = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleExecutable"];
		NSString*		crashLogsFolder = [@"~/Library/Logs/CrashReporter/" stringByExpandingTildeInPath];
		NSString*		crashLogName = [appName stringByAppendingString: @".crash.log"];
		NSString*		crashLogPath = nil;
		if( !isTenFiveOrBetter )
        {
			crashLogPath = [crashLogsFolder stringByAppendingPathComponent: crashLogName];
        }
		else
        {
            NSDirectoryEnumerator*	enny = [[NSFileManager defaultManager] enumeratorAtPath: crashLogsFolder];
            NSString*				currName = nil;
            NSString*				crashLogPrefix = [NSString stringWithFormat: @"%@_",appName];
            NSString*				crashLogSuffix = @".crash";
            NSString*				foundName = nil;
            NSDate*					foundDate = nil;
            
            // Find the newest of our crash log files:
            while(( currName = [enny nextObject] ))
            {
                if( [currName hasPrefix: crashLogPrefix] && [currName hasSuffix: crashLogSuffix] )
                {
                    NSDate*	currDate = [[enny fileAttributes] fileModificationDate];
                    if( foundName )
                    {
                        if( [currDate isGreaterThan: foundDate] )
                        {
                            foundName = currName;
                            foundDate = currDate;
                        }
                    }
                    else
                    {
                        foundName = currName;
                        foundDate = currDate;
                    }
                }
            }
            
            if( foundName )
                crashLogPath = [crashLogsFolder stringByAppendingPathComponent: foundName];
        }
    
		NSDictionary*	fileAttrs = [[NSFileManager defaultManager] fileAttributesAtPath: crashLogPath traverseLink: YES];
		NSDate*			lastTimeCrashLogged = (fileAttrs == nil) ? nil : [fileAttrs fileModificationDate];
		NSTimeInterval	lastCrashReportInterval = [[NSUserDefaults standardUserDefaults] floatForKey: @"UKCrashReporterLastCrashReportDate"];
		NSDate*			lastTimeCrashReported = [NSDate dateWithTimeIntervalSince1970: lastCrashReportInterval];
		
		if( lastTimeCrashLogged )	// We have a crash log file and its mod date? Means we crashed sometime in the past.
		{
			// If we never before reported a crash or the last report lies before the last crash:
			if( [lastTimeCrashReported compare: lastTimeCrashLogged] == NSOrderedAscending )
			{
				// Fetch the newest report from the log:
				NSString*			crashLog = [NSString stringWithContentsOfFile: crashLogPath encoding: NSUTF8StringEncoding error: nil];	// +++ Check error.
				NSArray*			separateReports = [crashLog componentsSeparatedByString: @"\n\n**********\n\n"];
				NSString*			currentReport = [separateReports count] > 0 ? [separateReports objectAtIndex: [separateReports count] -1] : @"*** Couldn't read Report ***";	// 1 since report 0 is empty (file has a delimiter at the top).
                
                NSString *plugInSeachString = [NSString stringWithFormat:@"PlugIn Identifier: %@", plugInIdentifier];
                if ([currentReport rangeOfString:plugInSeachString].location != NSNotFound)
                {
                    latestCrashReport = [currentReport retain];
                    
                    NSString *defaultsKey = [NSString stringWithFormat:@"UKCrashReporterLastCrashReportDate%@", plugInIdentifier];
                    [[NSUserDefaults standardUserDefaults] setFloat: [[NSDate date] timeIntervalSince1970] forKey: defaultsKey];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
			}
		}
	NS_HANDLER
		NSLog(@"Error during check for crash: %@",localException);
	NS_ENDHANDLER
	
	[pool release];
    
    return [latestCrashReport autorelease];
}



