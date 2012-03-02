//
//  MBTScheduledUpdateDriver.h
//  Mail Plugin Manager
//
//  Created by Scott Little on 01/03/2012.
//  Copyright (c) 2012 Little Known Software. All rights reserved.
//

#import "SUUIBasedUpdateDriver.h"

@interface MBTScheduledUpdateDriver : SUUIBasedUpdateDriver {
@private
	BOOL	showErrors;
	BOOL	postponed;
}

@end
