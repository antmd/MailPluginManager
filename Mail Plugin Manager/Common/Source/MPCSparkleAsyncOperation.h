//
//  MPMSparkleAsyncOperation.h
//  Mail Plugin Manager
//
//  Created by Scott Little on 25/02/2012.
//  Copyright (c) 2012 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Sparkle/Sparkle.h>
#import "SUUpdateDriver.h"

@interface MPCSparkleAsyncOperation : NSOperation {
	BOOL			_isExecuting;
	BOOL			_isFinished;
	SUUpdateDriver	*_updateDriver;
	SUUpdater		*_updater;
}

@property	(readonly)	BOOL			isExecuting;
@property	(readonly)	BOOL			isFinished;
- (id)initWithUpdateDriver:(SUUpdateDriver *)anUpdateDriver updater:(SUUpdater *)anUpdater;
- (void)finish;
@end
