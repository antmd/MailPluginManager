//
//  ManifestModelTests.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 27/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "ManifestModelTests.h"
#import "MPCManifestModel.h"
#import "MPCActionItem.h"
#import "MPCConfirmationStep.h"

@implementation ManifestModelTests

#pragma mark - Accessors

@synthesize bundleContentsPath;
@synthesize userHomePath;
@synthesize	filePath;
@synthesize	fileContents;
@synthesize	actionItemContents;
@synthesize	actionItem1;
@synthesize	actionItem2;
@synthesize	actionItem3;
@synthesize	actionItem4;
@synthesize	confirmStepContents;
@synthesize	confirmStep1;
@synthesize	confirmStep2;
@synthesize	confirmStep3;
@synthesize	confirmStep4;

#pragma mark - InstallationItem

- (void)test_001_Item_Complete {
	MPCActionItem	*anItem = [[[MPCActionItem alloc] initWithDictionary:self.actionItem1 fromPackageFilePath:@"/Short" manifestType:kMPCManifestTypeInstallation] autorelease];
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
	MPCActionItem	*anItem = [[[MPCActionItem alloc] initWithDictionary:self.actionItem2 fromPackageFilePath:@"/Short" manifestType:kMPCManifestTypeInstallation] autorelease];
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
	MPCActionItem	*anItem = [[[MPCActionItem alloc] initWithDictionary:self.actionItem3 fromPackageFilePath:@"/Short" manifestType:kMPCManifestTypeInstallation] autorelease];
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
	MPCActionItem	*anItem = [[[MPCActionItem alloc] initWithDictionary:self.actionItem4 fromPackageFilePath:@"/Short" manifestType:kMPCManifestTypeInstallation] autorelease];
	
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

- (void)test_010_Step_Complete_Info {
	MPCConfirmationStep	*aStep = [[[MPCConfirmationStep alloc] initWithDictionary:self.confirmStep1 andPackageFilePath:@"/Short"] autorelease];
	
	//	Test the item
	STAssertNotNil(aStep, nil);
	STAssertEquals(aStep.type, kMPCConfirmationTypeInformation, nil);
	STAssertEqualObjects(aStep.bulletTitle, @"What's New", nil);
	STAssertEqualObjects(aStep.title, @"Release Notes", nil);
	STAssertEqualObjects(aStep.path, @"file:///Short/Something.html", nil);
	STAssertFalse(aStep.requiresAgreement, nil);
	STAssertTrue(aStep.hasHTMLContent, nil);
	STAssertFalse(aStep.agreementAccepted, nil);
}

- (void)test_011_Step_Complete_License {
	MPCConfirmationStep	*aStep = [[[MPCConfirmationStep alloc] initWithDictionary:self.confirmStep2 andPackageFilePath:@"/Short"] autorelease];
	aStep.agreementAccepted = YES;
	
	//	Test the item
	STAssertNotNil(aStep, nil);
	STAssertEquals(aStep.type, kMPCConfirmationTypeLicense, nil);
	STAssertEqualObjects(aStep.bulletTitle, @"License", nil);
	STAssertEqualObjects(aStep.title, @"License", nil);
	STAssertEqualObjects(aStep.path, @"/Short/MyLicense.rtf", nil);
	STAssertTrue(aStep.requiresAgreement, nil);
	STAssertFalse(aStep.hasHTMLContent, nil);
	STAssertTrue(aStep.agreementAccepted, nil);
}

- (void)test_012_Step_Complete_License_2 {
	MPCConfirmationStep	*aStep = [[[MPCConfirmationStep alloc] initWithDictionary:self.confirmStep3 andPackageFilePath:@"/Short"] autorelease];
	
	//	Test the item
	STAssertNotNil(aStep, nil);
	STAssertEquals(aStep.type, kMPCConfirmationTypeLicense, nil);
	STAssertEqualObjects(aStep.bulletTitle, @"License", nil);
	STAssertEqualObjects(aStep.title, @"User License", nil);
	STAssertEqualObjects(aStep.path, @"file:///Short/Second License.html", nil);
	STAssertFalse(aStep.requiresAgreement, nil);
	STAssertTrue(aStep.hasHTMLContent, nil);
	STAssertFalse(aStep.agreementAccepted, nil);
}

- (void)test_013_Step_Complete_Confirm {
	MPCConfirmationStep	*aStep = [[[MPCConfirmationStep alloc] initWithDictionary:self.confirmStep4 andPackageFilePath:@"/Short"] autorelease];
	
	//	Test the item
	STAssertNotNil(aStep, nil);
	STAssertEquals(aStep.type, kMPCConfirmationTypeConfirm, nil);
	STAssertEqualObjects(aStep.bulletTitle, @"Install", nil);
	STAssertEqualObjects(aStep.title, @"Install Summary", nil);
	STAssertNil(aStep.path, nil);
	STAssertFalse(aStep.requiresAgreement, nil);
	STAssertFalse(aStep.hasHTMLContent, nil);
	STAssertFalse(aStep.agreementAccepted, nil);
}


#pragma mark - Full Model

- (void)test_020_Model_Full {
	MPCManifestModel	*theModel = [[[MPCManifestModel alloc] initWithPackageAtPath:[self.filePath stringByDeletingLastPathComponent]] autorelease];

	//	Test the item
	STAssertNotNil(theModel, nil);
	STAssertEqualObjects(theModel.displayName, @"ExamplePlugin", nil);
	STAssertEqualObjects(theModel.backgroundImagePath, [self.bundleContentsPath stringByAppendingPathComponent:@"Resources/image.png"], nil);
	STAssertNotNil(theModel.bundleManager, nil);
	STAssertEqualsWithAccuracy(theModel.minOSVersion, 10.6, 0.01, nil);
	STAssertEqualsWithAccuracy(theModel.maxOSVersion, 10.7, 0.01, nil);
	STAssertEqualsWithAccuracy(theModel.minMailVersion, 4.2, 0.01, nil);
	STAssertTrue(theModel.shouldInstallManager, nil);
	STAssertEquals([theModel.confirmationStepList count], (NSUInteger)4, nil);
	STAssertEquals([theModel.actionItemList count], (NSUInteger)3, nil);
	STAssertEquals(theModel.totalActionItemCount, (NSUInteger)4, nil);
	STAssertEquals(theModel.confirmationStepCount, (NSUInteger)4, nil);
}



#pragma mark - Admin

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
	self.bundleContentsPath = [[[NSBundle bundleForClass:[self class]] bundlePath] stringByAppendingPathComponent:@"/Contents"];
	self.userHomePath = NSHomeDirectory();
	self.filePath = [[NSBundle bundleForClass:[self class]] pathForResource:kMPCManifestName ofType:kMPCPlistExtension];
	self.fileContents = [NSDictionary dictionaryWithContentsOfFile:self.filePath];
	self.actionItemContents = [self.fileContents valueForKey:kMPCActionItemsKey];
	for (NSUInteger i = 0; i < 4; i++) {
		if (i < [self.actionItemContents count]) {
			[self setValue:[self.actionItemContents objectAtIndex:i] forKey:[NSString stringWithFormat:@"actionItem%d", i+1]];
		}
	}
	self.confirmStepContents = [self.fileContents valueForKey:kMPCConfirmationStepsKey];
	for (NSUInteger i = 0; i < 4; i++) {
		if (i < [self.confirmStepContents count]) {
			[self setValue:[self.confirmStepContents objectAtIndex:i] forKey:[NSString stringWithFormat:@"confirmStep%d", i+1]];
		}
	}
	
}

- (void)tearDown
{
    // Tear-down code here.
	self.bundleContentsPath = nil;
	self.userHomePath = nil;
	self.filePath = nil;
	self.fileContents = nil;
	self.actionItemContents = nil;
	self.actionItem1 = nil;
	self.actionItem2 = nil;
	self.actionItem3 = nil;
	self.actionItem4 = nil;
	self.confirmStepContents = nil;
	self.confirmStep1 = nil;
	self.confirmStep2 = nil;
	self.confirmStep3 = nil;
	self.confirmStep4 = nil;
    
    [super tearDown];
}

@end
