//
//  MBMCompanyList.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 09/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MBMRemoteUpdatableList.h"

@interface MBMCompanyList : MBMRemoteUpdatableList
+ (NSString *)companyNameFromIdentifier:(NSString *)identifier;
+ (NSString *)companyURLFromIdentifier:(NSString *)identifier;
+ (NSString *)productURLFromIdentifier:(NSString *)identifier;
@end
