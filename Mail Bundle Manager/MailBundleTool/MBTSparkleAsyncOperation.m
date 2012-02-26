//
//  MBTSparkleAsyncOperation.m
//  Mail Plugin Manager
//
//  Created by Scott Little on 25/02/2012.
//  Copyright (c) 2012 Little Known Software. All rights reserved.
//

#import "MBTSparkleAsyncOperation.h"



@implementation MBTSparkleAsyncOperation

@synthesize isExecuting = _isExecuting;
@synthesize isFinished = _isFinished;
@synthesize updateDriver = _updateDriver;



#pragma mark - Operation Methods

- (id)initWithUpdateDriver:(SUUpdateDriver *)anUpdateDriver {
	self = [super init];
	if (self) {
		_updateDriver = [anUpdateDriver retain];
	}
	return self;
}

- (void)dealloc {
	self.updateDriver = nil;
	
	[super dealloc];
}

- (void)start {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
	
	[self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
	
	//	Run a background thread to see if we need to update this app, using the basic updater directly.
	[NSThread detachNewThreadSelector:NSSelectorFromString(@"checkForUpdatesInBgReachabilityCheckWithDriver:") toTarget:[self.updateDriver valueForKey:@"updater"] withObject:self.updateDriver];
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

@end
