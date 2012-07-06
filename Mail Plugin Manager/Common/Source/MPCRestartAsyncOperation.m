//
//  MPCRestartAsyncOperation.m
//  Mail Plugin Manager
//
//  Created by Scott Little on 05/03/2012.
//  Copyright (c) 2012 Little Known Software. All rights reserved.
//

#import "MPCRestartAsyncOperation.h"

@implementation MPCRestartAsyncOperation

@synthesize isExecuting = _isExecuting;
@synthesize isFinished = _isFinished;
@synthesize couldQuitMail = _couldQuitMail;


#pragma mark - Operation Methods

- (id)init {
	return [self initWithTaskBlock:nil];
}

- (id)initWithTaskBlock:(MPCAsyncRestartBlock)aBlock {
	self = [super init];
	if (self) {
		_taskBlock = [aBlock copy];
	}
	return self;
}

- (void)dealloc {
	
	[_taskBlock release];
	[super dealloc];
}


- (void)complete {
	
	// Copy the relauncher into a temporary directory so we can get to it after the new version's installed.
	NSString	*relaunchMailPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"MailPluginRelaunch" ofType:@"app"];
	relaunchMailPath = [relaunchMailPath stringByAppendingPathComponent:@"/Contents/MacOS/MailPluginRelaunch"];
	
    [NSTask launchedTaskWithLaunchPath:relaunchMailPath arguments:[NSArray arrayWithObject:@"0.0"]];

	//	Indicate that the operation is finished.
	[self finish];
}

- (void)start {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
	
	[self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
	
	//	Set up an observer for app termination watch
	__block id appDoneObserver;
	appDoneObserver = [[[NSWorkspace sharedWorkspace] notificationCenter] addObserverForName:NSWorkspaceDidTerminateApplicationNotification object:[NSWorkspace sharedWorkspace] queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
		
		if ([[[[note userInfo] valueForKey:NSWorkspaceApplicationKey] bundleIdentifier] isEqualToString:kMPCMailBundleIdentifier]) {
			
			//	If there is a block, run it first
			if (_taskBlock != nil) {
				_taskBlock();
			}

			//	Complete the task
			[self complete];
			
			//	Remove this observer
			[[NSNotificationCenter defaultCenter] removeObserver:appDoneObserver];
			
		}
	}];
	
	//	If we didn't actually succeed in restarting mail, just finish and set a flag indicating failure
	if (![AppDel quitMail]) {
		if (_taskBlock != nil) {
			_taskBlock();
		}
		[[NSNotificationCenter defaultCenter] removeObserver:appDoneObserver];
		[self finish];
	}
	//	Otherwise the observer will finish after quitting
	
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
