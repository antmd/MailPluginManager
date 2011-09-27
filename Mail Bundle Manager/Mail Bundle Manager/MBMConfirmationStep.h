//
//  MBMConfirmationStep.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 23/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBMConfirmationStep : NSObject
@property	(nonatomic, assign, readonly)	MBMConfirmationType	type;
@property	(nonatomic, copy, readonly)		NSString			*bulletTitle;
@property	(nonatomic, copy, readonly)		NSString			*title;
@property	(nonatomic, copy, readonly)		NSString			*path;
@property	(nonatomic, assign, readonly)	BOOL				requiresAgreement;
@property	(nonatomic, assign, readonly)	BOOL				hasHTMLContent;
@property	(nonatomic, assign)				BOOL				agreementAccepted;

- (id)initWithDictionary:(NSDictionary *)aDictionary andInstallationFilePath:(NSString *)installFilePath;
@end