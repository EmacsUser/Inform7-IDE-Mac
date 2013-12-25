//
//  IFGlkResources.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 29/08/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GlkView/GlkView.h>


///
/// Class that retrieves Glk resources from the materials directory
///
@interface IFGlkResources : NSObject<GlkImageSource> {
	NSDocument* project;
	NSDictionary* manifest;
}

- (id) initWithProject: (NSDocument*) project;					// Initialise this resource file to get image resources from the specified project

@end
