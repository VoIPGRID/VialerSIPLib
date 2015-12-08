This is a log formatter for CocoaLumberjack: https://github.com/CocoaLumberjack
Use a version less than 2 for compatibility with CocoaLumberjack up to (but not included) version 2.
Use version 2 or greater for compatibility with CocoaLumberjack version 2 and higher.


Normally CocoaLumberjack logs asynchronous but with this formatter, logging will be done synchronously when DEBUG is defined.


The log string is also compacted when DEBUG is defined:
    ERROR   11:09:20.363 [AppDelegate application:didFinishLaunchingWithOptions:29] This is an ERROR
instead of
    ERROR   2014/07/30 10:45:41.823 [AppDelegate application:didFinishLaunchingWithOptions:29] This is an ERROR


You will still need to setup your own logger for instance like this:
    
    //Add the Terminal and TTY(XCode console) loggers to CocoaLumberjack (simulate the default NSLog behaviour)
    HDLumberjackLogFormatter* logFormat = [[HDLumberjackLogFormatter alloc] init];
    
    DDASLLogger *aslLogger = [DDASLLogger sharedInstance];
    [aslLogger setLogFormatter: logFormat];
    DDTTYLogger *ttyLogger = [DDTTYLogger sharedInstance];
    [ttyLogger setLogFormatter:logFormat];
    [ttyLogger setColorsEnabled:YES];
    
    //Give INFO a color
    UIColor *pink = [UIColor colorWithRed:(255/255.0) green:(58/255.0) blue:(159/255.0) alpha:1.0];
    [[DDTTYLogger sharedInstance] setForegroundColor:pink backgroundColor:nil forFlag:DDLogFlagInfo];
    
    [DDLog addLogger:aslLogger];
    [DDLog addLogger:ttyLogger];


CocoaLumberjack supports XcodeColors, you might need to define "XcodeColors YES" see:
https://github.com/CocoaLumberjack/CocoaLumberjack/blob/master/Documentation/XcodeColors.md