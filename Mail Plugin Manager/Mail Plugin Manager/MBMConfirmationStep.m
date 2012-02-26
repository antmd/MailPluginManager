//
//  MBMConfirmationStep.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 23/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBMConfirmationStep.h"

#define	kInformationTypeKey		@"information"
#define	kLicenseTypeKey			@"license"
#define kConfirmTypeKey			@"confirm"


@interface MBMConfirmationStep ()
@property	(nonatomic, assign, readwrite)	MBMConfirmationType	type;
@property	(nonatomic, copy, readwrite)	NSString			*bulletTitle;
@property	(nonatomic, copy, readwrite)	NSString			*title;
@property	(nonatomic, copy, readwrite)	NSString			*path;
@property	(nonatomic, assign, readwrite)	BOOL				requiresAgreement;
@property	(nonatomic, assign, readwrite)	BOOL				hasHTMLContent;
@property	(nonatomic, copy)				NSDictionary		*originalValues;
@end

@implementation MBMConfirmationStep


#pragma mark - Accessors

@synthesize type = _type;
@synthesize bulletTitle = _bulletTitle;
@synthesize title = _title;
@synthesize path = _path;
@synthesize requiresAgreement = _requiresAgreement;
@synthesize hasHTMLContent = _hasHTMLContent;
@synthesize agreementAccepted = _agreementAccepted;
@synthesize originalValues = _originalValues;


#pragma mark - Memory Management

- (id)initWithDictionary:(NSDictionary *)aDictionary andPackageFilePath:(NSString *)packageFilePath {
    self = [super init];
    if (self) {
        // Initialization code here.
		_originalValues = [aDictionary copy];
		
		//	Set the type
		NSString	*typeString = [aDictionary valueForKey:kMBMConfirmationTypeKey];
		if ([typeString isEqualToString:kLicenseTypeKey]) {
			_type = kMBMConfirmationTypeLicense;
		}
		else if ([typeString isEqualToString:kInformationTypeKey]) {
			_type = kMBMConfirmationTypeInformation;
		}
		else if ([typeString isEqualToString:kConfirmTypeKey]) {
			_type = kMBMConfirmationTypeConfirm;
		}
		
		//	Set the flag for is the content of this part html
		_hasHTMLContent = [[[aDictionary valueForKey:kMBMPathKey] pathExtension] isEqualToString:@"html"];
		
		//	Save the full path
		//	If it is html, ensure it has a full URL
		if (_hasHTMLContent) {
			//	Update the path to include the packageFilePath, and make it a full URL
			if (![[aDictionary valueForKey:kMBMPathKey] hasPrefix:@"http"]) {
				_path = [[NSString stringWithFormat:@"file://%@", [packageFilePath stringByAppendingPathComponent:[aDictionary valueForKey:kMBMPathKey]]] copy];
			}
		}
		//	Otherwise if there is a path just make it a full path
		else if ([aDictionary valueForKey:kMBMPathKey]) {
			_path = [[packageFilePath stringByAppendingPathComponent:[aDictionary valueForKey:kMBMPathKey]] copy];
		}
		
		//	Localized the two titles
		NSString	*localizedTitle = MBMLocalizedStringFromPackageFile([aDictionary valueForKey:kMBMConfirmationTitleKey], packageFilePath);
		_title = [localizedTitle copy];
		if ([aDictionary valueForKey:kMBMConfirmationBulletTitleKey]) {
			_bulletTitle = [MBMLocalizedStringFromPackageFile([aDictionary valueForKey:kMBMConfirmationBulletTitleKey], packageFilePath) copy];
		}
		else {
			_bulletTitle = [localizedTitle copy];
		}
		
		//	Agreement requirement
		_requiresAgreement = NO;
		if ([aDictionary valueForKey:kMBMConfirmationShouldAgreeToLicense]) {
			_requiresAgreement = [[aDictionary valueForKey:kMBMConfirmationShouldAgreeToLicense] boolValue];
		}

		
    }
    
    return self;
}

- (void)dealloc {
	self.bulletTitle = nil;
	self.title = nil;
	self.path = nil;
	self.originalValues = nil;

	[super dealloc];
}


- (NSString *)description {
	NSMutableString	*result = [NSMutableString string];
	
	[result appendFormat:@">>%@ [%p] (", [self className], self];
	[result appendFormat:@"type:%d(%@)  ", self.type, (self.type == kMBMConfirmationTypeLicense?@"License":(self.type == kMBMConfirmationTypeInformation?@"Information":@"Confirm"))];
	[result appendFormat:@"title:%@  ", self.title];
	[result appendFormat:@"bulletTitle:%@\n", self.bulletTitle];
	[result appendFormat:@"requiresAgreement:%@  ", [NSString stringWithBool:self.requiresAgreement]];
	[result appendFormat:@"hasHTMLContent:%@  ", [NSString stringWithBool:self.hasHTMLContent]];
	[result appendFormat:@"agreementAccepted:%@\n)", [NSString stringWithBool:self.agreementAccepted]];
	
	return [NSString stringWithString:result];
}

@end
