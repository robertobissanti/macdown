//
//  MPHomebrewSubprocessController.m
//  MacDown
//
//  Created by Tzu-ping Chung on 18/2.
//  Copyright © 2017 Tzu-ping Chung . All rights reserved.
//

#import "MPHomebrewSubprocessController.h"


@interface MPHomebrewSubprocessController ()

@property (readonly) NSTask *task;
@property (readwrite) void(^completionHandler)(NSString *);

@end


@implementation MPHomebrewSubprocessController

- (instancetype)initWithArguments:(NSArray *)args
{
    self = [super init];
    if (!self)
        return nil;

    NSPipe *stdoutPipe = [[NSPipe alloc] init];

    _task = [[NSTask alloc] init];
    _task.launchPath = @"brew";
    if (args)
        _task.arguments = args;
    _task.standardOutput = stdoutPipe;

    return self;
}

- (instancetype)init
{
    return [self initWithArguments:nil];
}

- (void)runWithCompletionHandler:(void(^)(NSString *))handler
{
    self.completionHandler = handler;

    // -readToEndOfFileInBackgroundAndNotify + NSNotificationCenter (the
    // previous implementation) is a pre-GCD API whose background read and
    // notification delivery run at a QoS the app doesn't control. Xcode's
    // Thread Performance Checker flagged a priority-inversion "Hang Risk"
    // where the main thread (user-interactive, switching Preferences
    // panes) ended up waiting on a lock also touched by this machinery.
    // NSTask.terminationHandler runs on a GCD-managed queue we don't have
    // to fight with, and we explicitly hop back to the main queue
    // ourselves before touching the completion handler (callers update
    // KVO-observed/bound UI properties from it).
    // Deliberately capture self strongly (not weak): MPDetectHomebrewPrefix
    // WithCompletionhandler() below creates this controller as a local
    // variable with no other owner, so this is what keeps it alive for the
    // task's duration. NSTask releases its terminationHandler after
    // invoking it once, so this isn't a lasting retain cycle.
    NSFileHandle *stdoutReadHandle =
        ((NSPipe *)self.task.standardOutput).fileHandleForReading;
    self.task.terminationHandler = ^(NSTask *task) {
        NSData *outData = [stdoutReadHandle readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:outData
                                                   encoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.completionHandler)
                self.completionHandler(output);
        });
    };

    @try
    {
        [self.task launch];
    }
    @catch (NSException *exception)     // Homebrew not installed.
    {
        if (handler)
            handler(nil);
    }
}

@end


void MPDetectHomebrewPrefixWithCompletionhandler(void(^handler)(NSString *))
{
    NSArray *args = @[@"--prefix"];
    MPHomebrewSubprocessController *c =
        [[MPHomebrewSubprocessController alloc] initWithArguments:args];
    [c runWithCompletionHandler:handler];
}

