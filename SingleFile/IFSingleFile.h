//
//  IFSingleFile.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 23/06/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFSyntaxStorage.h"

//
// Extensions and other lone files are stored by this document class.
//
// Previous versions used the project class for this, but this did not provide a good interface
// for files that can't sensibly be compiled.
//
@interface IFSingleFile : NSDocument {
	IFSyntaxStorage* fileStorage;						// The contents of the file
	NSStringEncoding fileEncoding;						// The encoding used for the file
}

// Retrieving document data
- (IFSyntaxStorage*) storage;							// The contents of the file
- (BOOL) isReadOnly;									// YES if this file is read-only

@end
