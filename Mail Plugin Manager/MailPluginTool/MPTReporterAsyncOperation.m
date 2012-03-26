//
//  MPTReporterAsyncOperation.m
//  Mail Plugin Manager
//
//  Created by Scott Little on 26/03/2012.
//  Copyright (c) 2012 Little Known Software. All rights reserved.
//

#import "MPTReporterAsyncOperation.h"
#import "MPTCrashReporter.h"

@interface MPTReporterAsyncOperation ()
@property	(readwrite)			BOOL			isExecuting;
@property	(readwrite)			BOOL			isFinished;
@property	(nonatomic, retain)	MPCMailBundle	*mailBundle;
@end


@implementation MPTReporterAsyncOperation

@synthesize isExecuting = _isExecuting;
@synthesize isFinished = _isFinished;
@synthesize mailBundle = _mailBundle;



#pragma mark - Memory Management

- (id)initWithMailBundle:(MPCMailBundle *)aMailBundleundle {
	self = [super init];
	if (self) {
		_mailBundle = [aMailBundleundle retain];
	}
	return self;
}

- (void)dealloc {
	self.mailBundle = nil;
	
	[super dealloc];
}


#pragma mark - Async Methods

- (void)start {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
	
	[self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
	
	//	Send the reports
	MPTCrashReporter	*reporter = [[[MPTCrashReporter alloc] initWithMailBundle:self.mailBundle] autorelease];
	reporter.delegate = self;
	[reporter sendLatestReports];
	
}


- (void)finish {
	
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
	
    _isExecuting = NO;
    _isFinished = YES;
	
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isConcurrent {
	return YES;
}


#pragma mark - NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	LKErr(@"Crash Reports for %@ Connection [%@]: %@", self.mailBundle.name, connection, error);
	[self finish];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSHTTPURLResponse	*httpResponse = (NSHTTPURLResponse *)response;
	if ([httpResponse statusCode] != 200) {
		//	Something went weird
		LKErr(@"Response from Crash Report on %@:%@", self.mailBundle.name, httpResponse);
	}
	else {
		LKLog(@"Good response from Crash Reports for %@", self.mailBundle.name);
	}
	[self finish];
}


@end
