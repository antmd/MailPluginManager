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

#pragma mark User Paths

- (void)test_001_Mail_Mail_Path {
	NSString	*result = [@"~/Library/Mail" stringByExpandingTildeInPath];
	
	STAssertEqualObjects([MBMMailBundle mailFolderPath], result, nil);
}

- (void)test_002_Mail_Bundle_Path {
	NSString	*result = [@"~/Library/Mail/Bundles" stringByExpandingTildeInPath];
	
	STAssertEqualObjects([MBMMailBundle bundlesPathShouldCreate:NO], result, nil);
}

- (void)test_003_Mail_Latest_Disabled_Bundle_Path {
	NSString	*result = [@"~/Library/Mail/Bundles (Disabled 101)" stringByExpandingTildeInPath];
	
	STAssertEqualObjects([MBMMailBundle latestDisabledBundlesPathShouldCreate:NO], result, nil);
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
	if ([MBMMailBundle latestDisabledBundlesPathShouldCreate:NO] != nil) {
		STFail(@"This test will not work properly when there are existing 'Bundles (Disabled X)' folders");
		return;
	}

	//	Try to get the latestDisabled with creation
	NSError		*error;
	NSString	*disabledPath = [MBMMailBundle latestDisabledBundlesPathShouldCreate:YES];
	STAssertNotNil(disabledPath, nil);
	STAssertTrue([[disabledPath lastPathComponent] isEqualToString:[MBMMailBundle disabledBundleFolderName]], nil);
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:disabledPath error:&error], @"Removing folder after test failed:%@", error);
	STAssertNil([MBMMailBundle latestDisabledBundlesPathShouldCreate:NO], nil);
}

- (void)test_006_Mail_Latest_Disabled_Folder_Is_Numbered {

	//	Remove the disabled folders and ensure that we can continue
	[self removeDisabledBundleFoldersIfCreated];
	if ([MBMMailBundle latestDisabledBundlesPathShouldCreate:NO] != nil) {
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
	STAssertEqualObjects([[MBMMailBundle latestDisabledBundlesPathShouldCreate:NO] lastPathComponent], @"Bundles (Disabled 1)", nil);
	
	//	Clean up
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:disabledPath error:&error], @"Removing 1st folder after test failed:%@", error);
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:secondPath error:&error], @"Removing 2nd folder after test failed:%@", error);
	STAssertNil([MBMMailBundle latestDisabledBundlesPathShouldCreate:NO], nil);
}

#pragma mark Local Paths

- (void)test_010_Mail_Local_Mail_Path {
	NSString	*result = @"/Library/Mail";
	
	STAssertEqualObjects([MBMMailBundle mailFolderPathLocal], result, nil);
}

- (void)test_011_Mail_Local_Bundle_Path {
	NSString	*result = @"/Library/Mail/Bundles";
	
	STAssertEqualObjects([MBMMailBundle bundlesPathLocalShouldCreate:NO], result, nil);
}

/*
- (void)test_012_Mail_Local_Latest_Disabled_Bundle_Path {
	NSString	*result = @"/Library/Mail/Bundles (Disabled 101)";
	
	STAssertEqualObjects([MBMMailBundle latestDisabledBundlesPathLocalShouldCreate:NO], result, nil);
}

- (void)test_013_Mail_Local_All_Disabled_Bundle_Paths {
	NSString	*disabledKnown1 = @"/Library/Mail/Bundles (Disabled 100)";
	NSString	*disabledKnown2 = @"/Library/Mail/Bundles (Disabled 101)";
	NSArray *pathList = [MBMMailBundle disabledBundlesPathLocalList];
	
	STAssertTrue([pathList count] >= 2, nil);
	if ([pathList count] >= 2) {
		STAssertEqualObjects([pathList lastObject], disabledKnown2, nil);
		STAssertEqualObjects([pathList objectAtIndex:([pathList count] - 2)], disabledKnown1, nil);
	}
}

- (void)test_014_Mail_Local_Latest_Disabled_Bundle_Path_With_Creation {
	
	//	Remove the disabled folders and ensure that we can continue
	[self removeDisabledBundleFoldersIfCreated];
	if ([MBMMailBundle latestDisabledBundlesPathLocalShouldCreate:NO] != nil) {
		STFail(@"This test will not work properly when there are existing 'Bundles (Disabled X)' folders");
		return;
	}
	
	//	Try to get the latestDisabled with creation
	NSError		*error;
	NSString	*disabledPath = [MBMMailBundle latestDisabledBundlesPathLocalShouldCreate:YES];
	STAssertNotNil(disabledPath, nil);
	STAssertTrue([[disabledPath lastPathComponent] isEqualToString:[MBMMailBundle disabledBundleFolderName]], nil);
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:disabledPath error:&error], @"Removing folder after test failed:%@", error);
	STAssertNil([MBMMailBundle latestDisabledBundlesPathLocalShouldCreate:NO], nil);
}
*/


#pragma mark - Comparision Tests

- (void)test_020_Compare {
	NSString	*firstVersion = @"3.2";
	NSString	*secondVersion = @"2.9";
	
	STAssertEquals([MBMMailBundle compareVersion:firstVersion toVersion:secondVersion], (NSInteger)NSOrderedDescending, nil);
	STAssertEquals([MBMMailBundle compareVersion:secondVersion toVersion:firstVersion], (NSInteger)NSOrderedAscending, nil);
	STAssertEquals([MBMMailBundle compareVersion:firstVersion toVersion:firstVersion], (NSInteger)NSOrderedSame, nil);
	STAssertEquals([MBMMailBundle compareVersion:secondVersion toVersion:secondVersion], (NSInteger)NSOrderedSame, nil);
}

- (void)test_021_Location_Test_Active_Positive {
	//	Use a UUID to create a unique filename
	NSString	*bundleInPlacePath = [[MBMMailBundle bundlesPathShouldCreate:NO] stringByAppendingPathComponent:[[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension:kMBMMailBundleExtension]];
	
	NSError		*error;
	STAssertTrue([[NSFileManager defaultManager] copyItemAtPath:self.testBundlePath toPath:bundleInPlacePath error:&error], @"Copying the bundle into the active bundles folder failed:%@", error);
	
	MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:bundleInPlacePath];

	STAssertTrue([mailBundle isInActiveBundlesFolder], nil);
	
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:bundleInPlacePath error:&error], @"Removing bundle after test failed:%@", error);
}

- (void)test_022_Location_Test_Active_Negative {
	//	Use a UUID to create a unique filename
	NSString	*bundleInPlacePath = [[MBMMailBundle latestDisabledBundlesPathShouldCreate:NO] stringByAppendingPathComponent:[[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension:kMBMMailBundleExtension]];
	
	NSError		*error;
	STAssertTrue([[NSFileManager defaultManager] copyItemAtPath:self.testBundlePath toPath:bundleInPlacePath error:&error], @"Copying the bundle into the disabled bundles folder failed:%@", error);
	
	MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:bundleInPlacePath];
	
	STAssertFalse([mailBundle isInActiveBundlesFolder], nil);
	
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:bundleInPlacePath error:&error], @"Removing bundle after test failed:%@", error);
}

- (void)test_023_Location_Test_Disabled_Positive {
	//	Use a UUID to create a unique filename
	NSString	*bundleInPlacePath = [[MBMMailBundle latestDisabledBundlesPathShouldCreate:NO] stringByAppendingPathComponent:[[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension:kMBMMailBundleExtension]];
	
	NSError		*error;
	STAssertTrue([[NSFileManager defaultManager] copyItemAtPath:self.testBundlePath toPath:bundleInPlacePath error:&error], @"Copying the bundle into the disabled bundles folder failed:%@", error);
	
	MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:bundleInPlacePath];
	
	STAssertTrue([mailBundle isInDisabledBundlesFolder], nil);
	
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:bundleInPlacePath error:&error], @"Removing bundle after test failed:%@", error);
}

- (void)test_024_Location_Test_Disabled_Negative {
	//	Use a UUID to create a unique filename
	NSString	*bundleInPlacePath = [[MBMMailBundle bundlesPathShouldCreate:NO] stringByAppendingPathComponent:[[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension:kMBMMailBundleExtension]];
	
	NSError		*error;
	STAssertTrue([[NSFileManager defaultManager] copyItemAtPath:self.testBundlePath toPath:bundleInPlacePath error:&error], @"Copying the bundle into the active bundles folder failed:%@", error);
	
	MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:bundleInPlacePath];
	
	STAssertFalse([mailBundle isInDisabledBundlesFolder], nil);
	
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:bundleInPlacePath error:&error], @"Removing bundle after test failed:%@", error);
}

#pragma mark - Getting Bundles

- (void)test_040_Bundle_From_Path {
	MBMMailBundle	*bundle = [MBMMailBundle mailBundleForPath:self.testBundlePath];
	
	STAssertNotNil(bundle, nil);
	STAssertFalse(bundle.installed, nil);
	STAssertFalse(bundle.enabled, nil);
	STAssertFalse(bundle.inLocalDomain, nil);
	STAssertNotNil(bundle.bundle, nil);
	STAssertEqualObjects([bundle.bundle class], [NSBundle class], nil);
	STAssertNotNil(bundle.icon, nil);
	STAssertEqualObjects(bundle.name, @"ExamplePlugin", nil);
	STAssertEqualObjects(bundle.path, self.testBundlePath, nil);
	STAssertEqualObjects(bundle.version, @"1", nil);
	STAssertEqualObjects(bundle.company, @"Little Known", nil);
	STAssertEqualObjects(bundle.companyURL, @"http://www.littleknownsoftware.com", nil);
	STAssertFalse(bundle.compatibleWithCurrentMail, nil);
}

- (void)test_041_Bundle_Copied_Into_Active {

	//	Use a UUID to create a unique filename
	NSString	*bundleInPlacePath = [[MBMMailBundle bundlesPathShouldCreate:YES] stringByAppendingPathComponent:[[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension:kMBMMailBundleExtension]];
	
	NSError		*error;
	STAssertTrue([[NSFileManager defaultManager] copyItemAtPath:self.testBundlePath toPath:bundleInPlacePath error:&error], @"Copying the bundle into the bundles folder failed:%@", error);

	MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:bundleInPlacePath];
	
	STAssertNotNil(mailBundle, nil);
	STAssertTrue(mailBundle.installed, nil);
	STAssertTrue(mailBundle.enabled, nil);
	STAssertFalse(mailBundle.inLocalDomain, nil);
	STAssertNotNil(mailBundle.bundle, nil);
	STAssertEqualObjects([mailBundle.bundle class], [NSBundle class], nil);
	STAssertEqualObjects(mailBundle.path, bundleInPlacePath, nil);
	
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:bundleInPlacePath error:&error], @"Removing bundle after test failed:%@", error);
}

- (void)test_042_Bundle_Copied_Into_Last_Disabled {
	
	//	Use a UUID to create a unique filename
	NSString	*bundleInPlacePath = [[MBMMailBundle latestDisabledBundlesPathShouldCreate:YES] stringByAppendingPathComponent:[[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension:kMBMMailBundleExtension]];
	
	NSError		*error;
	STAssertTrue([[NSFileManager defaultManager] copyItemAtPath:self.testBundlePath toPath:bundleInPlacePath error:&error], @"Copying the bundle into the disabled bundles folder failed:%@", error);
	
	MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:bundleInPlacePath];
	
	STAssertNotNil(mailBundle, nil);
	STAssertTrue(mailBundle.installed, nil);
	STAssertFalse(mailBundle.enabled, nil);
	STAssertFalse(mailBundle.inLocalDomain, nil);
	STAssertNotNil(mailBundle.bundle, nil);
	STAssertEqualObjects([mailBundle.bundle class], [NSBundle class], nil);
	STAssertEqualObjects(mailBundle.path, bundleInPlacePath, nil);
	
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:bundleInPlacePath error:&error], @"Removing bundle after test failed:%@", error);
}

- (void)test_043_Bundle_Copied_Into_Last_Disabled_Then_Enable {
	
	//	Use a UUID to create a unique filename
	NSString	*guid = [[NSProcessInfo processInfo] globallyUniqueString];
	NSString	*bundleInPlacePath = [[MBMMailBundle latestDisabledBundlesPathShouldCreate:YES] stringByAppendingPathComponent:[guid stringByAppendingPathExtension:kMBMMailBundleExtension]];
	NSString	*newPath = [[MBMMailBundle bundlesPathShouldCreate:YES] stringByAppendingPathComponent:[guid stringByAppendingPathExtension:kMBMMailBundleExtension]];
	
	NSError		*error;
	STAssertTrue([[NSFileManager defaultManager] copyItemAtPath:self.testBundlePath toPath:bundleInPlacePath error:&error], @"Copying the bundle into the disabled bundles folder failed:%@", error);
	
	MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:bundleInPlacePath];
	STAssertTrue(mailBundle.installed, nil);
	STAssertFalse(mailBundle.enabled, nil);
	mailBundle.enabled = YES;
	
	STAssertNotNil(mailBundle, nil);
	STAssertTrue(mailBundle.installed, nil);
	STAssertTrue(mailBundle.enabled, nil);
	STAssertFalse(mailBundle.inLocalDomain, nil);
	STAssertNotNil(mailBundle.bundle, nil);
	STAssertEqualObjects([mailBundle.bundle class], [NSBundle class], nil);
	STAssertEqualObjects(mailBundle.path, newPath, nil);
	
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:newPath error:&error], @"Removing bundle after test failed:%@", error);
}

- (void)test_044_Bundle_Copied_Into_Active_Then_Disable_Create_New {
	
	//	Use a UUID to create a unique filename
	NSString	*guid = [[NSProcessInfo processInfo] globallyUniqueString];
	NSString	*bundleInPlacePath = [[MBMMailBundle bundlesPathShouldCreate:YES] stringByAppendingPathComponent:[guid stringByAppendingPathExtension:kMBMMailBundleExtension]];
	
	//	Remove the disabled folders and ensure that we can continue
	[self removeDisabledBundleFoldersIfCreated];
	if ([MBMMailBundle latestDisabledBundlesPathShouldCreate:NO] != nil) {
		STFail(@"This test will not work properly when there are existing 'Bundles (Disabled X)' folders");
		return;
	}
	
	NSError		*error;
	STAssertTrue([[NSFileManager defaultManager] copyItemAtPath:self.testBundlePath toPath:bundleInPlacePath error:&error], @"Copying the bundle into the enabled bundles folder failed:%@", error);
	
	MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:bundleInPlacePath];

	STAssertTrue(mailBundle.installed, nil);
	STAssertTrue(mailBundle.enabled, nil);
	STAssertFalse(mailBundle.inLocalDomain, nil);
	mailBundle.enabled = NO;
	STAssertTrue(mailBundle.installed, nil);
	STAssertFalse(mailBundle.enabled, nil);
	STAssertFalse(mailBundle.inLocalDomain, nil);
	
	//	A new latestDisabled should have been created
	STAssertNotNil([MBMMailBundle latestDisabledBundlesPathShouldCreate:NO], nil);
	NSString	*newPath = [[MBMMailBundle latestDisabledBundlesPathShouldCreate:NO] stringByAppendingPathComponent:[guid stringByAppendingPathExtension:kMBMMailBundleExtension]];

	//	Test that the path is updated as well
	STAssertEqualObjects(mailBundle.path, newPath, nil);

	//	Clean up created paths and files
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:newPath error:&error], @"Removing bundle after test failed:%@", error);
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:[MBMMailBundle latestDisabledBundlesPathShouldCreate:NO] error:&error], @"Removing folder after test failed:%@", error);
	STAssertNil([MBMMailBundle latestDisabledBundlesPathShouldCreate:NO], nil);
}

- (void)test_045_Bundle_Copied_Into_Active_Then_Uninstalled {
	
	//	Use a UUID to create a unique filename
	NSString	*guid = [[NSProcessInfo processInfo] globallyUniqueString];
	NSString	*bundleInPlacePath = [[MBMMailBundle bundlesPathShouldCreate:YES] stringByAppendingPathComponent:[guid stringByAppendingPathExtension:kMBMMailBundleExtension]];
	
	NSError		*error;
	STAssertTrue([[NSFileManager defaultManager] copyItemAtPath:self.testBundlePath toPath:bundleInPlacePath error:&error], @"Copying the bundle into the enabled bundles folder failed:%@", error);
	
	MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:bundleInPlacePath];
	
	STAssertTrue(mailBundle.installed, nil);
	STAssertTrue(mailBundle.enabled, nil);
	STAssertFalse(mailBundle.inLocalDomain, nil);
	mailBundle.installed = NO;
	STAssertFalse(mailBundle.installed, nil);
	STAssertFalse(mailBundle.enabled, nil);
	STAssertFalse(mailBundle.inLocalDomain, nil);
	
	//	New path should be in the trash
	NSString	*newPath = [[NSHomeDirectory() stringByAppendingPathComponent:@".Trash"] stringByAppendingPathComponent:[guid stringByAppendingPathExtension:kMBMMailBundleExtension]];
	
	//	Test that the paths are the same
	STAssertEqualObjects(mailBundle.path, newPath, nil);
}

- (void)test_046_Mail_Bundle_Loaded_Then_Copied_From_Uninstalled_To_Active {
	
	//	Use a UUID to create a unique filename
	NSString	*guid = [[NSProcessInfo processInfo] globallyUniqueString];
	NSString	*bundleInPlacePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[guid stringByAppendingPathExtension:kMBMMailBundleExtension]];
	
	NSError		*error;
	STAssertTrue([[NSFileManager defaultManager] copyItemAtPath:self.testBundlePath toPath:bundleInPlacePath error:&error], @"Copying the bundle into the temporary folder failed:%@", error);
	
	MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:bundleInPlacePath];
	
	STAssertFalse(mailBundle.installed, nil);
	STAssertFalse(mailBundle.enabled, nil);
	STAssertFalse(mailBundle.inLocalDomain, nil);
	mailBundle.enabled = YES;
	STAssertTrue(mailBundle.installed, nil);
	STAssertTrue(mailBundle.enabled, nil);
	STAssertFalse(mailBundle.inLocalDomain, nil);
	
	//	New path should be in the trash
	NSString	*newPath = [[MBMMailBundle bundlesPathShouldCreate:NO] stringByAppendingPathComponent:[guid stringByAppendingPathExtension:kMBMMailBundleExtension]];
	
	//	Test that the paths are the same
	STAssertEqualObjects(mailBundle.path, newPath, nil);

	//	Clean up created paths and files
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:newPath error:&error], @"Removing bundle after test failed:%@", error);
}

/*
- (void)test_047_Bundle_Copied_Into_Active_Local_Domain {
	
	//	Use a UUID to create a unique filename
	NSString	*bundleInPlacePath = [[MBMMailBundle bundlesPathLocalShouldCreate:YES] stringByAppendingPathComponent:[[[NSProcessInfo processInfo] globallyUniqueString] stringByAppendingPathExtension:kMBMMailBundleExtension]];
	
	NSError		*error;
	STAssertTrue([[NSFileManager defaultManager] copyItemAtPath:self.testBundlePath toPath:bundleInPlacePath error:&error], @"Copying the bundle into the bundles folder failed:%@", error);
	
	MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:bundleInPlacePath];
	
	STAssertNotNil(mailBundle, nil);
	STAssertTrue(mailBundle.installed, nil);
	STAssertTrue(mailBundle.enabled, nil);
	STAssertTrue(mailBundle.inLocalDomain, nil);
	STAssertNotNil(mailBundle.bundle, nil);
	STAssertEqualObjects([mailBundle.bundle class], [NSBundle class], nil);
	STAssertEqualObjects(mailBundle.path, bundleInPlacePath, nil);
	
	STAssertTrue([[NSFileManager defaultManager] removeItemAtPath:bundleInPlacePath error:&error], @"Removing bundle after test failed:%@", error);
}

- (void)test_048_Bundle_Copied_Into_Active_Local_Domain_Then_Uninstalled {
	
	//	Use a UUID to create a unique filename
	NSString	*guid = [[NSProcessInfo processInfo] globallyUniqueString];
	NSString	*bundleInPlacePath = [[MBMMailBundle bundlesPathLocalShouldCreate:YES] stringByAppendingPathComponent:[guid stringByAppendingPathExtension:kMBMMailBundleExtension]];
	
	NSError		*error;
	STAssertTrue([[NSFileManager defaultManager] copyItemAtPath:self.testBundlePath toPath:bundleInPlacePath error:&error], @"Copying the bundle into the bundles folder failed:%@", error);
	
	MBMMailBundle	*mailBundle = [MBMMailBundle mailBundleForPath:bundleInPlacePath];
	
	STAssertNotNil(mailBundle, nil);
	STAssertTrue(mailBundle.installed, nil);
	STAssertTrue(mailBundle.enabled, nil);
	STAssertTrue(mailBundle.inLocalDomain, nil);
	mailBundle.installed = NO;
	STAssertFalse(mailBundle.installed, nil);
	STAssertFalse(mailBundle.enabled, nil);
	STAssertFalse(mailBundle.inLocalDomain, nil);
	
	//	New path should be in the trash
	NSString	*newPath = [[NSHomeDirectory() stringByAppendingPathComponent:@".Trash"] stringByAppendingPathComponent:[guid stringByAppendingPathExtension:kMBMMailBundleExtension]];
	
	//	Test that the paths are the same
	STAssertEqualObjects(mailBundle.path, newPath, nil);
}
*/


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
