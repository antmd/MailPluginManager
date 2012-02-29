//
//  MBTSparkleAsyncOperation.h
//  Mail Plugin Manager
//
//  Created by Scott Little on 25/02/2012.
//  Copyright (c) 2012 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Sparkle/Sparkle.h>
#import "SUUpdateDriver.h"

@interface MBTSparkleAsyncOperation : NSOperation {
	BOOL			_isExecuting;
	BOOL			_isFinished;
	SUUpdateDriver	*_updateDriver;
	SUUpdater		*_updater;
	SEL				_selector;
}

@property	(readonly)	BOOL			isExecuting;
@property	(readonly)	BOOL			isFinished;
@property	(assign)	SEL				selector;
- (id)initWithUpdateDriver:(SUUpdateDriver *)anUpdateDriver updater:(SUUpdater *)anUpdater selector:(SEL)aSelector;
- (id)initWithUpdateDriver:(SUUpdateDriver *)anUpdateDriver;
- (id)initWithUpdater:(SUUpdater *)anUpdater;
- (void)finish;
@end
