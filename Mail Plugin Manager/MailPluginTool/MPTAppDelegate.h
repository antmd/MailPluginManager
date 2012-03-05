//
//  MBTAppDelegate.h
//  MailBundleTool
//
//  Created by Scott Little on 28/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MPCAppDelegate.h"

#import "SUBasicUpdateDriver.h"
#import "MPCSparkleAsyncOperation.h"

@interface MPTAppDelegate : MPCAppDelegate {
@private	
	NSMutableDictionary			*_savedSparkleState;
	NSArray						*_sparkleKeysValues;
	MPCSparkleAsyncOperation	*_sparkleOperation;
	SUBasicUpdateDriver			*_updateDriver;
	
}
- (void)doAction:(NSString *)action withArguments:(NSArray *)arguments;


@end
