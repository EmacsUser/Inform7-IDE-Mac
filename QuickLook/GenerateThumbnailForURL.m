#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import "IFSyntaxStorage.h"
#import "IFNaturalHighlighter.h"
#import "IFInform6Highlighter.h"

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef cfUrl, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
	// Try to get the file that we're looking at
	NSString* fileName = nil;
	if ([(NSURL*)cfUrl isFileURL]) {
		fileName = [(NSURL*)cfUrl path];
	}
	
	if (!fileName) {
		NSLog(@"No filename");
		return noErr;
	}
	
	// Try to get the source code
	BOOL isInform6 = NO;
	NSString* sourceCodeString = nil;
	
	NSString* uti = (NSString*) contentTypeUTI;
	
	if ([uti isEqualToString: @"org.inform-fiction.source.inform7"]
		|| [uti isEqualToString: @"org.inform-fiction.inform7.extension"]) {
		// ni file
		
		sourceCodeString = [NSString stringWithContentsOfFile: fileName
													 encoding: NSUTF8StringEncoding
														error: nil];
		
	} else if ([uti isEqualToString: @"org.inform-fiction.source.inform6"]) {
		// inf file
		
		isInform6 = YES;
		sourceCodeString = [NSString stringWithContentsOfFile: fileName
													 encoding: NSUTF8StringEncoding
														error: nil];
		
	} else if ([uti isEqualToString: @"org.inform-fiction.project"]) {
		// project file
		
		isInform6 = NO;
		sourceCodeString = [NSString stringWithContentsOfFile: [[fileName stringByAppendingPathComponent: @"Source"] stringByAppendingPathComponent: @"story.ni"]
													 encoding: NSUTF8StringEncoding
														error: nil];
		
		if (sourceCodeString == nil) {
			sourceCodeString = [NSString stringWithContentsOfFile: [[fileName stringByAppendingPathComponent: @"Source"] stringByAppendingPathComponent: @"main.inf"]
														 encoding: NSUTF8StringEncoding
															error: nil];
			isInform6 = YES;
		}
		
	} else {
		NSLog(@"Unknown UTI: %@", uti);
		return noErr;
	}
	
	if (!sourceCodeString) {
		NSLog(@"No source code");
		return noErr;
	}
	
	// Create a suitable storage object and highlighter
	int length = [sourceCodeString length];
	if (length > 4096) length = 4096;
	IFSyntaxStorage* storage = [[[IFSyntaxStorage alloc] initWithString: [sourceCodeString substringToIndex: length]] autorelease];
	if (isInform6) {
		[storage setHighlighter: [[[IFInform6Highlighter alloc] init] autorelease]];
	} else {
		[storage setHighlighter: [[[IFNaturalHighlighter alloc] init] autorelease]];		
	}
	
	// Wait until it's all highlighted
	while ([storage highlighterPass]);
	
	// Produce the result
	CGSize size;
	size.width = 800;
	size.height = 840;
	CGContextRef cgContext = QLThumbnailRequestCreateContext(thumbnail, size, true, NULL);
	
	NSGraphicsContext* context = [NSGraphicsContext graphicsContextWithGraphicsPort: cgContext
																			flipped: NO];
	
	// Start drawing
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext: context];
	[context setImageInterpolation: NSImageInterpolationHigh];
	
	// Draw the background
	[NSGraphicsContext saveGraphicsState];
	NSShadow* shadow = [[NSShadow alloc] init];
	[shadow setShadowOffset: NSMakeSize(0, -7)];
	[shadow setShadowBlurRadius: 7];
	[shadow set];
	NSGradient* gradient = [[NSGradient alloc] initWithStartingColor: [NSColor colorWithDeviceRed: 0.95
																							green: 0.95
																							 blue: 0.95
																							alpha: 1.0]
														 endingColor: [NSColor whiteColor]];
	[gradient drawInRect: NSMakeRect(8,16, size.width-16, size.height - 24)
				   angle: 250];
	[gradient release];
	[shadow release];
	[NSGraphicsContext restoreGraphicsState];
	
	// Draw the source text
	[storage drawInRect: NSMakeRect(16, 24, size.width-32, size.height - 40)];
	
	// Draw 'Inform'
	NSMutableParagraphStyle* centered = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[centered setAlignment: NSCenterTextAlignment];
	[@"Inform" drawInRect: NSMakeRect(16, 32, size.width-32, 70)
		   withAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
							[NSFont boldSystemFontOfSize: 64], NSFontAttributeName,
							[NSColor colorWithDeviceRed: 0
												  green: 0
												   blue: 0
												  alpha: 0.6], NSForegroundColorAttributeName,
							centered, NSParagraphStyleAttributeName,
							nil]];
	
	// Done with the drawing
	[NSGraphicsContext restoreGraphicsState];
	
	// Finish up with the context
	QLThumbnailRequestFlushContext(thumbnail, cgContext);
	CFRelease(cgContext);
	
    return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}
