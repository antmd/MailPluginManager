//
//  NSBundle+MPCAdditions.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import "NSBundle+MPCAdditions.h"

#import "MPCMailBundle.h"

@implementation NSBundle (NSBundle_MPCAdditions)

- (NSString *)versionString {
	return [[self infoDictionary] valueForKey:(NSString *)kCFBundleVersionKey];
}

- (BOOL)hasLaterVersionNumberThanBundle:(NSBundle *)otherBundle {

	if (otherBundle == nil) {
		return YES;
	}
	
	return ([MPCMailBundle compareVersion:[self versionString] toVersion:[otherBundle versionString]] == NSOrderedDescending);
	
}

@end
