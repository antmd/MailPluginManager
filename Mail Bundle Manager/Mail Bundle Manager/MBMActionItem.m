//
//  MBMActionItem.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 14/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "MBMActionItem.h"
#import "MBMMailBundle.h"


@interface MBMActionItem ()
@property	(nonatomic, copy, readwrite)		NSString	*name;
@property	(nonatomic, copy, readwrite)		NSString	*itemDescription;
@property	(nonatomic, copy, readwrite)		NSArray		*permissions;
@property	(nonatomic, copy, readwrite)		NSString	*path;
@property	(nonatomic, copy, readwrite)		NSString	*destinationPath;
@end

@implementation MBMActionItem

@synthesize name = _name;
@synthesize itemDescription = _itemDescription;
@synthesize permissions = _permissions;
@synthesize path = _path;
@synthesize destinationPath = _destinationPath;
@synthesize isMailBundle = _isMailBundle;
@synthesize isBundleManager = _isBundleManager;


#pragma mark - Memory Management

- (id)initWithDictionary:(NSDictionary *)itemDictionary fromPackageFilePath:(NSString *)packageFilePath manifestType:(MBMManifestType)type {

	self = [super init];
    if (self) {
        // Initialization code here.
		_name = [[itemDictionary valueForKey:kMBMNameKey] copy];
		
		//	Get the path, ensuring to take into account the manifestType
		NSString	*tempPath = [itemDictionary valueForKey:kMBMPathKey];
		if (type == kMBMManifestTypeInstallation) {
			tempPath = [packageFilePath stringByAppendingPathComponent:tempPath];
		}
		else {
			//	if the is only one component and it ends with mailbundle, build full path to bundles folder
			if (([[tempPath pathComponents] count] == 1) && [[tempPath pathExtension] isEqualToString:kMBMMailBundleExtension]) {
				tempPath = [[MBMMailBundle bundlesPath] stringByAppendingPathComponent:tempPath];
			}
			else {
				//	Expand any tildas
				tempPath = [tempPath stringByExpandingTildeInPath];
			}
		}
		_path = [tempPath copy];
		
		//	Ensure that the destination path includes the filename if one wasn't attached
		tempPath = [[itemDictionary valueForKey:kMBMDestinationPathKey] stringByExpandingTildeInPath];
		//	But only if it doesn't already have an extension (it case the file is being given a different name)
		if (IsEmpty([tempPath pathExtension])) {
			NSString	*fileName = [_path lastPathComponent];
			if (![tempPath hasSuffix:fileName]) {
				tempPath = [tempPath stringByAppendingPathComponent:fileName];
			}
		}
		_destinationPath = [tempPath copy];
		
		//	Description is optional
		if ([itemDictionary valueForKey:kMBMDescriptionKey]) {
			_itemDescription = [[itemDictionary valueForKey:kMBMDescriptionKey] copy];
		}
		
		//	If there are permissions specific to this action, see what they will be
		if ([itemDictionary valueForKey:kMBMPermissionsKey]) {
			_permissions = [[itemDictionary valueForKey:kMBMPermissionsKey] copy];
		}
		
		//	Check to see if this is a mail bundle
		_isMailBundle = [[_path pathExtension] isEqualToString:kMBMMailBundleExtension];
		
		//	If there is a bundle manager key, set it otherwise set as NO
		_isBundleManager = ([itemDictionary valueForKey:kMBMIsBundleManagerKey] != nil)?[[itemDictionary valueForKey:kMBMIsBundleManagerKey] boolValue]:NO;
	}
    
    return self;
}

- (void)dealloc {
	self.name = nil;
	self.itemDescription = nil;
	self.permissions = nil;
	self.path = nil;
	self.destinationPath = nil;
	
	[super dealloc];
}


- (NSString *)description {
	NSMutableString	*result = [NSMutableString string];
	
	[result appendFormat:@">>%@ [%p] (", [self className], self];
	[result appendFormat:@"name:%@  ", self.name];
	[result appendFormat:@"itemDescription:%@  ", self.itemDescription];
	[result appendFormat:@"isMailBundle:%@  ", [NSString stringWithBool:self.isMailBundle]];
	[result appendFormat:@"isBundleManager:%@)\n", [NSString stringWithBool:self.isBundleManager]];
	[result appendFormat:@"\tpath:%@\n", self.path];
	[result appendFormat:@"\tdestinatinPath:%@\n", self.destinationPath];
	[result appendFormat:@"\tpermissions:(%@)\n", self.permissions];
	
	return [NSString stringWithString:result];
}

@end
