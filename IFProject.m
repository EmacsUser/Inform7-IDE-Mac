//
//  IFProject.m
//  Inform
//
//  Created by Andrew Hunter on Wed Aug 27 2003.
//  Copyright (c) 2003 Andrew Hunter. All rights reserved.
//

#import "IFProject.h"
#import "IFProjectController.h"


@implementation IFProject

// == Initialisation ==

- (id) init {
    self = [super init];

    if (self) {
        settings = [[IFCompilerSettings allocWithZone: [self zone]] init];
        projectFile = nil;
        sourceFiles = nil;
        mainSource  = nil;
        singleFile  = YES;

        compiler = [[IFCompiler allocWithZone: [self zone]] init];
		
		notes = [[NSTextStorage alloc] initWithString: @""];
        
        /*
        sourceFiles = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
            [[[NSTextStorage alloc] init] autorelease], @"untitled.inf", nil] retain];
        mainSource = [@"untitled.inf" retain];
         */
    }

    return self;
}

- (void) dealloc {
    if (sourceFiles) [sourceFiles release];
    if (projectFile) [projectFile release];
    if (mainSource)  [mainSource  release];
	if (notes)       [notes release];

	[settings release];
    [compiler release];

    [super dealloc];
}

// == Loading/saving ==
- (BOOL) readFromFile: (NSString*) fileName ofType: (NSString*) fileType {
    if ([fileType isEqualTo: @"Inform project file"]) {
        if (projectFile) [projectFile release];
        if (sourceFiles) [sourceFiles release];
        if (mainSource)  [mainSource  release];

        // Open the directory
        projectFile = [[IFProjectFile allocWithZone: [self zone]]
            initWithPath: fileName];

        if (![projectFile isDirectory]) {
            [projectFile release];
            projectFile = nil;
            return NO;
        }

        // Refresh the settings
        if (settings) [settings release];
        settings = [[projectFile settings] retain];

        // Turn the source directory into NSTextStorages
        NSFileWrapper* sourceDir = [[projectFile fileWrappers] objectForKey: @"Source"];

        if (sourceDir == nil ||
            ![sourceDir isDirectory]) {
            [projectFile release];
            projectFile = nil;
            return NO;
        }

        if (sourceFiles) [sourceFiles release];
        sourceFiles = [[NSMutableDictionary allocWithZone: [self zone]] init];
        NSDictionary* source = [sourceDir fileWrappers];
        NSEnumerator* sourceEnum = [source keyEnumerator];
        NSString* key;

        if (mainSource) [mainSource release];
        mainSource = nil;

		// Load all the source files
        while (key = [sourceEnum nextObject]) {
            NSTextStorage* text;
            NSString*      textData;

            if ([[key pathExtension] isEqualToString: @"rtf"]) {
                NSAttributedString* attr = [[NSAttributedString alloc] initWithRTF: 
                    [[[sourceDir fileWrappers] objectForKey: key] regularFileContents]
                                                                documentAttributes: nil];
                
                text = [[NSTextStorage allocWithZone: [self zone]] initWithAttributedString:
                    attr];
            } else {
                textData = [[NSString alloc] initWithData:
                    [[[sourceDir fileWrappers] objectForKey: key] regularFileContents]
                                                 encoding: NSISOLatin1StringEncoding];

                text = [[NSTextStorage allocWithZone: [self zone]] initWithString:
                    textData];
                [textData release];
            }

            [sourceFiles setObject: [text autorelease]
                            forKey: key];

            if ([[key pathExtension] isEqualTo: @"inf"] ||
                [[key pathExtension] isEqualTo: @"ni"]) {
                if (mainSource) [mainSource release];
                mainSource = [key copy];
            }
        }

        singleFile = NO;
		
		// Load the notes (if present)
		NSFileWrapper* noteWrapper = [[projectFile fileWrappers] objectForKey: @"notes.rtf"];
		if (noteWrapper != nil && [noteWrapper regularFileContents] != nil) {
			NSTextStorage* newNotes = [[NSTextStorage alloc] initWithRTF: [noteWrapper regularFileContents]
													  documentAttributes: nil];
			
			if (newNotes) {
				if (notes) [notes release];
				notes = newNotes;
			}
		}
        
        return YES;
    } else if ([fileType isEqualTo: @"Inform source file"] ||
               [fileType isEqualTo: @"Inform header file"]) {
        // No project file
        if (projectFile) [projectFile release];
        projectFile = nil;
        
        // Default settings
        if (settings) [settings release];
        settings = [[IFCompilerSettings allocWithZone: [self zone]] init];
        
        // Load the single file
        NSString* theFile = [NSString stringWithContentsOfFile: fileName];
        
        if (sourceFiles) [sourceFiles release];
        sourceFiles = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
            [[[NSTextStorage alloc] initWithString: theFile] autorelease],
            [fileName lastPathComponent], nil];
        
        if (mainSource) [mainSource release];
        mainSource = [[fileName lastPathComponent] copy];
        
        singleFile = YES;
        return YES;
    }
    
    return NO;
}

- (BOOL) writeToFile: (NSString*) fileName ofType: (NSString*) fileType {
    if ([fileType isEqualTo: @"Inform project file"]) {
        [self prepareForSaving];
        
        return [projectFile writeToFile: fileName
                             atomically: YES
                        updateFilenames: YES];
    } else if ([fileType isEqualToString: @"Inform source file"] ||
               [fileType isEqualToString: @"Inform header file"]) {
        NSTextStorage* theFile = [self storageForFile: [self mainSourceFile]];
        
        return [[theFile string] writeToFile: fileName
                                  atomically: YES];
    }
    
    return NO;
}

- (BOOL) addFile: (NSString*) newFile {
    if ([sourceFiles objectForKey: newFile] != nil) return NO;
    if (singleFile) return NO;
    
    [sourceFiles setObject: [[[NSTextStorage alloc] initWithString: @""] autorelease]
                    forKey: newFile];
    
    return YES;
}

// == General housekeeping ==
- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
}

- (void)makeWindowControllers {
    IFProjectController *aController = [[IFProjectController allocWithZone:[self zone]] init];
    [self addWindowController:aController];
    [aController release];
}

// == Document info ==
- (IFCompilerSettings*) settings {
    return settings;
}

- (IFCompiler*) compiler {
    return compiler;
}

- (BOOL) singleFile {
    return singleFile;
}

// == Getting the files ==
- (void) prepareForSaving {
    // Update the project file wrapper from whatever is on the disk
    // (Implement me)
    
    // Output all the source files to the project file wrapper
    NSEnumerator* keyEnum = [sourceFiles keyEnumerator];
    NSString*     key;
    NSFileWrapper* source = [[NSFileWrapper alloc] initDirectoryWithFileWrappers: nil];

    [source setPreferredFilename: @"Source"];
    [source setFilename: @"Source"];

    while (key = [keyEnum nextObject]) {
        NSData*        data;
        NSFileWrapper* file;
        
        if ([[key pathExtension] isEqualToString: @"rtf"]) {
            NSAttributedString* str = [sourceFiles objectForKey: key];
            
            data = [str RTFFromRange: NSMakeRange(0, [str length]) documentAttributes: nil];
        } else {
            data = [[[sourceFiles objectForKey: key] string] dataUsingEncoding: NSISOLatin1StringEncoding];
        }
        file = [[NSFileWrapper alloc] initRegularFileWithContents: data];

        [file setFilename: key];
        [file setPreferredFilename: key];

        [source addFileWrapper: [file autorelease]];
    }

    // Replace the source file wrapper
    [projectFile removeFileWrapper: [[projectFile fileWrappers] objectForKey: @"Source"]];
    [projectFile addFileWrapper: [source autorelease]];
	
	// The notes file
	NSFileWrapper* notesWrapper = [[[NSFileWrapper alloc] initRegularFileWithContents: 
		[notes RTFFromRange: NSMakeRange(0, [notes length])
		 documentAttributes: nil]] autorelease];
	
	[notesWrapper setPreferredFilename: @"notes.rtf"];
	[projectFile removeFileWrapper: [[projectFile fileWrappers] objectForKey: @"notes.rtf"]];
	[projectFile addFileWrapper: notesWrapper];

    // Setup the settings
    [projectFile setSettings: settings];
}

- (NSString*) mainSourceFile {
    if (singleFile) return mainSource;
    
    NSFileWrapper* sourceDir = [[projectFile fileWrappers] objectForKey: @"Source"];

    NSDictionary* source = [sourceDir fileWrappers];
    NSEnumerator* sourceEnum = [source keyEnumerator];
    NSString* key;

    if (mainSource) [mainSource autorelease];
    mainSource = nil;

    while (key = [sourceEnum nextObject]) {
        if ([[key pathExtension] isEqualTo: @"inf"] ||
            [[key pathExtension] isEqualTo: @"ni"]) {
            if (mainSource) [mainSource autorelease];
            mainSource = [key copy];
        }
    }

    return mainSource;
}

- (NSTextStorage*) storageForFile: (NSString*) sourceFile {
	NSTextStorage* storage;
	NSString* sourceDir = [[[self fileName] stringByAppendingPathComponent: @"Source"] stringByStandardizingPath];
	
	if (![sourceFile isAbsolutePath]) {
		// Force absolute path
		sourceFile = [[sourceDir stringByAppendingPathComponent: sourceFile] stringByStandardizingPath];
	}
	
	if ([sourceFile isAbsolutePath]) {
		// Absolute path
		if ([[[sourceFile stringByDeletingLastPathComponent] stringByStandardizingPath] isEqualToString: sourceDir]) {
			return [sourceFiles objectForKey: [sourceFile lastPathComponent]];
		}
		
		// Temporary text storage
		NSString* textData = [[NSString alloc] initWithData: [NSData dataWithContentsOfFile: sourceFile]
												   encoding: NSISOLatin1StringEncoding];
		storage = [[NSTextStorage alloc] initWithString: [textData autorelease]];
		
		NSLog(@"Using temporary storage from %@", sourceFile);
		return [storage autorelease];
	} else {
		// Not absolute path
	}
	
    return [sourceFiles objectForKey: sourceFile];
}

- (IFProjectFile*) projectFile {
    return projectFile;
}

- (NSDictionary*) sourceFiles {
    return sourceFiles;
}

- (NSString*) pathForFile: (NSString*) file {
	if ([file isAbsolutePath]) return [file stringByStandardizingPath];
	
	return [[[[self fileName] stringByAppendingPathComponent: @"Source"] stringByAppendingPathComponent: file] stringByStandardizingPath];
	
	if ([sourceFiles objectForKey: file] != nil) {
		return [[[self fileName] stringByAppendingPathComponent: @"Source"] stringByAppendingPathComponent: file];
	}
	
	// FIXME: search libraries
	
	return file;
}

- (NSTextStorage*) notes {
	return notes;
}

@end
