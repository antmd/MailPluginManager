//
//  MBTSinglePluginController.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 04/10/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MBMMailBundle.h"

@interface MBTSinglePluginController : NSWindowController {
}

@property (nonatomic, retain)	MBMMailBundle	*mailBundle;

@property	(assign) IBOutlet	NSTextField	*mainDescriptionField;
@property	(assign) IBOutlet	NSTextField	*secondaryTextField;
@property	(assign) IBOutlet	NSButton	*rightButton;
@property	(assign) IBOutlet	NSButton	*centerButton;
@property	(assign) IBOutlet	NSButton	*leftButton;

- (id)initWithMailBundle:(MBMMailBundle *)aMailBundle;
@end

