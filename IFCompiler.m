//
//  IFCompiler.m
//  Inform
//
//  Created by Andrew Hunter on Mon Aug 18 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFCompiler.h"

static int mod = 0;

NSString* IFCompilerStartingNotification = @"IFCompilerStartingNotification";
NSString* IFCompilerStdoutNotification   = @"IFCompilerStdoutNotification";
NSString* IFCompilerStderrNotification   = @"IFCompilerStderrNotification";
NSString* IFCompilerFinishedNotification = @"IFCompilerFinishedNotification";

@implementation IFCompiler

+ (NSString*) compilerExecutable {
    // Implement me: allow for compilers installed other than inside the bundle
    // Implement me: allow for compilers with different versions inside the bundle
    /*
    NSString* compString = [NSString stringWithFormat: @"%@/Compilers/inform-6.21-zcode",
        [[NSBundle mainBundle] resourcePath]];
     */
    NSString* compString = [NSString stringWithFormat: @"%@/Compilers/inform-6.3-biplatform",
        [[NSBundle mainBundle] resourcePath]];

    if ([[NSFileManager defaultManager] fileExistsAtPath: compString]) {
        return compString;
    } else {
        return nil; // No compiler available
    }
}

// == Initialisation, etc ==

- (id) init {
    self = [super init];

    if (self) {
        settings = nil;
        inputFile = nil;
        theTask = nil;
        stdOut = stdErr = nil;
        delegate = nil;
        workingDirectory = nil;

        deleteOutputFile = YES;
        runQueue = [[NSMutableArray allocWithZone: [self zone]] init];
    }
    
    return self;
}

- (void) dealloc {
    if (deleteOutputFile) [self deleteOutput];

    [theTask release];
    theTask = nil;

    if (outputFile)       [outputFile release];
    if (workingDirectory) [workingDirectory release];    
    if (settings)         [settings release];
    if (inputFile)        [inputFile release];

    if (stdOut) [stdOut release];
    if (stdErr) [stdErr release];

    if (delegate) [delegate release];

    [runQueue release];
    
    [super dealloc];
}

// == Setup ==

- (void) setSettings: (IFCompilerSettings*) set {
    if (settings) [settings release];

    settings = [set retain];
}

- (void) setInputFile: (NSString*) path {
    if (inputFile) [inputFile release];

    inputFile = [path copyWithZone: [self zone]];
}

- (NSString*) inputFile {
    return inputFile;
}

- (IFCompilerSettings*) settings {
    return settings;
}

- (void) deleteOutput {
    if (outputFile) {
        if ([[NSFileManager defaultManager] fileExistsAtPath: outputFile]) {
            NSLog(@"Removing '%@'", outputFile);
            [[NSFileManager defaultManager] removeFileAtPath: outputFile
                                                     handler: nil];
        } else {
            NSLog(@"Compiler produced no output");
            // Nothing to do
        }
        
        [outputFile release];
        outputFile = nil;
    }
}

- (void) addCustomBuildStage: (NSString*) command
               withArguments: (NSArray*) arguments
              nextStageInput: (NSString*) file {
    if (theTask) {
        // This starts a new build process, so we kill the old task if it's still
        // running
        if ([theTask isRunning]) {
            [theTask terminate];
        }
        [theTask release];
        theTask = nil;
    }

    [runQueue addObject: [NSArray arrayWithObjects:
        [NSString stringWithString: command],
        [NSArray arrayWithArray: arguments],
        [NSString stringWithString: file], nil]];
}

- (void) addNaturalInformStage {
    // Prepare the arguments
    NSMutableArray* args = [NSMutableArray arrayWithArray: [settings naturalInformCommandLineArguments]];

    [args addObject: @"-package"];
    [args addObject: [NSString stringWithString: [self currentStageInput]]];

    [self addCustomBuildStage: [settings naturalInformCompilerToUse]
                withArguments: args
               nextStageInput: [NSString stringWithFormat: @"%@/Build/auto.inf", [self currentStageInput]]];
}

- (void) addStandardInformStage {
    if (!outputFile) [self outputFile];
    
    // Prepare the arguments
    NSMutableArray* args = [NSMutableArray arrayWithArray: [settings commandLineArguments]];

    [args addObject: @"-x"];
   
    [args addObject: [NSString stringWithString: [self currentStageInput]]];
    [args addObject: [NSString stringWithString: outputFile]];

    [self addCustomBuildStage: [settings compilerToUse]
                withArguments: args
               nextStageInput: outputFile];
}

- (NSString*) currentStageInput {
    NSString* inFile = inputFile;
    if (![runQueue count] <= 0) inFile = [[runQueue lastObject] objectAtIndex: 2];

    return inFile;
}

- (void) prepareForLaunch {
    // Kill off any old tasks...
    if (theTask) {
        if ([theTask isRunning]) {
            [theTask terminate];
        }
        [theTask release];
        theTask = nil;
    }

    if (deleteOutputFile) [self deleteOutput];

    // Prepare the arguments
    if ([runQueue count] <= 0) {
        if ([settings runBuildScript]) {
            NSString* buildsh = [@"~/build.sh" stringByExpandingTildeInPath];
            
            [self addCustomBuildStage: buildsh
                        withArguments: [NSArray array]
                       nextStageInput: [self currentStageInput]];
            
        }
        
        if ([settings usingNaturalInform]) {
            [self addNaturalInformStage];
        }

        if (![settings usingNaturalInform] || [settings compileNaturalInformOutput]) {
            [self addStandardInformStage];
        }
    }

    /*
    NSMutableArray* args = [NSMutableArray arrayWithArray: [settings commandLineArguments]];

    [args addObject: @"-x"];

    [args addObject: [NSString stringWithString: inputFile]];
    [args addObject: [NSString stringWithString: outputFile]];
     */
    
    NSArray* args     = [[runQueue objectAtIndex: 0] objectAtIndex: 1];
    NSString* command = [[runQueue objectAtIndex: 0] objectAtIndex: 0];
    [[args retain] autorelease];
    [[command retain] autorelease];
    [runQueue removeObjectAtIndex: 0];

    // Prepare the task
    theTask = [[NSTask allocWithZone: [self zone]] init];
    finishCount = 0;

    [theTask setArguments:  args];
    [theTask setLaunchPath: command];
    if (workingDirectory)
        [theTask setCurrentDirectoryPath: workingDirectory];
    else
        [theTask setCurrentDirectoryPath: NSTemporaryDirectory()];

    // Prepare the task's IO

    // waitForDataInBackground is a daft way of doing things and a waste of a thread
    if (stdErr) [stdErr release];
    if (stdOut) [stdOut release];

    [[NSNotificationCenter defaultCenter] removeObserver: self];

    stdErr = [[NSPipe allocWithZone: [self zone]] init];
    stdOut = [[NSPipe allocWithZone: [self zone]] init];

    [theTask setStandardOutput: stdOut];
    [theTask setStandardError:  stdErr];

    stdErrH = [stdErr fileHandleForReading];
    stdOutH = [stdOut fileHandleForReading];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(stdOutWaiting:)
                                                 name: NSFileHandleDataAvailableNotification
                                               object: stdOutH];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(stdErrWaiting:)
                                                 name: NSFileHandleDataAvailableNotification
                                               object: stdErrH];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(taskDidFinish:)
                                                 name: NSTaskDidTerminateNotification
                                               object: theTask];

    [stdOutH waitForDataInBackgroundAndNotify];
    [stdErrH waitForDataInBackgroundAndNotify];
}

- (void) launch {
    [[NSNotificationCenter defaultCenter] postNotificationName: IFCompilerStartingNotification
                                                        object: self];
    [theTask launch];
}

- (NSString*) outputFile {
    if (outputFile == nil) {
        outputFile = [[NSString stringWithFormat: @"%@/Inform-%x-%x.%@",
            NSTemporaryDirectory(), time(NULL), ++mod, [settings fileExtension]] retain];
        deleteOutputFile = YES;
    }

    return [NSString stringWithString: outputFile];
}

- (void) setOutputFile: (NSString*) file {
    if (outputFile) [outputFile release];
    outputFile = [file copy];
    deleteOutputFile = NO;
}

- (void) setDeletesOutput: (BOOL) deletes {
    deleteOutputFile = deletes;
}

- (void) setDelegate: (id<NSObject>) dg {
    if (delegate) [delegate release];
    delegate = [dg retain];
}

- (id) delegate {
    return delegate;
}

- (void) setDirectory: (NSString*) path {
    if (workingDirectory) [workingDirectory release];
    workingDirectory = [path copy];
}

- (NSString*) directory {
    return [[workingDirectory copy] autorelease];
}

- (void) taskHasReallyFinished {
    BOOL failed = [theTask terminationStatus] != 0;

    if (failed) {
        [runQueue removeAllObjects];
    }

    if ([runQueue count] <= 0) {
        if (delegate &&
            [delegate respondsToSelector: @selector(taskFinished:)]) {
            [delegate taskFinished: [theTask terminationStatus]];
        }

        NSDictionary* uiDict = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt: [theTask terminationStatus]],
            @"exitCode",
            nil];
        [[NSNotificationCenter defaultCenter] postNotificationName: IFCompilerFinishedNotification
                                                            object: self
                                                          userInfo: uiDict];
    } else {
        int exitCode = [theTask terminationStatus];
        
        if (exitCode != 0) {
            // The task failed
            if (delegate &&
                [delegate respondsToSelector: @selector(taskFinished:)]) {
                [delegate taskFinished: exitCode];
            }
            
            // Notify everyone of the failure
            NSDictionary* uiDict = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt: exitCode],
                @"exitCode",
                nil];
            [[NSNotificationCenter defaultCenter] postNotificationName: IFCompilerFinishedNotification
                                                                object: self
                                                              userInfo: uiDict];
            
            // Give up
            [runQueue removeAllObjects];
            [theTask release];
            theTask = nil;
            
            return;
        }
        
        // Prepare the next task for launch
        if (theTask) {
            if ([theTask isRunning]) {
                [theTask terminate];
            }
            [theTask release];
            theTask = nil;
        }

        NSArray* args     = [[runQueue objectAtIndex: 0] objectAtIndex: 1];
        NSString* command = [[runQueue objectAtIndex: 0] objectAtIndex: 0];
        [[args retain] autorelease];
        [[command retain] autorelease];
        [runQueue removeObjectAtIndex: 0];

        theTask = [[NSTask allocWithZone: [self zone]] init];
        finishCount = 0;

        // Prepare the task
        [theTask setArguments:  args];
        [theTask setLaunchPath: command];
        if (workingDirectory)
            [theTask setCurrentDirectoryPath: workingDirectory];
        else
            [theTask setCurrentDirectoryPath: NSTemporaryDirectory()];

        // Prepare the task's IO
        if (stdErr) [stdErr release];
        if (stdOut) [stdOut release];

        [[NSNotificationCenter defaultCenter] removeObserver: self];

        stdErr = [[NSPipe allocWithZone: [self zone]] init];
        stdOut = [[NSPipe allocWithZone: [self zone]] init];

        [theTask setStandardOutput: stdOut];
        [theTask setStandardError:  stdErr];

        stdErrH = [stdErr fileHandleForReading];
        stdOutH = [stdOut fileHandleForReading];

        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(stdOutWaiting:)
                                                     name: NSFileHandleDataAvailableNotification
                                                   object: stdOutH];

        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(stdErrWaiting:)
                                                     name: NSFileHandleDataAvailableNotification
                                                   object: stdErrH];

        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(taskDidFinish:)
                                                     name: NSTaskDidTerminateNotification
                                                   object: theTask];

        [stdOutH waitForDataInBackgroundAndNotify];
        [stdErrH waitForDataInBackgroundAndNotify];

        // Launch it
        [theTask launch];
    }
}

// == Notifications ==
- (void) stdOutWaiting: (NSNotification*) not {
    NSData* inData = [stdOutH availableData];

    if ([inData length]) {
        if (delegate &&
            [delegate respondsToSelector: @selector(receivedFromStdErr:)]) {
            [delegate receivedFromStdErr: [NSString stringWithCString: [inData bytes]
                                                               length: [inData length]]]; 
        }

        NSDictionary* uiDict = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSString stringWithCString: [inData bytes]
                                 length: [inData length]],
                @"string",
                nil];
        [[NSNotificationCenter defaultCenter] postNotificationName: IFCompilerStdoutNotification
                                                            object: self
                                                          userInfo: uiDict];

        [stdOutH waitForDataInBackgroundAndNotify];
    } else {
        finishCount++;

        if (finishCount == 3) {
            [self taskHasReallyFinished];
        }
    }
}

- (void) stdErrWaiting: (NSNotification*) not {
    NSData* inData = [stdErrH availableData];

    if ([inData length]) {
        if (delegate &&
            [delegate respondsToSelector: @selector(receivedFromStdErr:)]) {
            [delegate receivedFromStdErr: [NSString stringWithCString: [inData bytes]
                                                               length: [inData length]]];
        }

        NSDictionary* uiDict = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSString stringWithCString: [inData bytes]
                                 length: [inData length]],
                @"string",
                nil];
        [[NSNotificationCenter defaultCenter] postNotificationName: IFCompilerStderrNotification
                                                            object: self
                                                          userInfo: uiDict];
        
        [stdErrH waitForDataInBackgroundAndNotify];
    } else {
        finishCount++;

        if (finishCount == 3) {
            [self taskHasReallyFinished];
        }
    }
}

- (void) taskDidFinish: (NSNotification*) not {
    finishCount++;

    if (finishCount == 3) {
        [self taskHasReallyFinished];
    }
}

@end
