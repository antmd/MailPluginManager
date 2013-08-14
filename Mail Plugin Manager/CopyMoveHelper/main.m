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

static void __XPC_Peer_Event_Handler(xpc_connection_t connection, xpc_object_t event) {
    syslog(LOG_NOTICE, "Received event in helper.");
    
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
        xpc_connection_t remote = xpc_dictionary_get_remote_connection(event);
		
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
		
		syslog(LOG_NOTICE, "From path: %s  To Path: %s copy:%s", sourcePathStr, destPathStr, shouldCopy?"YES":"NO");
		
		NSString	*errorString = nil;
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
			syslog(LOG_NOTICE, "Either the from or to path for copying a file with privileges was nil - From:%s To:%s", sourcePathStr, destPathStr);
		}
        
        xpc_object_t reply = xpc_dictionary_create_reply(event);
        xpc_dictionary_set_bool(reply, "reply", (bool)(errorString == nil));
		if (errorString) {
			syslog(LOG_NOTICE, "Error in helper:%s", [errorString UTF8String]);
			xpc_dictionary_set_string(reply, "error", [errorString UTF8String]);
		}
        xpc_connection_send_message(remote, reply);
        xpc_release(reply);
	}
}

static void __XPC_Connection_Handler(xpc_connection_t connection)  {
    syslog(LOG_NOTICE, "Configuring message event handler for helper.");
    
	xpc_connection_set_event_handler(connection, ^(xpc_object_t event) {
		__XPC_Peer_Event_Handler(connection, event);
	});
	
	xpc_connection_resume(connection);
}

int main(int argc, const char *argv[]) {
	
	@autoreleasepool {
	    
		xpc_connection_t service = xpc_connection_create_mach_service(argv[0],
																	  dispatch_get_main_queue(),
																	  XPC_CONNECTION_MACH_SERVICE_LISTENER);
		
		if (!service) {
			syslog(LOG_NOTICE, "Failed to create service.");
			exit(EXIT_FAILURE);
		}
		
		syslog(LOG_NOTICE, "Configuring connection event handler for helper");
		xpc_connection_set_event_handler(service, ^(xpc_object_t connection) {
			__XPC_Connection_Handler(connection);
		});
		
		xpc_connection_resume(service);
		
		dispatch_main();
		
		xpc_release(service);
	    
	}
    return 0;
    
}
