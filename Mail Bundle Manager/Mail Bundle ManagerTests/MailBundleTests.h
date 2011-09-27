//
//  MailBundleTests.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 27/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface MailBundleTests : SenTestCase
@property	(assign)	BOOL	createdMailPath;
@property	(assign)	BOOL	createdBundlesPath;
@property	(assign)	BOOL	createdDisabledBundlePaths;
@property	(nonatomic, copy)	NSString	*testBundlePath;

- (BOOL)removeMailFolderIfCreated;
- (BOOL)removeBundlesFolderIfCreated;
- (BOOL)removeDisabledBundleFoldersIfCreated;
@end
