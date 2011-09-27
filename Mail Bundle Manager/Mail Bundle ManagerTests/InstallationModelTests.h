//
//  InstallationModelTests.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 27/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface InstallationModelTests : SenTestCase
@property	(nonatomic, retain)	NSString		*bundleContentsPath;
@property	(nonatomic, retain)	NSString		*userHomePath;
@property	(nonatomic, retain)	NSString		*filePath;
@property	(nonatomic, retain)	NSDictionary	*fileContents;
@property	(nonatomic, retain)	NSArray			*installItemContents;
@property	(nonatomic, retain)	NSDictionary	*installItem1;
@property	(nonatomic, retain)	NSDictionary	*installItem2;
@property	(nonatomic, retain)	NSDictionary	*installItem3;
@property	(nonatomic, retain)	NSDictionary	*installItem4;
@property	(nonatomic, retain)	NSArray			*confirmStepContents;
@property	(nonatomic, retain)	NSDictionary	*confirmStep1;
@property	(nonatomic, retain)	NSDictionary	*confirmStep2;
@property	(nonatomic, retain)	NSDictionary	*confirmStep3;
@property	(nonatomic, retain)	NSDictionary	*confirmStep4;
@end
