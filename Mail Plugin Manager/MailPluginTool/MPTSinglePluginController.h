//
//  MPTSinglePluginController.h
//  Mail Bundle Manager
//
//  Created by Scott Little on 04/10/2011.
//  Copyright 2011 Little Known Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MPCMailBundle.h"

typedef enum {
	kMPTButtonLayoutUpdate = 0,
	//	[hidden]			[Not Now]	[Update]
	kMPTButtonLayoutUpdateIncompatible,
	//	[Disable]			[Not Now]	[Update]
	kMPTButtonLayoutUpdateIncompatibleDisabled,
	//	[hidden]			[Not Now]	[Update]
	kMPTButtonLayoutUpdateFutureIncompatible,
	//	[hidden]			[Thanks]	[Update]
	kMPTButtonLayoutIncompatibleOnly,
	//	[Remove]			[Disable]	[Thanks]
	kMPTButtonLayoutIncompatibleOnlyDisabled,
	//	[Remove]			[hidden]	[Thanks]
	kMPTButtonLayoutFutureIncompatibleOnly,
	//	[Disable]			[hidden]	[Thanks]
	kMPTButtonLayoutFutureIncompatibleOnlyDisabled
	//	[hidden]			[hidden]	[Thanks]
} MPTButtonLayoutType;


@interface MPTSinglePluginController : NSWindowController {
@private
	
	MPCMailBundle		*_mailBundle;
	
	NSTextField			*_mainDescriptionField;
	NSTextField			*_secondaryTextField;
	NSButton			*_rightButton;
	NSButton			*_centerButton;
	NSButton			*_leftButton;
	
	NSArray				*_buttonConfigurations;
	MPTButtonLayoutType	_buttonLayout;
}

@property (nonatomic, retain)	MPCMailBundle	*mailBundle;

@property	(assign) IBOutlet	NSTextField	*mainDescriptionField;
@property	(assign) IBOutlet	NSTextField	*secondaryTextField;
@property	(assign) IBOutlet	NSButton	*rightButton;
@property	(assign) IBOutlet	NSButton	*centerButton;
@property	(assign) IBOutlet	NSButton	*leftButton;

- (id)initWithMailBundle:(MPCMailBundle *)aMailBundle;
@end

