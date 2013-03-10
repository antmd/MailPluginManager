//
//  MPIAppDelegate.h
//  Plugin Installer
//
//  Created by Scott Little on 9/3/13.
//  Copyright (c) 2013 Little Known Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MPCAppDelegate.h"

@interface MPIAppDelegate : MPCAppDelegate {
	
	MPCManifestModel	*_manifestModel;
}

@property (nonatomic, retain)	MPCManifestModel	*manifestModel;

@end
