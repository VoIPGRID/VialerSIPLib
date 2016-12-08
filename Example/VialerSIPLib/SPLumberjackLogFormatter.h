//
//  SPLumberjackLogFormatter.h
//  Copyright © 2016 Devhouse Spindle. All rights reserved.
//

@import Foundation;
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

@interface SPLumberjackLogFormatter : NSObject <DDLogFormatter>

@end
