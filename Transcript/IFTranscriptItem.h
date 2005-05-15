//
//  IFTranscriptItem.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 10/05/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <ZoomView/ZoomSkeinItem.h>

//
// Corresponds to an individual transcript item.
//
// I imagine a large game might end up trying to display ~2000 of these, so we need to be able to handle that
// in a reasonable manner. It would be nice if there was a sensible way to use the layout manager without also
// needing an NSTextView, but that's (apparently) not really possible. Maybe ~6000 textviews is doable, but it
// doesn't sound likely to me.
//
// Annoyingly, Tiger has a mechanism for doing exactly what we're doing with the transcripts. Unfortunately,
// not everyone has Tiger. All Inform code must run OK on Panther at least.
//
@interface IFTranscriptItem : NSObject {
	// Item data
	ZoomSkeinItem* skeinItem;				// The skein item associated with this item
	
	NSString* command;						// Command that precedes this item (may be nil)
	NSTextStorage* transcript;				// The actual transcript from the game (not editable)
	NSTextStorage* expected;				// 'Expected' or 'comment' text (editable)
	
	NSDictionary* attributes;				// Font, etc that this item will use
	
	BOOL played;							// Whether or not this item has been played
	BOOL changed;							// Whether or not this item has changed since the last play through
	
	// View data
	float width;							// Width of the view that contains this item
	float offset;							// Offset of this item from the top
	
	// Calculated data
	int textEquality;						// -1 if empty, 0 if not equal, 1 if equal except for whitespace, 2 if exactly equal
	
	BOOL calculated;						// YES if the various calculations are up to date
	float textHeight;						// Height of the text this item contains
	float height;							// Height of this item
	
	NSTextContainer* transcriptContainer;	// Container for the transcript
	NSTextContainer* expectedContainer;		// Container for the 'expected' text
	
	// Field editing
	NSTextView* fieldEditor;				// The field editor for this item
	
	// Delegate
	id delegate;							// Delegate for this item (not retained)
}

// Setting the item data
- (void) setSkeinItem: (ZoomSkeinItem*) item;					// Sets the skein item associated with this node

- (void) setCommand: (NSString*) command;						// Command that precedes this item (may be nil)
- (void) setTranscript: (NSString*) transcript;					// The actual transcript from the game (not editable)
- (void) setExpected: (NSString*) expected;						// 'Expected' or 'comment' text (editable)

- (void) setPlayed: (BOOL) played;								// Whether or not this item has been played in the story
- (void) setChanged: (BOOL) changed;							// Whether or not this item changed on this run through

- (void) setAttributes: (NSDictionary*) attributes;				// Set the attributes used for display

- (ZoomSkeinItem*) skeinItem;									// Retrieves the skein item associated with this node
- (NSDictionary*) attributes;									// Retrieves the attributes used for display

// Setting the data from the view
- (void) setWidth: (float) newWidth;							// Total width of the view
- (void) setOffset: (float) offset;								// Offset from the top

- (float) offset;												// Offset from the top

// Calculating the height of this item
- (void) calculateItem;											// Calculates the data associated with this transcript item
- (BOOL) calculated;											// YES if the calculations for this item are up to date
- (float) height;												// The height of this item
- (float) textHeight;											// The height of the text for this item

// (UI stuff below)

// Drawing
- (void) drawAtPoint: (NSPoint) point;							// Draws this transcript item at the given location

// Field editing
- (void) setupFieldEditor: (NSTextView*) fieldEditor			// Sets up a field editor for changing the left or right-hand side of the transcript
			  forExpected: (BOOL) editExpected
				  atPoint: (NSPoint) itemOrigin;

- (void) setDelegate: (id) delegate;							// Sets the delegate for this item (delegate is NOT retained)

@end

@interface NSObject(IFTranscriptItemDelegate)

- (void) transcriptItemHasChanged: (IFTranscriptItem*) sender;	// Called when an item changes for some reason (eg, due to the field editor)

@end
