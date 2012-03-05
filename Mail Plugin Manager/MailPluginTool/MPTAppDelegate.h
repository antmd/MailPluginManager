//
//  MBTAppDelegate.h
//  MailBundleTool
//
//  Created by Scott Little on 28/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MBAppDelegate.h"

#import "SUBasicUpdateDriver.h"
#import "MPMSparkleAsyncOperation.h"

@interface MPTAppDelegate : MBAppDelegate {
@private	
	NSMutableDictionary			*_savedSparkleState;
	NSArray						*_sparkleKeysValues;
	MPMSparkleAsyncOperation	*_sparkleOperation;
	SUBasicUpdateDriver			*_updateDriver;
	
}
- (void)doAction:(NSString *)action withArguments:(NSArray *)arguments;


@end
