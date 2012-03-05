//
//  MPCRestartAsyncOperation.h
//  Mail Plugin Manager
//
//  Created by Scott Little on 05/03/2012.
//  Copyright (c) 2012 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^MPCAsyncRestartBlock)(void);

@interface MPCRestartAsyncOperation : NSOperation{
	BOOL					_isExecuting;
	BOOL					_isFinished;
	BOOL					_couldQuitMail;
	MPCAsyncRestartBlock	_taskBlock;
}

- (id)initWithTaskBlock:(MPCAsyncRestartBlock)aBlock;

@property	(readonly)	BOOL		isExecuting;
@property	(readonly)	BOOL		isFinished;
@property	(assign)	BOOL		couldQuitMail;

- (void)finish;

@end
