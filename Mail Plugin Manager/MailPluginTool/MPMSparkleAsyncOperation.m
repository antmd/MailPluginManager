//
//  MPMSparkleAsyncOperation.m
//  Mail Plugin Manager
//
//  Created by Scott Little on 25/02/2012.
//  Copyright (c) 2012 Little Known Software. All rights reserved.
//

#import "MPMSparkleAsyncOperation.h"


@interface MPMSparkleAsyncOperation ()
@property	(retain)	SUUpdateDriver	*updateDriver;
@property	(retain)	SUUpdater		*updater;
@end

@implementation MPMSparkleAsyncOperation

@synthesize isExecuting = _isExecuting;
@synthesize isFinished = _isFinished;
@synthesize updateDriver = _updateDriver;
@synthesize updater = _updater;
@synthesize selector = _selector;


#pragma mark - Operation Methods

- (id)initWithUpdateDriver:(SUUpdateDriver *)anUpdateDriver updater:(SUUpdater *)anUpdater selector:(SEL)aSelector {
	self = [super init];
	if (self) {
		_updateDriver = [anUpdateDriver retain];
		_updater = [anUpdater retain];
		_selector = aSelector;
	}
	return self;
}

- (id)initWithUpdateDriver:(SUUpdateDriver *)anUpdateDriver {
	return [self initWithUpdateDriver:anUpdateDriver updater:[anUpdateDriver valueForKey:@"updater"] selector:NSSelectorFromString(@"checkForUpdatesInBgReachabilityCheckWithDriver:")];
}

- (id)initWithUpdater:(SUUpdater *)anUpdater {
	return [self initWithUpdateDriver:nil updater:anUpdater selector:NSSelectorFromString(@"checkForUpdatesInBackground")];
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
	[NSThread detachNewThreadSelector:self.selector toTarget:self.updater withObject:self.updateDriver];
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
