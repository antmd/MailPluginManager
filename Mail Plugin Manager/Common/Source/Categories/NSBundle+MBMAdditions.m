//
//  NSBundle+MBMAdditions.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "NSBundle+MBMAdditions.h"

#import "MBMMailBundle.h"

@implementation NSBundle (NSBundle_MBMAdditions)

- (NSString *)versionString {
	return [[self infoDictionary] valueForKey:(NSString *)kCFBundleVersionKey];
}

- (BOOL)hasLaterVersionNumberThanBundle:(NSBundle *)otherBundle {

	if (otherBundle == nil) {
		return YES;
	}
	
	return ([MBMMailBundle compareVersion:[self versionString] toVersion:[otherBundle versionString]] == NSOrderedDescending);
	
}

@end
