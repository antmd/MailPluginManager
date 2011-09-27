//
//  InstallationModelTests.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 27/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "InstallationModelTests.h"
#import "MBMInstallationModel.h"
#import "MBMInstallationItem.h"
#import "MBMConfirmationStep.h"

@implementation InstallationModelTests

#pragma mark - Accessors

@synthesize userHomePath;
@synthesize	filePath;
@synthesize	fileContents;
@synthesize	installItemContents;
@synthesize	installItem1;
@synthesize	installItem2;
@synthesize	installItem3;
@synthesize	installItem4;
@synthesize	confirmStepContents;
@synthesize	confirmStep1;
@synthesize	confirmStep2;
@synthesize	confirmStep3;

#pragma mark - InstallationItem

- (void)test_001_Item_Complete {
	MBMInstallationItem	*anItem = [[[MBMInstallationItem alloc] initWithDictionary:self.installItem1 fromInstallationFilePath:@"/Short"] autorelease];
	NSArray				*permissionsList = [NSArray arrayWithObjects:@"user", @"system", nil];
	
	//	Test the item
	STAssertNotNil(anItem, nil);
	STAssertEqualObjects(anItem.name, @"Test File", nil);
	STAssertEqualObjects(anItem.path, @"/Short/Delivery/Test.txt", nil);
	STAssertEqualObjects(anItem.itemDescription, @"Complete Test", nil);
	STAssertEqualObjects(anItem.permissions, permissionsList, nil);
	STAssertEqualObjects(anItem.destinationPath, [self.userHomePath stringByAppendingPathComponent:@"Documents/Tests/Test.txt"], nil);
	STAssertFalse(anItem.isMailBundle, nil);
	STAssertFalse(anItem.isBundleManager, nil);
}

- (void)test_002_Item_Mail_Bundle_Complete {
	MBMInstallationItem	*anItem = [[[MBMInstallationItem alloc] initWithDictionary:self.installItem2 fromInstallationFilePath:@"/Short"] autorelease];
	NSArray				*permissionsList = [NSArray arrayWithObjects:@"user", nil];
	
	//	Test the item
	STAssertNotNil(anItem, nil);
	STAssertEqualObjects(anItem.name, @"Example Bundle", nil);
	STAssertEqualObjects(anItem.path, @"/Short/Delivery/Example.mailbundle", nil);
	STAssertEqualObjects(anItem.itemDescription, @"ExamplePlugin bundle for Mail", nil);
	STAssertEqualObjects(anItem.permissions, permissionsList, nil);
	STAssertEqualObjects(anItem.destinationPath, [self.userHomePath stringByAppendingPathComponent:@"Documents/Tests/Example.mailbundle"], nil);
	STAssertTrue(anItem.isMailBundle, nil);
	STAssertFalse(anItem.isBundleManager, nil);
}

- (void)test_003_Item_Bundle_Manager_Complete {
	MBMInstallationItem	*anItem = [[[MBMInstallationItem alloc] initWithDictionary:self.installItem3 fromInstallationFilePath:@"/Short"] autorelease];
	NSArray				*permissionsList = [NSArray arrayWithObjects:@"admin", nil];
	
	//	Test the item
	STAssertNotNil(anItem, nil);
	STAssertEqualObjects(anItem.name, @"Bundle Manager", nil);
	STAssertEqualObjects(anItem.path, @"/Short/Delivery/Bundle Manager.app", nil);
	STAssertEqualObjects(anItem.itemDescription, @"App for managing bundles for Mail", nil);
	STAssertEqualObjects(anItem.permissions, permissionsList, nil);
	STAssertEqualObjects(anItem.destinationPath, [self.userHomePath stringByAppendingPathComponent:@"Documents/Tests/Bundle Manager.app"], nil);
	STAssertFalse(anItem.isMailBundle, nil);
	STAssertTrue(anItem.isBundleManager, nil);
}

- (void)test_004_Item_Minimal_Item {
	MBMInstallationItem	*anItem = [[[MBMInstallationItem alloc] initWithDictionary:self.installItem4 fromInstallationFilePath:@"/Short"] autorelease];
	
	//	Test the item
	STAssertNotNil(anItem, nil);
	STAssertEqualObjects(anItem.name, @"Empty Item", nil);
	STAssertEqualObjects(anItem.path, @"/Short/Delivery/empty.txt", nil);
	STAssertNil(anItem.itemDescription, nil);
	STAssertNil(anItem.permissions, nil);
	STAssertEqualObjects(anItem.destinationPath, [self.userHomePath stringByAppendingPathComponent:@"Documents/Tests/empty.txt"], nil);
	STAssertFalse(anItem.isMailBundle, nil);
	STAssertFalse(anItem.isBundleManager, nil);
}


#pragma mark - Confirmation Steps

- (void)test_010_Step_Complete {
	MBMConfirmationStep	*aStep = [[[MBMConfirmationStep alloc] initWithDictionary:self.confirmStep1 andInstallationFilePath:@"/Short"] autorelease];
	
	//	Test the item
	STAssertNotNil(aStep, nil);
	STAssertEquals(aStep.type, kMBMConfirmationTypeReleaseNotes, nil);
	STAssertEqualObjects(aStep.bulletTitle, @"What's New", nil);
	STAssertEqualObjects(aStep.title, @"Release Notes", nil);
	STAssertEqualObjects(aStep.path, @"file:///Short/Something.html", nil);
	STAssertFalse(aStep.requiresAgreement, nil);
	STAssertTrue(aStep.hasHTMLContent, nil);
	STAssertFalse(aStep.agreementAccepted, nil);
}



#pragma mark - Admin

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
	self.userHomePath = NSHomeDirectory();//[NSSearchPathForDirectoriesInDomains(NSUserDirectory, NSUserDomainMask, YES) lastObject];
	self.filePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"installationModel" ofType:@"plist"];
	self.fileContents = [NSDictionary dictionaryWithContentsOfFile:self.filePath];
	self.installItemContents = [self.fileContents valueForKey:kMBMInstallItemsKey];
	for (NSUInteger i = 0; i < 4; i++) {
		if (i < [self.installItemContents count]) {
			[self setValue:[self.installItemContents objectAtIndex:i] forKey:[NSString stringWithFormat:@"installItem%d", i+1]];
		}
	}
	self.confirmStepContents = [self.fileContents valueForKey:kMBMConfirmationStepsKey];
	for (NSUInteger i = 0; i < 3; i++) {
		if (i < [self.confirmStepContents count]) {
			[self setValue:[self.confirmStepContents objectAtIndex:i] forKey:[NSString stringWithFormat:@"confirmStep%d", i+1]];
		}
	}
	
}

- (void)tearDown
{
    // Tear-down code here.
	self.userHomePath = nil;
	self.filePath = nil;
	self.fileContents = nil;
	self.installItemContents = nil;
	self.installItem1 = nil;
	self.installItem2 = nil;
	self.installItem3 = nil;
	self.installItem4 = nil;
	self.confirmStepContents = nil;
	self.confirmStep1 = nil;
	self.confirmStep2 = nil;
	self.confirmStep3 = nil;
    
    [super tearDown];
}

@end
