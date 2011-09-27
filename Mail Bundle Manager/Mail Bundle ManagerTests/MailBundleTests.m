//
//  MailBundleTests.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 27/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MailBundleTests.h"
#import "MBMMailBundle.h"

@implementation MailBundleTests

#pragma mark - Accessors

@synthesize createdMailPath;
@synthesize createdBundlesPath;
@synthesize createdDisabledBundlePaths;
@synthesize testBundlePath;


#pragma mark - Path Tests

- (void)test_001_Mail_Mail_Path {
	NSString	*result = [@"~/Library/Mail" stringByExpandingTildeInPath];
	
	STAssertEqualObjects([MBMMailBundle mailFolderPath], result, nil);
}

- (void)test_002_Mail_Bundle_Path {
	NSString	*result = [@"~/Library/Mail/Bundles" stringByExpandingTildeInPath];
	
	STAssertEqualObjects([MBMMailBundle bundlesPath], result, nil);
}

- (void)test_003_Mail_Latest_Disabled_Bundle_Path {
	NSString	*result = [@"~/Library/Mail/Bundles (Disabled 101)" stringByExpandingTildeInPath];
	
	STAssertEqualObjects([MBMMailBundle latestDisabledBundlesPath], result, nil);
}

- (void)test_004_Mail_All_Disabled_Bundle_Paths {
	NSString	*disabledKnown1 = [@"~/Library/Mail/Bundles (Disabled 100)" stringByExpandingTildeInPath];
	NSString	*disabledKnown2 = [@"~/Library/Mail/Bundles (Disabled 101)" stringByExpandingTildeInPath];
	NSArray *pathList = [MBMMailBundle disabledBundlesPathList];
	
	STAssertTrue([pathList count] >= 2, nil);
	STAssertEqualObjects([pathList lastObject], disabledKnown2, nil);
	STAssertEqualObjects([pathList objectAtIndex:([pathList count] - 2)], disabledKnown1, nil);
}


#pragma mark - Comparision Tests

- (void)test_010_Compare {
	NSString	*firstVersion = @"3.2";
	NSString	*secondVersion = @"2.9";
	
	STAssertEquals([MBMMailBundle compareVersion:firstVersion toVersion:secondVersion], (NSInteger)NSOrderedDescending, nil);
	STAssertEquals([MBMMailBundle compareVersion:secondVersion toVersion:firstVersion], (NSInteger)NSOrderedAscending, nil);
	STAssertEquals([MBMMailBundle compareVersion:firstVersion toVersion:firstVersion], (NSInteger)NSOrderedSame, nil);
	STAssertEquals([MBMMailBundle compareVersion:secondVersion toVersion:secondVersion], (NSInteger)NSOrderedSame, nil);
}


#pragma mark - Getting Bundles

- (void)test_020_Bundle_From_Path {
	MBMMailBundle	*bundle = [MBMMailBundle mailBundleForPath:self.testBundlePath];
	
	STAssertNotNil(bundle, nil);
	STAssertEquals(bundle.status, kMBMStatusEnabled, nil);
	STAssertNotNil(bundle.bundle, nil);
	STAssertEqualObjects([bundle.bundle class], [NSBundle class], nil);
	STAssertNil(bundle.icon, nil);
	STAssertEqualObjects(bundle.name, @"ExamplePlugin", nil);
	STAssertEqualObjects(bundle.path, self.testBundlePath, nil);
	STAssertEqualObjects(bundle.version, @"1", nil);
}


#pragma mark - Admin

- (void)setUp {
    [super setUp];
    
    // Set-up code here.
	NSError			*error = nil;
	NSFileManager	*manager = [NSFileManager defaultManager];
	
	self.testBundlePath = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/Tests/ExamplePlugin.mailbundle"];
	
	//	Ensure that the mail and bundle folders exist
	if (![manager fileExistsAtPath:[@"~/Library/Mail" stringByExpandingTildeInPath]]) {
		self.createdMailPath = [manager createDirectoryAtPath:[@"~/Library/Mail" stringByExpandingTildeInPath] withIntermediateDirectories:YES attributes:NULL error:&error];
	}
	if (![manager fileExistsAtPath:[@"~/Library/Mail/Bundles" stringByExpandingTildeInPath]]) {
		self.createdBundlesPath = [manager createDirectoryAtPath:[@"~/Library/Mail/Bundles" stringByExpandingTildeInPath] withIntermediateDirectories:YES attributes:NULL error:&error];
	}
	[manager createDirectoryAtPath:[@"~/Library/Mail/Bundles (Disabled 100)" stringByExpandingTildeInPath] withIntermediateDirectories:YES attributes:NULL error:&error];
	self.createdDisabledBundlePaths = [manager createDirectoryAtPath:[@"~/Library/Mail/Bundles (Disabled 101)" stringByExpandingTildeInPath] withIntermediateDirectories:YES attributes:NULL error:&error];
}

- (void)tearDown {
    // Tear-down code here.

	//	Remove any folders that were created
	[self removeMailFolderIfCreated];
	[self removeBundlesFolderIfCreated];
	[self removeDisabledBundleFoldersIfCreated];
	
	self.testBundlePath = nil;
    
    [super tearDown];
}

- (BOOL)removeMailFolderIfCreated {
	BOOL	result = NO;
	if (self.createdMailPath) {
		NSError	*error;
		result = [[NSFileManager defaultManager] removeItemAtPath:[@"~/Library/Mail" stringByExpandingTildeInPath] error:&error];
		self.createdMailPath = !result;
	}
	return result;
}

- (BOOL)removeBundlesFolderIfCreated {
	BOOL	result = NO;
	if (self.createdBundlesPath) {
		NSError	*error;
		result = [[NSFileManager defaultManager] removeItemAtPath:[@"~/Library/Mail/Bundles" stringByExpandingTildeInPath] error:&error];
		self.createdBundlesPath = !result;
	}
	return result;
}

- (BOOL)removeDisabledBundleFoldersIfCreated {
	BOOL	result = NO;
	if (self.createdDisabledBundlePaths) {
		NSError	*error;
		[[NSFileManager defaultManager] removeItemAtPath:[@"~/Library/Mail/Bundles (Disabled 100)" stringByExpandingTildeInPath] error:&error];
		result = [[NSFileManager defaultManager] removeItemAtPath:[@"~/Library/Mail/Bundles (Disabled 101)" stringByExpandingTildeInPath] error:&error];
		self.createdDisabledBundlePaths = !result;
	}
	return result;
}

@end
