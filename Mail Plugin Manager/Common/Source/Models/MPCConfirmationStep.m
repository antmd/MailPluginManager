//
//  MPCConfirmationStep.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 23/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MPCConfirmationStep.h"

#define	kInformationTypeKey		@"information"
#define	kLicenseTypeKey			@"license"
#define kConfirmTypeKey			@"confirm"


@interface MPCConfirmationStep ()
@property	(nonatomic, assign, readwrite)	MPCConfirmationType	type;
@property	(nonatomic, copy, readwrite)	NSString			*bulletTitle;
@property	(nonatomic, copy, readwrite)	NSString			*title;
@property	(nonatomic, copy, readwrite)	NSString			*path;
@property	(nonatomic, assign, readwrite)	BOOL				requiresAgreement;
@property	(nonatomic, assign, readwrite)	BOOL				hasHTMLContent;
@property	(nonatomic, copy)				NSDictionary		*originalValues;
@end

@implementation MPCConfirmationStep


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
		NSString	*typeString = [aDictionary valueForKey:kMPCConfirmationTypeKey];
		if ([typeString isEqualToString:kLicenseTypeKey]) {
			_type = kMPCConfirmationTypeLicense;
		}
		else if ([typeString isEqualToString:kInformationTypeKey]) {
			_type = kMPCConfirmationTypeInformation;
		}
		else if ([typeString isEqualToString:kConfirmTypeKey]) {
			_type = kMPCConfirmationTypeConfirm;
		}
		
		//	Set the flag for is the content of this part html
		_hasHTMLContent = [[[aDictionary valueForKey:kMPCPathKey] pathExtension] isEqualToString:@"html"];
		
		//	Save the full path
		//	If it is html, ensure it has a full URL
		if (_hasHTMLContent) {
			//	Update the path to include the packageFilePath, and make it a full URL
			if (![[aDictionary valueForKey:kMPCPathKey] hasPrefix:@"http"]) {
				_path = [[NSString stringWithFormat:@"file://%@", [packageFilePath stringByAppendingPathComponent:[aDictionary valueForKey:kMPCPathKey]]] copy];
			}
		}
		//	Otherwise if there is a path just make it a full path
		else if ([aDictionary valueForKey:kMPCPathKey]) {
			_path = [[packageFilePath stringByAppendingPathComponent:[aDictionary valueForKey:kMPCPathKey]] copy];
		}
		
		//	Localized the two titles
		NSString	*localizedTitle = MPCLocalizedStringFromPackageFile([aDictionary valueForKey:kMPCConfirmationTitleKey], packageFilePath);
		_title = [localizedTitle copy];
		if ([aDictionary valueForKey:kMPCConfirmationBulletTitleKey]) {
			_bulletTitle = [MPCLocalizedStringFromPackageFile([aDictionary valueForKey:kMPCConfirmationBulletTitleKey], packageFilePath) copy];
		}
		else {
			_bulletTitle = [localizedTitle copy];
		}
		
		//	Agreement requirement
		_requiresAgreement = NO;
		if ([aDictionary valueForKey:kMPCConfirmationShouldAgreeToLicense]) {
			_requiresAgreement = [[aDictionary valueForKey:kMPCConfirmationShouldAgreeToLicense] boolValue];
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
	[result appendFormat:@"type:%d(%@)  ", self.type, (self.type == kMPCConfirmationTypeLicense?@"License":(self.type == kMPCConfirmationTypeInformation?@"Information":@"Confirm"))];
	[result appendFormat:@"title:%@  ", self.title];
	[result appendFormat:@"bulletTitle:%@\n", self.bulletTitle];
	[result appendFormat:@"requiresAgreement:%@  ", [NSString stringWithBool:self.requiresAgreement]];
	[result appendFormat:@"hasHTMLContent:%@  ", [NSString stringWithBool:self.hasHTMLContent]];
	[result appendFormat:@"agreementAccepted:%@\n)", [NSString stringWithBool:self.agreementAccepted]];
	
	return [NSString stringWithString:result];
}

@end
