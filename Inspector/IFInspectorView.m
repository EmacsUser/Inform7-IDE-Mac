//
//  IFInspectorView.m
//  Inform
//
//  Created by Andrew Hunter on Mon May 03 2004.
//  Copyright (c) 2004 Andrew Hunter. All rights reserved.
//

#import "IFInspectorView.h"

#define TitleHeight 20
#define ViewOffset  20
#define ViewPadding 1

@implementation IFInspectorView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		innerView = nil;
		
		arrow = [[IFIsArrow alloc] initWithFrame: NSMakeRect(0, -4, 24, 28)];
		[self addSubview: arrow];
		[arrow sizeToFit];
		
		willLayout = NO;
		
		titleView = [[IFIsTitleView alloc] initWithFrame: NSMakeRect(0, 0, frame.size.width, TitleHeight)];
		[titleView setTitle: @"Untitled"];
		
		[self setAutoresizesSubviews: NO];
		[titleView setAutoresizingMask: NSViewWidthSizable];
		[arrow setAutoresizingMask: NSViewMaxYMargin];
		
		[arrow setTarget: self];
		[arrow setAction: @selector(openChanged:)];
		
		[self addSubview: titleView];
		[self addSubview: arrow];
    }
    return self;
}

- (void) dealloc {
	if (innerView) [innerView release];
	
	[arrow release];
	[titleView release];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
	[super dealloc];
}

// = The view =

- (void) setTitle: (NSString*) title {
	[titleView setTitle: title];
}

- (void) setView: (NSView*) view {
	if (innerView) {
		[[NSNotificationCenter defaultCenter] removeObserver: self
														name: NSViewFrameDidChangeNotification
													  object: innerView];
		[innerView removeFromSuperview];
		[innerView release];
	}
	
	[innerView setPostsFrameChangedNotifications: YES];
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(innerSizeChanged:)
												 name: NSViewFrameDidChangeNotification
											   object: innerView];
	
	innerView = [view retain];
	[self queueLayout];
}

- (NSView*) view {
	return innerView;
}

- (void) innerSizeChanged: (NSNotification*) not {
	if ([arrow intValue] == 3) {
		[self queueLayout];
	}
}

- (void) queueLayout {
	if (!willLayout) {
		[[NSRunLoop currentRunLoop] performSelector: @selector(layoutViews)
											 target: self
										   argument: nil
											  order: 64
											  modes: [NSArray arrayWithObjects: NSDefaultRunLoopMode, NSModalPanelRunLoopMode, nil]];
		willLayout = YES;
	}
}

- (void) layoutViews {
	willLayout = NO;
	
	switch ([arrow intValue]) {
		case 1:
		case 2:
			// Closed
			if ([innerView superview] != nil)
				[innerView removeFromSuperview];
			
			NSRect ourFrame = [self frame];
			ourFrame.size.height = TitleHeight;
			[self setFrame: ourFrame];
			[self setNeedsDisplay: YES];
			break;
			
		case 3:
		{
			// Open
			NSRect bounds = [self bounds];
			NSRect newFrame = [self frame];
			NSRect oldFrame = newFrame;
			
			NSRect innerFrame = bounds;
			
			innerFrame.size.height = [innerView frame].size.height;
			innerFrame.origin.y += ViewOffset;
			newFrame.size.height = innerFrame.size.height + ViewOffset + ViewPadding;

			if ([innerView superview] != self) {
				[innerView removeFromSuperview];
			
				[innerView setFrame: innerFrame];
				[self addSubview: innerView
					  positioned: NSWindowBelow
					  relativeTo: titleView];
			}
			
			if (!NSEqualRects(newFrame, oldFrame)) {
				[self setFrame: newFrame];
			}
			
			// [self setNeedsDisplay: YES];
			break;
		}
	}
}

- (void) openChanged: (id) sender {
	[self queueLayout];
}

- (void) mouseUp: (NSEvent*) evt {
	// Clicking in the title will open the view if it's not already (you need to use the arrow to close it, though)
	if ([arrow intValue] != 3) {
		[arrow setIntValue: 3];
		[self queueLayout];
	} else {
		[arrow setIntValue: 1];
		[self queueLayout];
	}
}

// = Drawing =
- (void)drawRect:(NSRect)rect {
#if ViewPadding > 0
	NSRect bounds = [self bounds];
	
	[[NSColor windowFrameColor] set];
	[NSBezierPath strokeLineFromPoint: NSMakePoint(NSMinX(bounds), NSMaxY(bounds)-0.5)
							  toPoint: NSMakePoint(NSMaxX(bounds), NSMaxY(bounds)-0.5)];
#endif
}

- (BOOL) isFlipped {
	return YES;
}

- (BOOL) isOpaque {
	return NO;
}

- (void) setExpanded: (BOOL) isExpanded {
	[arrow setOpen: isExpanded];
	[self layoutViews];
}

- (BOOL) expanded {
	return [arrow intValue] == 3;
}

@end
