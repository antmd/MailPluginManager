//
//  main.m
//  CopyMoveHelper2
//
//  Created by Scott Little on 12/8/13.
//  Copyright (c) 2013 Little Known Software. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <syslog.h>
#include <xpc/xpc.h>

static	BOOL	isProcessing = YES;

static void __XPC_Peer_Event_Handler(xpc_connection_t connection, xpc_object_t event) {
//    syslog(LOG_NOTICE, "Received event in helper.");
    
	xpc_type_t type = xpc_get_type(event);
    
	if (type == XPC_TYPE_ERROR) {
		if (event == XPC_ERROR_CONNECTION_INVALID) {
			// The client process on the other end of the connection has either
			// crashed or cancelled the connection. After receiving this error,
			// the connection is in an invalid state, and you do not need to
			// call xpc_connection_cancel(). Just tear down any associated state
			// here.
            
		} else if (event == XPC_ERROR_TERMINATION_IMMINENT) {
			// Handle per-connection termination cleanup.
		}
        
	} else {
		isProcessing = YES;
//		syslog(LOG_NOTICE, "SJL:Processing set to YES - New Version");
        xpc_connection_t remote = xpc_dictionary_get_remote_connection(event);
		
        xpc_object_t reply = xpc_dictionary_create_reply(event);
		NSString	*errorString = nil;
		BOOL		getVersion = (BOOL)xpc_dictionary_get_bool(event, "getVersion");
		
		if (getVersion) {
			NSUInteger	version = [[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] integerValue];
			xpc_dictionary_set_int64(reply, "buildVersion", (int64_t)version);
//			syslog(LOG_NOTICE, "SJL:bundle version is %ld", (long)version);
		}
		else {
		
			BOOL		shouldCopy = (BOOL)xpc_dictionary_get_bool(event, "shouldCopy");
			BOOL		shouldOverwrite = (BOOL)xpc_dictionary_get_bool(event, "shouldOverwrite");
			const char	*sourcePathStr = xpc_dictionary_get_string(event, "sourcePath");
			const char	*destPathStr = xpc_dictionary_get_string(event, "destPath");
			NSString	*fromPath = nil;
			NSString	*toPath = nil;
			
			if (sourcePathStr) {
				fromPath = [NSString stringWithUTF8String:sourcePathStr];
			}
			if (destPathStr) {
				toPath = [NSString stringWithUTF8String:destPathStr];
			}
			
	//		syslog(LOG_NOTICE, "From path: %s  To Path: %s copy:%s", sourcePathStr, destPathStr, shouldCopy?"YES":"NO");
			
			if (fromPath && toPath) {
				
				NSError			*localError = nil;
				NSFileManager	*manager = [NSFileManager defaultManager];
				
				//	Remove any existing file at destPath
				if ([manager fileExistsAtPath:toPath]) {
					if (shouldOverwrite) {
						if (![manager removeItemAtPath:toPath error:&localError]) {
							errorString = [NSString stringWithFormat:@"Could not delete a file (%@) to be overwritten:%@", [toPath lastPathComponent], [localError localizedDescription]];
						}
					}
					else {
						//	Create a new error message to return
						errorString = [NSString stringWithFormat:@"File exists (%@) which should not be overwritten", [toPath lastPathComponent]];
					}
				}
				
				if (errorString == nil) {
					BOOL	didSucceed = NO;
					if (shouldCopy) {
						didSucceed = [manager copyItemAtPath:fromPath toPath:toPath error:&localError];
					}
					else {
						didSucceed = [manager moveItemAtPath:fromPath toPath:toPath error:&localError];
					}
					if (!didSucceed) {
						errorString = [NSString stringWithFormat:@"Error %@ bundle (enable/disable):%@", (shouldCopy?@"copying":@"moving"), [localError localizedDescription]];
					}
				}
			}
			else {
				errorString = [NSString stringWithFormat:@"Either the from or to path for copying a file with privileges was nil - From:%s To:%s", sourcePathStr, destPathStr];
	//			syslog(LOG_NOTICE, "Either the from or to path for copying a file with privileges was nil - From:%s To:%s", sourcePathStr, destPathStr);
			}

			xpc_dictionary_set_bool(reply, "reply", (bool)(errorString == nil));
			if (errorString) {
				syslog(LOG_NOTICE, "Error in helper:%s", [errorString UTF8String]);
				xpc_dictionary_set_string(reply, "error", [errorString UTF8String]);
			}
		}
        
        xpc_connection_send_message(remote, reply);
        xpc_release(reply);
		isProcessing = NO;
//		syslog(LOG_NOTICE, "SJL:Processing set to done");
	}
}

static void __XPC_Connection_Handler(xpc_connection_t connection)  {
//    syslog(LOG_NOTICE, "Configuring message event handler for helper.");
    
	xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
		__XPC_Peer_Event_Handler(connection, event);
	});
	
	xpc_connection_resume(connection);
}

static void setup_idle_time_quit(xpc_connection_t service) {

//	syslog(LOG_NOTICE, "SJL:Inside setup idle quit");
	
	//	This ensures that we just push off quitting for x minutes if there is processing going on
	if (isProcessing) {
		syslog(LOG_NOTICE, "SJL:Delaying for 5 minutes");
		double delayInSeconds = 5.0 * 60.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			setup_idle_time_quit(service);
		});
		return;
	}

	//	This closes out the connection, lets anything currently happening finish before cancel, release and quit
//	syslog(LOG_NOTICE, "SJL:Suspending");
	xpc_connection_suspend(service);
	dispatch_async(dispatch_get_main_queue(), ^{
//		syslog(LOG_NOTICE, "SJL:Quitting");
		xpc_connection_cancel(service);
		xpc_release(service);
		exit(0);
	});

}

int main(int argc, const char *argv[]) {
	
	@autoreleasepool {
	    
		NSString	*filePath = [NSString stringWithUTF8String:argv[0]];
		xpc_connection_t service = xpc_connection_create_mach_service([[filePath lastPathComponent] UTF8String],
																	  dispatch_get_main_queue(),
																	  XPC_CONNECTION_MACH_SERVICE_LISTENER);
		
		if (!service) {
			syslog(LOG_NOTICE, "Failed to create MPC CopyMoveHelper service.");
			exit(EXIT_FAILURE);
		}
		
//		syslog(LOG_NOTICE, "Configuring connection event handler for helper");
		xpc_connection_set_event_handler(service, ^(xpc_object_t connection) {
			__XPC_Connection_Handler(connection);
		});
		
		xpc_connection_resume(service);
		
		setup_idle_time_quit(service);
		
		dispatch_main();
		
	}
    return 0;
    
}
