//
//  IFHeaderView.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 02/01/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import "IFHeaderView.h"


@implementation IFHeaderView

// = Initialisation =

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		displayDepth = 5;
		backgroundColour = [[NSColor whiteColor] copy];
    }
    return self;
}

- (void) dealloc {
	[rootHeader release];		rootHeader = nil;
	[backgroundColour release];	backgroundColour = nil;
	[message release];			message = nil;
	
	[editNode release];			editNode = nil;
	[editStorage release];		editStorage = nil;
	[editor release];			editor = nil;
	
	[super dealloc];
}

// = Information about this view =

- (IFHeaderNode*) rootHeaderNode {
	return rootHeaderNode;
}

// = Updating the view =

- (void) sizeView {
	// Resize the view
	NSRect rootFrame = [rootHeaderNode frame];
	rootFrame.size.width = [self frame].size.width;
	rootFrame.size.height += 5;
	
	if (message && [self enclosingScrollView]) {
		rootFrame.size = [[self enclosingScrollView] contentSize];
		[self setAutoresizingMask: [self autoresizingMask] | NSViewHeightSizable];
	} else {
		[self setAutoresizingMask: [self autoresizingMask] & ~NSViewHeightSizable];
	}
	
	[self setFrameSize: rootFrame.size];
}

- (void) updateFromRoot {
	// Replace the root header node
	[rootHeaderNode release]; rootHeaderNode = nil;
	rootHeaderNode = [[IFHeaderNode alloc] initWithHeader: rootHeader
												 position: NSMakePoint(0,0)
													depth: 0];
	[rootHeaderNode populateToDepth: displayDepth];
	
	// Add a message if necessary
	if ([[rootHeaderNode children] count] == 0) {
		if ([[rootHeader children] count] == 0) {
			[self setMessage: [[NSBundle mainBundle] localizedStringForKey: @"NoHeadingsSet"
																	 value: @""
																	 table: nil]];
		} else {
			[self setMessage: [[NSBundle mainBundle] localizedStringForKey: @"NoHeadingsVisible"
																	 value: @""
																	 table: nil]];
		}
	} else {
		message = nil;
	}
	
	// Redraw the display
	[self sizeView];
	[self setNeedsDisplay: YES];	
}

- (void) setMessage: (NSString*) newMessage {
	[message release];
	if ([newMessage length] == 0) newMessage = nil;
	message = [newMessage copy];
	
	[self sizeView];
	[self setNeedsDisplay: YES];
}

// = Settings for this view =

- (BOOL) isFlipped {
	return YES;
}

- (int) displayDepth {
	return displayDepth;
}

- (void) setDisplayDepth: (int) newDisplayDepth {
	// Set the display depth for this view
	displayDepth = newDisplayDepth;
	
	// Refresh the view
	[self updateFromRoot];
}


- (void) setDelegate: (id) newDelegate {
	delegate = newDelegate;
}

- (void) setBackgroundColour: (NSColor*) colour {
	[backgroundColour release];
	backgroundColour = [colour copy];
}

// = Drawing =

- (void)drawRect:(NSRect)rect {
	// Draw the background
	[backgroundColour set];
	NSRectFill(rect);
	
	// Draw the message, if any
	if (message) {
		// Get the style for the message
		NSMutableParagraphStyle* style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
		[style setAlignment: NSCenterTextAlignment];
		
		NSDictionary* messageAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
										   [NSFont systemFontOfSize: 12], NSFontAttributeName,
										   style, NSParagraphStyleAttributeName, 
										   nil];
		
		// Draw roughly centered
		NSRect bounds = [self bounds];
		NSRect textBounds = NSInsetRect(bounds, 8, 8);
		textBounds.origin.y = NSMinY(bounds) + 8;
		textBounds.size.height = NSMaxY(bounds) - NSMinY(textBounds);
		
		[message drawInRect: textBounds
			 withAttributes: messageAttributes];
	} else {
		// Draw the nodes
		[rootHeaderNode drawNodeInRect: rect
							 withFrame: [self bounds]];
	}
}

// = Messages from the header controller =

- (void) refreshHeaders: (IFHeaderController*) controller {
	// Get the root header from the controller
	[rootHeader release]; rootHeader = nil;
	rootHeader = [[controller rootHeader] retain];
	
	// Update this control
	[self updateFromRoot];
	
	if (delegate && [delegate respondsToSelector:@selector(refreshHeaders:)]) {
		[delegate refreshHeaders: controller];
	}
}

// = Editing events =

- (void) editHeaderNode: (IFHeaderNode*) node 
			 mouseEvent: (NSEvent*) mouseDown {
	// Stop editing the previous node
	[editNode setEditing: NO];
	[editNode setSelectionStyle: IFHeaderNodeUnselected];
	[editNode autorelease];
	editNode = nil;
	
	// Don't edit the title node
	if ([[node header] parent] == nil) return;
	
	// Start editing the next node
	editNode = [node retain];
	[editNode setSelectionStyle: IFHeaderNodeInputCursor];
	[editNode setEditing: YES];
	
	[self setNeedsDisplay: YES];
	
	// Work out the bounding box of the area to be edited
	NSRect headerNameRect = [node headerTitleRect];
	NSRect bounds = [self bounds];
	headerNameRect.size.width = NSMaxX(bounds) - NSMinX(headerNameRect);
	
	// Assign the field editor to ourselves
	[editor autorelease];
	editor = (NSTextView*)[[self window] fieldEditor: YES
										   forObject: node];
	[editor retain];
	
	// Set up the editor storage (twice, as for some reason the field editor blanks out if we only set it once)
	if (!editStorage) editStorage = [[NSTextStorage alloc] init];
	[editStorage setAttributedString: [node attributedTitle]];
	[[editor layoutManager] replaceTextStorage: editStorage];
	
	// Set up the field editor
	NSColor* bgColour = [editNode textBackgroundColour];
	if (!bgColour) bgColour = backgroundColour;
	
	[editor setSelectedRange: NSMakeRange(0,0)];
	[editor setDelegate: self];
	[editor setRichText: NO];
	[editor setAllowsDocumentBackgroundColorChange: NO];
	[editor setBackgroundColor: bgColour];
	[editor setHorizontallyResizable: NO];
	[editor setVerticallyResizable: YES];
	[editor setTextContainerInset: NSMakeSize(0, 0)];
	
	[[editor textContainer] setContainerSize: headerNameRect.size];
	[[editor textContainer] setWidthTracksTextView: NO];
	[[editor textContainer] setHeightTracksTextView: NO];
	[editor setDrawsBackground: NO];
	[editor setTypingAttributes: [editNode attributes]];
	[[editor textContainer] setLineFragmentPadding: 0];
	
	// Add the field editor
	[editor removeFromSuperview];
	[editor setFrame: headerNameRect];
	[self addSubview: editor];
	[[self window] makeFirstResponder: editor];
	
	// Set up the editor storage again
	[editStorage setAttributedString: [node attributedTitle]];
	[[editor layoutManager] replaceTextStorage: editStorage];
	
	// [[editor textStorage] setAttributedString: [node attributedTitle]];
	
	if (mouseDown) [editor mouseDown: mouseDown];
}

// = Mouse events =

- (void) mouseDown: (NSEvent*) evt {
	// Get the position where the mouse was clicked
	NSPoint viewPos = [self convertPoint: [evt locationInWindow]
								fromView: nil];
	
	// Get which node was clicked on
	IFHeaderNode* clicked = [rootHeaderNode nodeAtPoint: viewPos];

	NSRect headerNameRect = [clicked headerTitleRect];
	if (NSPointInRect(viewPos, headerNameRect)) {
		// Start editing the node
		[self editHeaderNode: clicked
				  mouseEvent: evt];
	} else {
		// Inform the delegate that the header has been clicked
		if (clicked && delegate && [delegate respondsToSelector: @selector(headerView:clickedOnNode:)]) {
			[delegate headerView: self
				   clickedOnNode: clicked];
		}
	}
}

// = Field editor delegate events =

- (void) textDidEndEditing: (NSNotification*) aNotification {
	NSLog(@"Finished editing");
	
	// Finished with the edit node
	[editNode setEditing: NO];
	[editNode setSelectionStyle: IFHeaderNodeUnselected];
	[editNode autorelease];
	editNode = nil;
	
	// Finished with the field editor
	[editor removeFromSuperview];
	[editor autorelease];
	editor = nil;
	
	[self setNeedsDisplay: YES];
}


@end
