//
//  HDLumberjackLogFormatter.h
//  HDLumberjackLogFormatter
//
//  Created by Harold on 25/02/14.
//  Copyright (c) 2014 hd-apps.com. All rights reserved.
//

#import <Foundation/Foundation.h>

//Do all Lumberjack imports here, this way you only need to include this file to use Lumberjack
#import <CocoaLumberjack/CocoaLumberjack.h>

// ========================= Overrides ========================================
// --> per https://github.com/robbiehanson/CocoaLumberjack/wiki/CustomLogLevels
// ----------------------------------------------------------------------------

// Are we in an debug build?
#ifdef DEBUG
    // YES: We're in a Debug build. As such, let's configure logging to flush right away.
    #ifdef LOG_ASYNC_ENABLED
        #undef LOG_ASYNC_ENABLED
    #endif
    #define LOG_ASYNC_ENABLED NO
#endif

@interface HDLumberjackLogFormatter : NSObject <DDLogFormatter>

@end
