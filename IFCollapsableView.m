//
//  IFCollapsableView.m
//  Inform
//
//  Created by Andrew Hunter on 06/10/2004.
//  Copyright 2004 Andrew Hunter. All rights reserved.
//

// Based around 'ZoomCollapsableView', used by Zoom for the iFiction drawer.
// We want this for our preferences tab

#import "IFCollapsableView.h"


@implementation IFCollapsableView

#define BORDER 8.0
#define FONTSIZE 13.0

// = Init/housekeeping =

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		views = [[NSMutableArray alloc] init];
		titles = [[NSMutableArray alloc] init];
		states = [[NSMutableArray alloc] init];
		
		rearranging = NO;
		
		[self setPostsFrameChangedNotifications: YES];
    	[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(subviewFrameChanged:)
													 name: NSViewFrameDidChangeNotification
												   object: self];
	}
    return self;
}

- (void) dealloc {
	[views release];
	[titles release];
	[states release];

	[[NSNotificationCenter defaultCenter] removeObserver: self];

	[super dealloc];
}

// = Drawing =
- (BOOL) isOpaque {
	return NO;
}

- (void)drawRect:(NSRect)rect {
	NSFont* titleFont = [NSFont boldSystemFontOfSize: FONTSIZE];
	NSDictionary* titleAttributes = 
		[NSDictionary dictionaryWithObjectsAndKeys: 
			titleFont, NSFontAttributeName,
			[NSColor blackColor], NSForegroundColorAttributeName,
			nil];
	
	NSRect bounds = [self bounds];
	
	// Draw the titles and frames
	NSColor* frameColour = [NSColor colorWithDeviceRed: 0.5
												 green: 0.5
												  blue: 0.5
												 alpha: 1.0];
	
	int x;
	
	for (x=0; x<[views count]; x++) {
		NSView* thisView = [views objectAtIndex: x];
		NSString* thisTitle = [titles objectAtIndex: x];
		//BOOL visible = [[states objectAtIndex: x] boolValue];
		
		NSSize titleSize = [thisTitle sizeWithAttributes: titleAttributes];
		NSRect thisFrame = [thisView frame];
		
		float ypos = thisFrame.origin.y - (titleSize.height*1.2);
		
		// Draw the border rect
		NSRect borderRect = NSMakeRect(floorf(BORDER)+0.5, floorf(ypos)+0.5, 
									   floorf(bounds.size.width-(BORDER*2)), floorf(thisFrame.size.height + (titleSize.height * 1.2) + (BORDER)));
		[frameColour set];
		[NSBezierPath strokeRect: borderRect];
		
		// IMPLEMENT ME: draw the show/hide triangle (or maybe add this as a view?)
		
		// Draw the title
		[thisTitle drawAtPoint: NSMakePoint(BORDER*2, ypos + 2 + titleSize.height * 0.1)
				withAttributes: titleAttributes];
	}
	
	
	// Draw the rest
	[super drawRect: rect];
}

// = Management =

- (void) removeAllSubviews {
	NSView* subview;
	NSEnumerator* viewEnum = [views objectEnumerator];
	
	while (subview = [viewEnum nextObject]) {
		[subview removeFromSuperview];
	}

	[views removeAllObjects];
	[titles removeAllObjects];
	[states removeAllObjects];
	
	[self rearrangeSubviews];
}

- (void) addSubview: (NSView*) subview
		  withTitle: (NSString*) title {
	[views addObject: subview];
	[titles addObject: title];
	[states addObject: [NSNumber numberWithBool: YES]];
	
	NSRect bounds = [self bounds];
	
	// Set the width appropriately
	NSRect viewFrame = [subview frame];
	
	viewFrame.size.width = bounds.size.width - (BORDER*4);
	[subview setAutoresizingMask: NSViewWidthSizable];
	[subview setFrame: viewFrame];
	[subview setNeedsDisplay: YES];
	
	// Rearrange the views
	[self rearrangeSubviews];
	
	// Receive notifications about this view
	[subview setPostsFrameChangedNotifications: YES];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(subviewFrameChanged:)
												 name: NSViewFrameDidChangeNotification
											   object: subview];
}

- (void) rearrangeSubviews {
	reiterate = YES;
	if (rearranging) return;
	rearranging = YES;
	reiterate = NO;
	
	BOOL needsRedrawing = NO;
	
	NSRect oldBounds;
	NSRect newBounds = [self bounds];;
	
	NSEnumerator* viewEnum;
	NSView* subview;
	
	float bestWidth;
	float newHeight;
	
	NSFont* titleFont = [NSFont boldSystemFontOfSize: FONTSIZE];
	float titleHeight = [titleFont ascender] - [titleFont descender];
	
	oldBounds = newBounds;
	
	// First stage: resize all subviews to be the correct width
	bestWidth = oldBounds.size.width - (BORDER*4);
	
	viewEnum = [views objectEnumerator];
	
	while (subview = [viewEnum nextObject]) {
		NSRect viewFrame = [subview frame];
		
		if (viewFrame.size.width != bestWidth) {
			needsRedrawing = YES;
			viewFrame.size.width = bestWidth;
			[subview setFrameSize: viewFrame.size];
			[subview setNeedsDisplay: YES];
		}
	}
	
	// Second stage: calculate our new height (and resize appropriately)
	newHeight = BORDER;
	
	viewEnum = [views objectEnumerator];
	
	while (subview = [viewEnum nextObject]) {
		NSRect viewFrame = [subview frame];
		
		newHeight += titleHeight * 1.2;
		newHeight += viewFrame.size.height;
		newHeight += BORDER*2;
	}
	
	oldBounds.size.height = floor(newHeight);
	[self setFrameSize: oldBounds.size];
	
	// Loop until our width settles down
	newBounds = [self bounds];
	
	// Stage three: Position the views appropriately
	float ypos = BORDER;
	
	viewEnum = [views objectEnumerator];
	
	while (subview = [viewEnum nextObject]) {
		NSRect viewFrame = [subview frame];
		
		ypos += titleHeight * 1.2;
		
		if ([subview superview] != self) {
			if ([subview superview] != nil) [subview removeFromSuperview];
			[self addSubview: subview];
		}		
		
		if (viewFrame.origin.x != BORDER*2 ||
			viewFrame.origin.y != floor(ypos)) {
			viewFrame.origin.x = BORDER*2;
			viewFrame.origin.y = floor(ypos);
			
			[subview setFrameOrigin: viewFrame.origin];
			[subview setNeedsDisplay: YES];
			needsRedrawing = YES;
		}
		
		ypos += viewFrame.size.height;
		ypos += BORDER*2;
	}
	
	if (reiterate) {
		// Something has resized and messed up our beautiful arrangement!
		rearranging = NO;
		[self rearrangeSubviews];
		return;
	}
	
	// Final stage: tidy up, redraw if necessary
	//if (needsRedrawing) {
	[self setNeedsDisplay: YES];
	//}
	
	rearranging = NO;
}

- (BOOL) isFlipped {
	return YES;
}

- (void) subviewFrameChanged: (NSNotification*) not {
	reiterate = YES;
	if (rearranging) return;
	
	rearranging = YES;
	
	[[NSRunLoop currentRunLoop] performSelector: @selector(finishChangingFrames:)
										 target: self
									   argument: self
										  order: 32
										  modes: [NSArray arrayWithObjects: NSDefaultRunLoopMode, NSModalPanelRunLoopMode, nil]];
}

- (void) finishChangingFrames: (id) sender {
	int x;
	NSRect bounds = [self bounds];
	
	for (x=0; x<[views count]; x++) {
		NSView* view = [views objectAtIndex: x];
		NSRect viewFrame = [view frame];
		
		if (viewFrame.size.width != bounds.size.width - (BORDER*4)) {
			viewFrame.size.width = bounds.size.width - (BORDER*4);
			[view setFrame: viewFrame];
			[view setNeedsDisplay: YES];
			[self setNeedsDisplay: YES];
		}
	}
	
	rearranging = NO;
	
	[self rearrangeSubviews];
}

- (void) startRearranging {
	rearranging = YES;
}

- (void) finishRearranging {
	rearranging = NO;
	
	[self rearrangeSubviews];
}

@end
