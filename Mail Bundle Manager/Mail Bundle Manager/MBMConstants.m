//
//  MBMConstants.m
//  Mail Bundle Manager
//
//  Created by Scott Little on 12/09/2011.
//  Copyright (c) 2011 Little Known Software. All rights reserved.
//

#ifdef STR_CONST
#undef STR_CONST
#endif
#define STR_CONST(name, value) NSString* const name = @ value
#include "MBMConstantsList.h"

