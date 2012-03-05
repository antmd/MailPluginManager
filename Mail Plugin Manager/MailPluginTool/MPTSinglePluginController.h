//
//  MPTSinglePluginController.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 04/10/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MBMMailBundle.h"

typedef enum {
	kMBTButtonLayoutUpdate = 0,
	//	[hidden]			[Not Now]	[Update]
	kMBTButtonLayoutUpdateIncompatible,
	//	[Disable]			[Not Now]	[Update]
	kMBTButtonLayoutUpdateIncompatibleDisabled,
	//	[hidden]			[Not Now]	[Update]
	kMBTButtonLayoutUpdateFutureIncompatible,
	//	[hidden]			[Thanks]	[Update]
	kMBTButtonLayoutIncompatibleOnly,
	//	[Remove]			[Disable]	[Thanks]
	kMBTButtonLayoutIncompatibleOnlyDisabled,
	//	[Remove]			[hidden]	[Thanks]
	kMBTButtonLayoutFutureIncompatibleOnly,
	//	[Disable]			[hidden]	[Thanks]
	kMBTButtonLayoutFutureIncompatibleOnlyDisabled
	//	[hidden]			[hidden]	[Thanks]
} MBTButtonLayoutType;


@interface MPTSinglePluginController : NSWindowController {
@private
	
	MBMMailBundle		*_mailBundle;
	
	NSTextField			*_mainDescriptionField;
	NSTextField			*_secondaryTextField;
	NSButton			*_rightButton;
	NSButton			*_centerButton;
	NSButton			*_leftButton;
	
	NSArray				*_buttonConfigurations;
	MBTButtonLayoutType	_buttonLayout;
}

@property (nonatomic, retain)	MBMMailBundle	*mailBundle;

@property	(assign) IBOutlet	NSTextField	*mainDescriptionField;
@property	(assign) IBOutlet	NSTextField	*secondaryTextField;
@property	(assign) IBOutlet	NSButton	*rightButton;
@property	(assign) IBOutlet	NSButton	*centerButton;
@property	(assign) IBOutlet	NSButton	*leftButton;

- (id)initWithMailBundle:(MBMMailBundle *)aMailBundle;
@end

