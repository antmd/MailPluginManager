//
//  MPTReporterAsyncOperation.h
//  Mail Plugin Manager
//
//  Created by Scott Little on 26/03/2012.
//  Copyright (c) 2012 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPCMailBundle.h"

@interface MPTReporterAsyncOperation : NSOperation {
	BOOL					_isExecuting;
	BOOL					_isFinished;
	MPCMailBundle			*_mailBundle;
}

- (id)initWithMailBundle:(MPCMailBundle *)aMailBundleundle;

@property	(readonly)	BOOL		isExecuting;
@property	(readonly)	BOOL		isFinished;

- (void)finish;

@end
