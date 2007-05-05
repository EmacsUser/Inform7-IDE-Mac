//
//  IFPageBarCell.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 06/04/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import "IFPageBarCell.h"
#import "IFPageBarView.h"

@implementation IFPageBarCell

+ (NSImage*) dropDownImage {
	NSImage* image = nil;
	
	if (!image) {
		image = [[NSImage imageNamed: @"BarMenuArrow"] retain];
	}
	
	return image;
}

// = Initialisation =

- (id) init {
	self = [super init];
	
	if (self) {
		radioGroup = -1;
		view = nil;
	}
	
	return self;
}

- (id) initTextCell: (NSString*) text {
	self = [self init];
	
	if (self) {
		NSAttributedString* attrText = [[NSAttributedString alloc] initWithString: text
																	   attributes: 
			[NSDictionary dictionaryWithObjectsAndKeys: 
				[[NSColor controlTextColor] colorWithAlphaComponent: 0.8], NSForegroundColorAttributeName,
				[NSFont systemFontOfSize: 11], NSFontAttributeName,
				nil]];
		
		[self setAttributedStringValue: attrText];
		[attrText release];
	}
	
	return self;
}

- (id) initImageCell: (NSImage*) image {
	self = [self init];
	
	if (self) {
		[self setImage: image];
	}
	
	return self;
}

- (void) dealloc {
	[menu release]; menu = nil;
	[view release]; view = nil;
	[identifier release]; identifier = nil;
	[keyEquivalent release]; keyEquivalent = nil;
	
	[super dealloc];
}

- (void) setIdentifier: (id) newIdentifier {
	[identifier release];
	identifier = [newIdentifier retain];
}

- (id) identifier {
	return identifier;
}

- (void) setStringValue: (NSString*) text {
	NSAttributedString* attrText = [[NSAttributedString alloc] initWithString: text
																   attributes: 
		[NSDictionary dictionaryWithObjectsAndKeys: 
			[[NSColor controlTextColor] colorWithAlphaComponent: 0.8], NSForegroundColorAttributeName,
			[NSFont systemFontOfSize: 11], NSFontAttributeName,
			nil]];
	
	[self setAttributedStringValue: attrText];
	[attrText release];	
}

// = Cell properties =

- (void) update {
	[(NSControl*)[self controlView] updateCell: self];
}

- (BOOL) isHighlighted {
	return isHighlighted;
}

- (void) setHighlighted: (BOOL) highlighted {
	isHighlighted = highlighted;
	[self update];
}

// = Sizing and rendering =

- (void) setIsRight: (BOOL) newIsRight {
	isRight = newIsRight;
}

- (NSSize) cellSize {
	NSSize size = NSZeroSize;

	// Work out the minimum size required to contain the text or the image
	NSImage* image = [self image];
	NSAttributedString* text = [self attributedStringValue];
	
	if (image) {
		size = [image size];
		size.width += 4;
	} else if (text) {
		size = [text size];
		size.width += 4;
	}
	
	if ([self isPopup]) {
		NSImage* dropDownArrow = [IFPageBarCell dropDownImage];
		size.width += [dropDownArrow size].width + 4;
	}
	
	// Add a border for the margins
	size.width += 8;
	size.width = floorf(size.width+0.5);
	size.height = floorf(size.height);
	
	return size;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame 
					   inView:(NSView *)controlView {
	NSImage* image = [self image];
	NSAttributedString* text = [self attributedStringValue];
	
	// Draw the background
	NSImage* backgroundImage = nil;
	
	if (isHighlighted) {
		if ([self isPopup]) {
			backgroundImage = [IFPageBarView graphiteSelectedImage];
		} else {
			backgroundImage = [IFPageBarView highlightedImage];
		}
	} else if ([self state] == NSOnState) {
		backgroundImage = [IFPageBarView selectedImage];
	}
	
	if (backgroundImage) {
		IFPageBarView* barView = (IFPageBarView*)[self controlView];
		NSRect backgroundBounds = [barView bounds];
		backgroundBounds.size.width -= 9.0;
		
		NSRect backgroundFrame = cellFrame;
		if (isRight) {
			backgroundFrame.origin.x += 1;
			backgroundFrame.size.width -= 1;
		} else {
			backgroundFrame.size.width -= 1;			
		}

		[IFPageBarView drawOverlay: backgroundImage
							inRect: backgroundFrame
					   totalBounds: backgroundBounds
						  fraction: 1.0];
	}
	
	if ([self isPopup]) {
		// Draw the popup arrow
		NSImage* dropDownArrow = [IFPageBarCell dropDownImage];
		NSSize dropDownSize = [dropDownArrow size];
		
		NSRect dropDownRect = NSMakeRect(0,0, dropDownSize.width, dropDownSize.height);
		NSRect dropDownDrawRect;
		
		dropDownDrawRect.origin = NSMakePoint(NSMaxX(cellFrame) - dropDownSize.width - 6,
											  cellFrame.origin.y + (cellFrame.size.height+2-dropDownSize.height)/2);
		dropDownDrawRect.size = dropDownSize;
		
		if (isRight) dropDownDrawRect.origin.x += 2;
		
		[dropDownArrow drawInRect: dropDownDrawRect
						 fromRect: dropDownRect
						operation: NSCompositeSourceOver
						 fraction: 1.0];
		
		// Reduce the frame size
		cellFrame.size.width -= dropDownSize.width+4;
	}
	
	if (image) {
		// Draw the image
		NSSize imageSize = [image size];
		NSRect imageRect;
		
		imageRect.origin = NSMakePoint(cellFrame.origin.x + (cellFrame.size.width-imageSize.width)/2,
									   cellFrame.origin.y + (cellFrame.size.height+2-imageSize.height)/2);
		imageRect.size = imageSize;
		
		[image drawInRect: imageRect
				 fromRect: NSMakeRect(0,0, imageSize.width, imageSize.height)
				operation: NSCompositeSourceOver
				 fraction: 1.0];
	} else if (text) {
		// Draw the text
		NSSize textSize = [text size];
		NSPoint textPoint = NSMakePoint(cellFrame.origin.x + (cellFrame.size.width-textSize.width)/2,
										cellFrame.origin.y + (cellFrame.size.height+2-textSize.height)/2);
		
		if (isRight) textPoint.x += 1;

		NSRect textRect;
		textRect.origin = textPoint;
		textRect.size = textSize;
		
		[text drawInRect: NSIntegralRect(textRect)];
	}
}

// = Cell states =

- (int) nextState {
	// Radio cells can be turned on (but get turned off manually)
	if (radioGroup >= 0) {
		return NSOnState;
	}
	
	// TODO: allow for push-on/push-off cells
	return NSOffState;
}

- (void) setState: (int) newState {
	if (newState == [self state]) {
		return;
	}
	
	[super setState: newState];
	[self update];
	
	if (radioGroup >= 0) {
		[(IFPageBarView*)[self controlView] setState: newState
											 forCell: self];
	}
}

- (BOOL) isEnabled {
	if (menu) {
		if ([menu numberOfItems] <= 0) return NO;
	}
	
	return [super isEnabled];
}


// = Acting as part of a radio group =

- (void) setRadioGroup: (int) group {
	radioGroup = group;
}

- (int) radioGroup {
	return radioGroup;
}
	
// = Acting as a tab =

- (void) setView: (NSView*) newView {
	if (view) [view release];
	view = [newView retain];
}

- (NSView*) view {
	return view;
}

// = Acting as a pop-up =

- (BOOL) isPopup {
	if (menu) return YES;
	
	return NO;
}

- (void) showPopupAtPoint: (NSPoint) pointInWindow {
	if (menu) {
		[self setState: NSOnState];
		isHighlighted = YES;
		[self update];
		
		NSEvent* fakeEvent = [NSEvent mouseEventWithType: NSLeftMouseDown
												location: pointInWindow
										   modifierFlags: 0
											   timestamp: [[NSApp currentEvent] timestamp]
											windowNumber: [[[self controlView] window] windowNumber]
												 context: [[[self controlView] window] graphicsContext]
											 eventNumber: [[NSApp currentEvent] eventNumber]
											  clickCount: 0
												pressure: 1.0];
		
		[NSMenu popUpContextMenu: menu
					   withEvent: fakeEvent
						 forView: [self controlView]
						withFont: [NSFont systemFontOfSize: 11]];
		
		[self setState: NSOffState];
		[self update];
	}
}

- (void) setMenu: (NSMenu*) newMenu {
	[menu release];
	menu = [newMenu retain];
	[self update];
}

// = Tracking =

- (BOOL)trackMouse:(NSEvent *)theEvent
			inRect:(NSRect)cellFrame 
			ofView:(NSView *)controlView 
	  untilMouseUp:(BOOL)untilMouseUp {
	trackingFrame = cellFrame;
	
	if ([self isPopup]) {
		NSRect winFrame = [[self controlView] convertRect: trackingFrame
												   toView: nil];
		[self showPopupAtPoint: NSMakePoint(NSMinX(winFrame)+1, NSMinY(winFrame)-3)];
		
		isHighlighted = NO;
		[self update];
		
		return YES;
	}
	
	BOOL result = [super trackMouse: theEvent
							 inRect: cellFrame
							 ofView: controlView
					   untilMouseUp: untilMouseUp];
	
	if (result) {
		// Tracking was successful
		if (radioGroup >= 0) {
			
		}
	}
	
	return result;
}

- (BOOL)startTrackingAt: (NSPoint)startPoint 
				 inView: (NSView*)controlView {
	isHighlighted = YES;
	[self update];
	
	// TODO: if this is a menu or pop-up cell, only send the action when the user makes a selection
	// [self sendActionOn: 0];
	
	return YES;
}

- (BOOL)continueTracking:(NSPoint)lastPoint
					  at:(NSPoint)currentPoint 
				  inView:(NSView *)controlView {
	BOOL shouldBeHighlighted;
	
	shouldBeHighlighted = NSPointInRect(currentPoint, 
										trackingFrame);
	if (shouldBeHighlighted != isHighlighted) {
		isHighlighted = shouldBeHighlighted;
		[self update];
	}
	
	return YES;
}

- (void)stopTracking:(NSPoint)lastPoint 
				  at:(NSPoint)stopPoint
			  inView:(NSView *)controlView 
		   mouseIsUp:(BOOL)flag {
	isHighlighted = NO;
	[self update];

	return;
}

// = Key equivalent =

- (NSString*) keyEquivalent {
	if (keyEquivalent == nil) return @"";
	return keyEquivalent;
}

- (void) setKeyEquivalent: (NSString*) newKeyEquivalent {
	[keyEquivalent release];
	keyEquivalent = [newKeyEquivalent copy];
}

@end
