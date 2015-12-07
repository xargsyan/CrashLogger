//
//  CrashLogger.m
//  CrashLogger
//
//  Created by SS on 12/3/15.
//  Copyright © 2015 Macadamian. All rights reserved.
//

#import "CrashLogger.h"
#import "CrashLoggerUtilities.h"

@interface CrashLogger()
@property NSMutableDictionary* logHandlers;

@end

@implementation CrashLogger

#pragma mark - Singleton creation and initialization

+ (instancetype)sharedInstance {
    static CrashLogger * _sharedInstance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (id)init {
    self = [super init];
    if (!self) return self;
    
    // Initialize properties here
    NSLog(@"Initializing CrashLogger...");
    _logHandlers=[[NSMutableDictionary alloc] init];
    return self;
}

#pragma mark - Log handler registration

- (BOOL) registerLogHandler: (id <LogHandlingProtocol>) logHandler withID:(NSString*) handlerID{
    if ([_logHandlers objectForKey:handlerID]==nil){
        [_logHandlers setObject:logHandler forKey:handlerID];
    } else {
        if ([_logHandlers objectForKey:handlerID]==logHandler){
            NSLog(@"WARNING: Tried to register the same log handler.\nSkipping registration.\n"
                  "1) Make sure you want to register the same log handler.\n"
                  "2) If necessary, change handlerID for registering as another handler.\n");
        } else {
            NSLog(@"WARNING: Tried to register another log handler on top of registered one (with same handler ID). Skipping registration.\n"
                  "1) Change handler ID\n"
                  "2) Unregister previous log handler and register this one\n");
        }
        return false;
    }
    return true;
}


- (BOOL) unregisterLogHandler: (NSString*) handlerID{
    if ([_logHandlers objectForKey:handlerID]!=nil){
        [_logHandlers removeObjectForKey:handlerID];
    } else {
        NSLog(@"WARNING: Tried to unregister non-existing log handler ID.\nSkipping unregistration.");
        return false;
    }
    return true;
}

#pragma mark - Logging methods

- (void) log:(NSString *)format, ...{
    va_list args;
    va_start(args, format);
    [self logNSString: [[NSString alloc]initWithFormat:format arguments:args]];
    va_end(args);
}

- (void) logObject:(id)object {
    if (_logHandlers.count==0){
        NSLog(@"WARNING: Tried to log without log handlers. Log will be skipped.\n"
              "Register log handlers before logging info.");
        return;
    }
    
    // Iterating through log handlers and sending them info to handle
    id <LogHandlingProtocol> handler=nil;
    for (id key in _logHandlers){
        handler=[_logHandlers objectForKey:key];
        if (handler!=nil){
            if ([handler respondsToSelector:@selector(handleObject:)]){
                [handler handleObject:object];
            } else {
                NSLog(@"WARNING: Can't pass information to log handler.\n"
                      "Log handler did not respond to selector 'handle'.\n"
                      "Make sure log handler is correct and conforms to log handling protocol.");
                continue;
            }
        } else {
            NSLog(@"WARNING: Encountered empty (nil) log handler. Skipping it.");
            continue;
        }
    }
}

- (void) logNSString: (NSString*) info {
    if (_logHandlers.count==0){
        NSLog(@"WARNING: Tried to log without log handlers. Log will be skipped.\n"
              "Register log handlers before logging info.");
        return;
    }
    
    // Iterating through log handlers and sending them info to handle
    id <LogHandlingProtocol> handler=nil;
    for (id key in _logHandlers){
        handler=[_logHandlers objectForKey:key];
        if (handler!=nil){
            if ([handler respondsToSelector:@selector(handle:)]){
                [handler handle:info];
            } else {
                NSLog(@"WARNING: Can't pass information to log handler.\n"
                      "Log handler did not respond to selector 'handle'.\n"
                      "Make sure log handler is correct and conforms to log handling protocol.");
                continue;
            }
        } else {
            NSLog(@"WARNING: Encountered empty log handler. Skipping it.");
            continue;
        }
    }
    
}

#pragma mark - Global uncaught exception Handler

// Handle uncaught exceptions here
void _uncaughtExceptionHandler(NSException* exception) {
    [[CrashLogger sharedInstance] logObject:exception];
    // There are three ways: 1) exit() here and don't wait for crash, 2) don't exit(), catch signal SIGABRT and handle it, 3) don't exit() and crash
    // exit(0);
}

// Objective-C style wrapper for C-style function _uncaughtExceptionHandler(). Returns pointer function's pointer. Note: for handling exceptions, go to _uncaughtExceptionHandler function
- (NSUncaughtExceptionHandler*) uncaughtExceptionHandler{
    return &_uncaughtExceptionHandler;
}

#pragma mark - Safe blocks

+ (id)safeBlock:(id(^)(void))block{
    // Catching uncaught exceptions. Uncaught exceptions go up in exception handling chain, and if there's no exception handler, they reach this function and get caught there.
    @try {
        block();
    }
    @catch (NSString* exception){
        [[CrashLogger sharedInstance] log:exception];
    }
    // Catch other exception types which are compatible with id type (such as NSObject, NSError). Logging their classes.
    @catch (id exception){
        [[CrashLogger sharedInstance] logObject:exception];
    }
    // Catch other exception types. This case should never happen as @throw only accepts object types. If it happens take care carefully
    @catch (...){
        NSLog(@"Unhandled exception of unknown type");
    }
}

@end
