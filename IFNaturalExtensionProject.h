//
//  IFNaturalExtensionProject.h
//  Inform
//
//  Created by Andrew Hunter on 18/11/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFProjectType.h"

@class IFNaturalExtensionView;
@interface IFNaturalExtensionProject : NSObject<IFProjectType> {
	IFNaturalExtensionView* vw;
}

@end

// (This class name sounds suspiciously likes a free sample from one of those spams...)
@interface IFNaturalExtensionView : NSObject<IFProjectSetupView> {
	IBOutlet NSView* view;
	
    IBOutlet NSTextField* name;
}

- (void) setupControls;
- (NSString*) authorName;

@end