//
//  IFHeaderView.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 02/01/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFHeader.h"
#import "IFHeaderNode.h"
#import "IFHeaderController.h"

///
/// View used to allow the user to restrict the section of the source file that they are
/// browsing
///
@interface IFHeaderView : NSView {
	int displayDepth;														// The display depth for this view
	IFHeader* rootHeader;													// The root header that this view should display
	IFHeaderNode* rootHeaderNode;											// The root header node
	NSColor* backgroundColour;												// The background colour for this view
	NSString* message;														// The message to display centered in the view
	
	id delegate;															// The delegate (NOT RETAINED)
}

- (IFHeaderNode*) rootHeaderNode;											// Retrieves the root header node
- (int) displayDepth;														// Retrieves the display depth for this view
- (void) setDisplayDepth: (int) displayDepth;								// Sets the display depth for this view
- (void) setBackgroundColour: (NSColor*) colour;							// Sets the background colour for this view

- (void) setDelegate: (id) delegate;										// Sets the delegate for this view
- (void) setMessage: (NSString*) message;									// Sets the message to use in this view

@end

@interface NSObject(IFHeaderViewDelegate)

- (void) headerView: (IFHeaderView*) view									// Indicates that a header node has been clicked on
	  clickedOnNode: (IFHeaderNode*) node;

@end