//
//  IFPage.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 25/03/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFProject.h"
#import "IFProjectController.h"

// Page notifications

// Notification sent by a page when it wishes to become frontmost
extern NSString* IFSwitchToPageNotification;

// Notification sent when a page wants to cause an invokation on the 'opposite' pane
extern NSString* IFOtherPaneInvokationNotification;

//
// Controller class that represents a page in a project pane
//
@protocol IFProjectPane;
@interface IFPage : NSObject {
	IFProjectController* parent;			// The project controller that 'owns' this page (not retained)
	NSObject<IFProjectPane>* otherPane;		// The pane that is opposite to this one (or nil, not retained)
	
	BOOL releaseView;						// YES if the view has been set using setView: and should be released
	IBOutlet NSView* view;					// The view to display for this page
}

// Initialising
- (id) initWithNibName: (NSString*) nib		// Designated initialiser
	 projectController: (IFProjectController*) controller;
- (void) setOtherPane: (NSObject<IFProjectPane>*) otherPane;	// Sets the pane to be considered 'opposite' to this one
- (void) finished;							// Called when the owning object has finished with this object

// Page actions
- (void) switchToPage;						// Request that the UI switches to displaying this page
- (void) switchToPageWithIdentifier: (NSString*) identifier
						   fromPage: (NSString*) oldIdentifier;	// Request that the UI switches to displaying a specific page

// Page properties
- (NSString*) title;						// The name of the tab this page appears under
- (NSString*) identifier;					// A unique identifier for this page
- (NSView*) view;							// The view that should be used to display this page
- (NSView*) activeView;						// The view that is considered to have focus for this page
- (IBOutlet void) setView: (NSView*) view;	// Sets the view to use

// Page validation
- (BOOL) shouldShowPage;					// YES if this page is valid to be shown

// TODO: page-specific toolbar items (NSCells?)

@end

#import "IFProjectPane.h"
