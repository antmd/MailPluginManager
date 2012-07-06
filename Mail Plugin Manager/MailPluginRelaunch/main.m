//
//  main.m
//  MailPluginRelaunch
//
//  Created by Scott Little on 05/07/2012.
//  Copyright (c) 2012 Little Known Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <AppKit/AppKit.h>

#define	CHECK_FOR_MAIL_TO_QUIT_TIME	.25				// Time this app uses to recheck if the parent has already died.

@interface TerminationListener : NSObject {
	NSString		*mailIdentifier;
	NSTimer			*watchdogTimer;
	NSTimeInterval	delayUntil;
}

- (void)appsHaveQuit;
- (void)relaunch;
- (void)watchdog:(NSTimer *)aTimer;

@end

@implementation TerminationListener

- (id) initWithDelayTime:(CGFloat)delayTime {
	if( !(self = [super init]) )
		return nil;
	
	delayUntil = [NSDate timeIntervalSinceReferenceDate] + delayTime;
	
	mailIdentifier = @"com.apple.mail";
	watchdogTimer = [[NSTimer scheduledTimerWithTimeInterval:CHECK_FOR_MAIL_TO_QUIT_TIME target:self selector:@selector(watchdog:) userInfo:nil repeats:YES] retain];
	
	return self;
}


-(void)dealloc {
	[watchdogTimer release];
	watchdogTimer = nil;
	
	[mailIdentifier release];
	mailIdentifier = nil;
	
	[super dealloc];
}


-(void)appsHaveQuit {
	[watchdogTimer invalidate];
	[self relaunch];
}

- (void)watchdog:(NSTimer *)aTimer {
	
	if (delayUntil > [NSDate timeIntervalSinceReferenceDate]) {
		return;
	}
	
	NSRunningApplication	*mailApp = nil;
	NSRunningApplication	*finisher = nil;
	for (NSRunningApplication *app in [[NSWorkspace sharedWorkspace] runningApplications]) {
		if ([[app bundleIdentifier] isEqualToString:mailIdentifier]) {
			mailApp = app;
		}
		if ([[app localizedName] isEqualToString:@"finish_installation"]) {
			finisher = app;
		}
	}
	
	if ((mailApp == nil) && (finisher == nil)) {
		[self appsHaveQuit];
	}
}


- (void)relaunch {
	NSString	*appPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:mailIdentifier];
	NSLog(@"############ relaunching %@", appPath);
	[[NSWorkspace sharedWorkspace] openFile:appPath];

	exit(EXIT_SUCCESS);
}

@end

int main (int argc, const char * argv[])
{
	if( argc < 1 || argc > 2 )
		return EXIT_FAILURE;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	//ProcessSerialNumber		psn = { 0, kCurrentProcess };
	//TransformProcessType( &psn, kProcessTransformToForegroundApplication );
	[[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
	
	[NSApplication sharedApplication];
	[[[TerminationListener alloc] initWithDelayTime:(argc > 1) ? atof(argv[1]) : 0.0] autorelease];
	[[NSApplication sharedApplication] run];
	
	[pool drain];
	
	return EXIT_SUCCESS;
}
