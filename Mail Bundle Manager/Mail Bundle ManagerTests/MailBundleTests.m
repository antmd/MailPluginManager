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

- (void)test_005_Mail_Latest_Disabled_Bundle_Path_With_Creation {

	//	Remove the disabled folders and ensure that we can continue
	[self removeDisabledBundleFoldersIfCreated];
	if ([MBMMailBundle latestDisabledBundlesPath] != nil) {
		STFail(@"This test will not work properly when there are existing 'Bundles (Disabled X)' folders");
		return;
	}

	//	Try to get the latestDisabled with creation
	NSError		*error;
	NSString	*disabledPath = [MBMMailBundle latestDisabledBundlesPathShouldCreate:YES];
	STAssertNotNil(disabledPath, nil);
	STAssertTrue([[disabledPath lastPathComponent] isEqualToString:[MBMMailBundle disabledBundleFolderName]], nil);
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:disabledPath error:&error], @"Removing folder after test failed:%@", error);
	STAssertNil([MBMMailBundle latestDisabledBundlesPath], nil);
}

- (void)test_006_Mail_Latest_Disabled_Folder_Is_Numbered {

	//	Remove the disabled folders and ensure that we can continue
	[self removeDisabledBundleFoldersIfCreated];
	if ([MBMMailBundle latestDisabledBundlesPath] != nil) {
		STFail(@"This test will not work properly when there are existing 'Bundles (Disabled X)' folders");
		return;
	}
	
	//	Then create two disabled ones and ensure that we get the right one back (as latest)
	//	First one sue the method and test that it was created
	NSString	*disabledPath = [MBMMailBundle latestDisabledBundlesPathShouldCreate:YES];
	STAssertNotNil(disabledPath, nil);
	STAssertTrue([[disabledPath lastPathComponent] isEqualToString:[MBMMailBundle disabledBundleFolderName]], nil);
	
	//	Wait 2 seconds to give a difference in order for the two folders
	NSTimeInterval theInterval = 0;
    NSDate *date = [NSDate date];
    while (theInterval <= 2.0) {
        theInterval = [[NSDate date] timeIntervalSinceDate:date];
    }
	
	//	Then manually create another
	NSError		*error;
	NSString	*secondPath = [[MBMMailBundle mailFolderPath] stringByAppendingPathComponent:@"Bundles (Disabled 1)"];
	STAssertTrue([[NSFileManager defaultManager] createDirectoryAtPath:secondPath withIntermediateDirectories:NO attributes:NULL error:&error], @"Removing folder after test failed:%@", error);
	
	//	Then see what we get back as the latest
	STAssertEqualObjects([[MBMMailBundle latestDisabledBundlesPath] lastPathComponent], @"Bundles (Disabled 1)", nil);
	
	//	Clean up
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:disabledPath error:&error], @"Removing 1st folder after test failed:%@", error);
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:secondPath error:&error], @"Removing 2nd folder after test failed:%@", error);
	STAssertNil([MBMMailBundle latestDisabledBundlesPath], nil);
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
	STAssertEquals(bundle.status, kMBMStatusUninstalled, nil);
	STAssertNotNil(bundle.bundle, nil);
	STAssertEqualObjects([bundle.bundle class], [NSBundle class], nil);
	STAssertNil(bundle.icon, nil);
	STAssertEqualObjects(bundle.name, @"ExamplePlugin", nil);
	STAssertEqualObjects(bundle.path, self.testBundlePath, nil);
	STAssertEqualObjects(bundle.version, @"1", nil);
}

- (void)test_021_Bundle_Copied_Into_Active {

	//	Use a UUID to create a unique filename
	NSString	*bundleInPlacePath = [[MBMMailBundle bundlesPath] stringByAppendingPathComponent:[[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension:@"mailbundle"]];
	
	NSError		*error;
	STAssertTrue([[NSFileManager defaultManager] copyItemAtPath:self.testBundlePath toPath:bundleInPlacePath error:&error], @"Copying the bundle into the bundles folder failed:%@", error);

	MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:bundleInPlacePath];
	
	STAssertNotNil(mailBundle, nil);
	STAssertEquals(mailBundle.status, kMBMStatusEnabled, nil);
	STAssertNotNil(mailBundle.bundle, nil);
	STAssertEqualObjects([mailBundle.bundle class], [NSBundle class], nil);
	STAssertNil(mailBundle.icon, nil);
	STAssertEqualObjects(mailBundle.name, @"ExamplePlugin", nil);
	STAssertEqualObjects(mailBundle.path, bundleInPlacePath, nil);
	STAssertEqualObjects(mailBundle.version, @"1", nil);
	
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:bundleInPlacePath error:&error], @"Removing bundle after test failed:%@", error);
}

- (void)test_022_Bundle_Copied_Into_Last_Disabled {
	
	//	Use a UUID to create a unique filename
	NSString	*bundleInPlacePath = [[MBMMailBundle latestDisabledBundlesPath] stringByAppendingPathComponent:[[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension:@"mailbundle"]];
	
	NSError		*error;
	STAssertTrue([[NSFileManager defaultManager] copyItemAtPath:self.testBundlePath toPath:bundleInPlacePath error:&error], @"Copying the bundle into the disabled bundles folder failed:%@", error);
	
	MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:bundleInPlacePath];
	
	STAssertNotNil(mailBundle, nil);
	STAssertEquals(mailBundle.status, kMBMStatusDisabled, nil);
	STAssertNotNil(mailBundle.bundle, nil);
	STAssertEqualObjects([mailBundle.bundle class], [NSBundle class], nil);
	STAssertNil(mailBundle.icon, nil);
	STAssertEqualObjects(mailBundle.name, @"ExamplePlugin", nil);
	STAssertEqualObjects(mailBundle.path, bundleInPlacePath, nil);
	STAssertEqualObjects(mailBundle.version, @"1", nil);
	
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:bundleInPlacePath error:&error], @"Removing bundle after test failed:%@", error);
}

- (void)test_023_Bundle_Copied_Into_Last_Disabled_Then_Enable {
	
	//	Use a UUID to create a unique filename
	NSString	*guid = [[NSProcessInfo processInfo] globallyUniqueString];
	NSString	*bundleInPlacePath = [[MBMMailBundle latestDisabledBundlesPath] stringByAppendingPathComponent:[guid stringByAppendingPathExtension:@"mailbundle"]];
	NSString	*newPath = [[MBMMailBundle bundlesPath] stringByAppendingPathComponent:[guid stringByAppendingPathExtension:@"mailbundle"]];
	
	NSError		*error;
	STAssertTrue([[NSFileManager defaultManager] copyItemAtPath:self.testBundlePath toPath:bundleInPlacePath error:&error], @"Copying the bundle into the disabled bundles folder failed:%@", error);
	
	MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:bundleInPlacePath];
	mailBundle.status = kMBMStatusEnabled;
	
	STAssertNotNil(mailBundle, nil);
	STAssertEquals(mailBundle.status, kMBMStatusEnabled, nil);
	STAssertNotNil(mailBundle.bundle, nil);
	STAssertEqualObjects([mailBundle.bundle class], [NSBundle class], nil);
	STAssertNil(mailBundle.icon, nil);
	STAssertEqualObjects(mailBundle.name, @"ExamplePlugin", nil);
	STAssertEqualObjects(mailBundle.path, newPath, nil);
	STAssertEqualObjects(mailBundle.version, @"1", nil);
	
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:newPath error:&error], @"Removing bundle after test failed:%@", error);
}

- (void)test_024_Bundle_Copied_Into_Active_Then_Disable_Create_New {
	
	//	Use a UUID to create a unique filename
	NSString	*guid = [[NSProcessInfo processInfo] globallyUniqueString];
	NSString	*bundleInPlacePath = [[MBMMailBundle bundlesPath] stringByAppendingPathComponent:[guid stringByAppendingPathExtension:@"mailbundle"]];
	
	//	Remove the disabled folders and ensure that we can continue
	[self removeDisabledBundleFoldersIfCreated];
	if ([MBMMailBundle latestDisabledBundlesPath] != nil) {
		STFail(@"This test will not work properly when there are existing 'Bundles (Disabled X)' folders");
		return;
	}
	
	NSError		*error;
	STAssertTrue([[NSFileManager defaultManager] copyItemAtPath:self.testBundlePath toPath:bundleInPlacePath error:&error], @"Copying the bundle into the enabled bundles folder failed:%@", error);
	
	MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:bundleInPlacePath];

	STAssertEquals(mailBundle.status, kMBMStatusEnabled, nil);
	mailBundle.status = kMBMStatusDisabled;
	STAssertEquals(mailBundle.status, kMBMStatusDisabled, nil);
	
	//	A new latestDisabled should have been created
	STAssertNotNil([MBMMailBundle latestDisabledBundlesPath], nil);
	NSString	*newPath = [[MBMMailBundle latestDisabledBundlesPath] stringByAppendingPathComponent:[guid stringByAppendingPathExtension:@"mailbundle"]];

	//	Test that the path is updated as well
	STAssertEqualObjects(mailBundle.path, newPath, nil);

	//	Clean up created paths and files
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:newPath error:&error], @"Removing bundle after test failed:%@", error);
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:[MBMMailBundle latestDisabledBundlesPath] error:&error], @"Removing folder after test failed:%@", error);
	STAssertNil([MBMMailBundle latestDisabledBundlesPath], nil);
}

- (void)test_025_Bundle_Copied_Into_Active_Then_Uninstalled {
	
	//	Use a UUID to create a unique filename
	NSString	*guid = [[NSProcessInfo processInfo] globallyUniqueString];
	NSString	*bundleInPlacePath = [[MBMMailBundle bundlesPath] stringByAppendingPathComponent:[guid stringByAppendingPathExtension:@"mailbundle"]];
	
	NSError		*error;
	STAssertTrue([[NSFileManager defaultManager] copyItemAtPath:self.testBundlePath toPath:bundleInPlacePath error:&error], @"Copying the bundle into the enabled bundles folder failed:%@", error);
	
	MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:bundleInPlacePath];
	
	STAssertEquals(mailBundle.status, kMBMStatusEnabled, nil);
	mailBundle.status = kMBMStatusUninstalled;
	STAssertEquals(mailBundle.status, kMBMStatusUninstalled, nil);
	
	//	New path should be in the trash
	NSString	*newPath = [[NSHomeDirectory() stringByAppendingPathComponent:@".Trash"] stringByAppendingPathComponent:[guid stringByAppendingPathExtension:@"mailbundle"]];
	
	//	Test that the paths are the same
	STAssertEqualObjects(mailBundle.path, newPath, nil);
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
