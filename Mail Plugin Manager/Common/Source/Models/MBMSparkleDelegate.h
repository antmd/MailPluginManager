//
//  MBMSparkleDelegate.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Sparkle/Sparkle.h>

@class MBMMailBundle;

@interface MBMSparkleDelegate : NSObject {
@private	
	MBMMailBundle	*_mailBundle;
//	NSString		*_relaunchPath;
//	BOOL			_quitMail;
//	BOOL			_quitManager;
}

@property	(nonatomic, retain, readonly)	MBMMailBundle	*mailBundle;
//@property	(nonatomic, copy)				NSString		*relaunchPath;
//@property	(nonatomic, assign)				BOOL			quitMail;
//@property	(nonatomic, assign)				BOOL			quitManager;

- (id)initWithMailBundle:(MBMMailBundle *)aMailBundle;

@end
