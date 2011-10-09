//
//  MBMUUIDList.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 10/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MBMRemoteUpdatableList.h"

@interface MBMUUIDList : MBMRemoteUpdatableList
+ (void)loadUUIDListFromCloud;
@end
