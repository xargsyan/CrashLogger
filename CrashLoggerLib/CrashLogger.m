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
            NSLog(@"WARNING: Tried to register the same log handler. Skipping registration.\n"
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

#pragma mark - Safe blocks

+ (id)safeBlock:(id(^)(void))block{
    // Catching uncaught exceptions. Uncaught exceptions go up in exception handling chain, and if there's no exception handler, they reach this function and get caught there.
    @try {
        block();
    }
    @catch (id exception){
        if ([exception class]==NSException.class){
            NSLog(@"%@",[CrashLoggerUtilities NSExceptionToString:exception]);
        } else {
            // Catch other exception types which are compatible with id type (such as NSString, NSObject). Logging their classes.
            NSLog(@"Unhandled exception of type %@", [exception class]);
        }
    }
    // Catch other exception types. This case should never happen as @throw only accepts object types. If it happens take care carefully
    @catch (...){
        NSLog(@"Unhandled exception of unknown type");
    }
}

@end
