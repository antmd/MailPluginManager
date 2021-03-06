//
//  MPCActionItem.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 14/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPCActionItem : NSObject {
@private	
	NSString	*_name;
	NSString	*_itemDescription;
	NSArray		*_permissions;
	NSString	*_path;
	NSString	*_destinationPath;
	BOOL		_isMailBundle;
	BOOL		_isBundleManager;
	BOOL		_useLibraryDomain;
	BOOL		_shouldDeletePathIfExists;
	BOOL		_shouldHideItem;
	BOOL		_shouldReleaseFromQuarantine;
	BOOL		_shouldOnlyReleaseFromQuarantine;
	
	NSSearchPathDomainMask	_domainMask;
}

@property	(nonatomic, copy, readonly)		NSString	*name;
@property	(nonatomic, copy, readonly)		NSString	*itemDescription;
@property	(nonatomic, copy, readonly)		NSArray		*permissions;
@property	(nonatomic, copy, readonly)		NSString	*path;
@property	(nonatomic, copy, readonly)		NSString	*destinationPath;
@property	(nonatomic, assign, readonly)	BOOL		isMailBundle;
@property	(nonatomic, assign, readonly)	BOOL		isBundleManager;
@property	(nonatomic, assign, readonly)	BOOL		useLibraryDomain;
@property	(nonatomic, assign, readonly)	BOOL		shouldDeletePathIfExists;
@property	(nonatomic, assign, readonly)	BOOL		shouldHideItem;
@property	(nonatomic, assign, readonly)	BOOL		shouldReleaseFromQuarantine;
@property	(nonatomic, assign, readonly)	BOOL		shouldOnlyReleaseFromQuarantine;

@property	(nonatomic, assign)	NSSearchPathDomainMask	domainMask;

- (id)initWithDictionary:(NSDictionary *)itemDictionary fromPackageFilePath:(NSString *)packageFilePath manifestType:(MPCManifestType)type;

@end

