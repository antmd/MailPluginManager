//
//  NSBundle+MPCAdditions.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (NSBundle_MPCAdditions)

- (NSString *)versionString;
- (NSString *)shortVersionString;

- (BOOL)hasLaterVersionNumberThanBundle:(NSBundle *)otherBundle;

@end
