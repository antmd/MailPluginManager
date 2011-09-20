//
//  MBMSparkleDelegate.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Sparkle/Sparkle.h>

@interface MBMSparkleDelegate : NSObject

@property	(nonatomic, copy)	NSString	*relaunchPath;
@property	(nonatomic, assign)	BOOL		quitMail;
@property	(nonatomic, assign)	BOOL		quitManager;

- (NSString *)pathToRelaunchForUpdater:(SUUpdater *)updater;

@end
