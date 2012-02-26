//
//  NSBundle+MBMAdditions.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSBundle (NSBundle_MBMAdditions)

- (NSString *)versionString;

- (BOOL)hasLaterVersionNumberThanBundle:(NSBundle *)otherBundle;

@end
