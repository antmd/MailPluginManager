//
//  NSUserDefaults+MBMShared.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MBMMailBundle.h"

@interface NSUserDefaults (MBMShared)
- (NSDictionary *)defaultsForMailBundle:(MBMMailBundle *)mailBundle;
- (NSMutableDictionary *)mutableDefaultsForMailBundle:(MBMMailBundle *)mailBundle;
- (void)setDefaults:(NSDictionary *)newValues forMailBundle:(MBMMailBundle *)mailBundle;
@end
