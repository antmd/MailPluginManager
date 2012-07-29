//
//  MPCConstants.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#ifdef STR_CONST
#undef STR_CONST
#endif
#define STR_CONST(name, value) NSString* const name = @ value
#include "MPCConstantsList.h"

NSInteger osMinorVersion(void) {
	// use a static because we only really need to get the version once.
	static NSInteger minVersion = 0;  // 0 == notSet
	if (minVersion == 0) {
		SInt32 version = 0;
		OSErr err = Gestalt(gestaltSystemVersionMinor, &version);
		if (!err) {
			minVersion = (NSInteger)version;
		}
	}
	return minVersion;
}

