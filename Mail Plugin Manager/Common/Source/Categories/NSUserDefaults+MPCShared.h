//
//  NSUserDefaults+MPCShared.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/10/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MPCMailBundle.h"

@interface NSUserDefaults (MPCShared)
- (NSDictionary *)defaultsForMailBundle:(MPCMailBundle *)mailBundle;
- (NSMutableDictionary *)mutableDefaultsForMailBundle:(MPCMailBundle *)mailBundle;
- (void)setDefaults:(NSDictionary *)newValues forMailBundle:(MPCMailBundle *)mailBundle;

- (NSDictionary *)sandboxedDomainInMailForName:(NSString *)domainName;
- (NSMutableDictionary *)mutableSandboxedDomainInMailForName:(NSString *)domainName;
- (void)setSandboxedDomain:(NSDictionary *)domainDict InMailForName:(NSString *)domainName;
@end
