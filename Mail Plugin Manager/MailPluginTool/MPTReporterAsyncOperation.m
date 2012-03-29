//
//  MPTReporterAsyncOperation.m
//  Mail Plugin Manager
//
//  Created by Scott Little on 26/03/2012.
//  Copyright (c) 2012 Little Known Software. All rights reserved.
//

#import "MPTReporterAsyncOperation.h"
#import "MPTPluginCrashReporter.h"

@interface MPTReporterAsyncOperation ()
@property	(readwrite)			BOOL			isExecuting;
@property	(readwrite)			BOOL			isFinished;
@property	(nonatomic, retain)	MPCMailBundle	*mailBundle;
@property	(nonatomic, retain)	NSBundle		*bundle;
@end


@implementation MPTReporterAsyncOperation

@synthesize isExecuting = _isExecuting;
@synthesize isFinished = _isFinished;
@synthesize mailBundle = _mailBundle;
@synthesize bundle = _bundle;


#pragma mark - Memory Management

- (id)initWithMailBundle:(MPCMailBundle *)aMailBundle {
	self = [super init];
	if (self) {
		_mailBundle = [aMailBundle retain];
	}
	return self;
}

- (id)initWithBundle:(NSBundle *)aBundle {
	self = [super init];
	if (self) {
		_bundle = [aBundle retain];
	}
	return self;
}

- (void)dealloc {
	self.mailBundle = nil;
	self.bundle = nil;
	
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
	MPTCrashReporter	*reporter = nil;
	if (self.bundle != nil) {
		reporter = [[[MPTCrashReporter alloc] initWithBundle:self.bundle] autorelease];
	}
	else if (self.mailBundle != nil) {
		reporter = [[[MPTPluginCrashReporter alloc] initWithMailBundle:self.mailBundle] autorelease];
	}
	
	//	If we managed to actually create one...
	reporter.delegate = self;
	if (![reporter sendLatestReports]) {
		[self performSelector:@selector(finish) withObject:nil afterDelay:0.1f];
	}
	
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

- (NSString *)bundleName {
	return (self.mailBundle!=nil)?self.mailBundle.name:[[self.bundle localizedInfoDictionary] valueForKey:(NSString *)kCFBundleExecutableKey];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	LKErr(@"Crash Reports for %@ Connection [%@]: %@", [self bundleName], connection, error);
	[self finish];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSHTTPURLResponse	*httpResponse = (NSHTTPURLResponse *)response;
	if ([httpResponse statusCode] != 200) {
		//	Something went weird
		LKErr(@"Response from Crash Report on %@:%@", [self bundleName], httpResponse);
	}
	else {
		LKLog(@"Good response from Crash Reports for %@", [self bundleName]);
	}
	[self finish];
}


@end
