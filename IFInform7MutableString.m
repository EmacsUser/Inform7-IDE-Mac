//
//  IFInform7MutableString.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 04/10/2009.
//  Copyright 2009 Andrew Hunter. All rights reserved.
//

#import "IFInform7MutableString.h"

///
/// I7 parser method that gives the string/comment depth at a given position
///
static void I7Parse(NSString* string, int pos, int* commentDepthOut, int* stringDepthOut, int* commentStartOut) {
	int commentDepth	= 0;
	int stringDepth		= 0;
	int commentStart	= -1;
	
	if (pos < [string length]) {
		// Iterate through the string
		int charPos;
		for (charPos = 0; charPos < pos; charPos++) {
			int chr = [string characterAtIndex: charPos];
			
			if (stringDepth == 0 && commentDepth == 0) {
				if (chr == '"') {
					// Quote characters begin a new string
					stringDepth++;
				} else if (chr == '[') {
					// '[' begins a new comment
					commentDepth++;
					commentStart = pos;
				}
			} else if (stringDepth != 0) {
				// Strings are ended by '"' characters
				if (chr == '"') {
					stringDepth--;
				}
			} else if (commentDepth != 0) {
				// Comments nest and are ended by ']' characters
				if (chr == '[') {
					commentDepth++;
				} else if (chr == ']') {
					commentDepth--;
					if (commentDepth == 0) commentStart = -1;
				}
			}
		}
	}
	
	// Update the output variables
	if (commentDepthOut)	*commentDepthOut	= commentDepth;
	if (stringDepthOut)		*stringDepthOut		= stringDepth;
	if (commentStartOut)	*commentStartOut	= commentStart;
}

@implementation NSMutableString(IFInform7MutableString)

///
/// Comments out a region in the string using Inform 7 syntax
///
- (NSRange) commentOutInform7: (NSRange) range {
	// Restrict the range to the length of the string
	if (range.location < 0 || range.location >= [self length]) {
		return range;
	}
	
	if (range.length <= 0) {
		return range;
	}
	
	int end = range.location + range.length;
	if (end > [self length]) {
		end				= [self length];
		range.length	= end - range.location;
	}
	
	// Get the original string
	int			finalPos	= range.location;
	int			finalLength = range.length;
	
	// Parse the string to the beginning of the range
	int pos = range.location;
	int stringDepth;
	int commentDepth;
	I7Parse(self, pos, &commentDepth, &stringDepth, NULL);

	// We also need to know the string depth where the close comment marker will go
	int finalStringDepth;
	I7Parse(self, pos + range.length, NULL, &finalStringDepth, NULL);
	
	if (stringDepth > 0) {
		// The user wants to comment out from the middle of a string; terminate the string
		// and comment out the remainder (this won't always result in valid syntax)
		[self insertString: @"\"[\"" 
				   atIndex: pos];
		finalLength += 3;
		pos			+= 3;
	} else if (commentDepth == 0) {
		// Starting to comment out code from outside a comment
		[self insertString: @"["
				   atIndex: pos];
		finalLength++;
		pos++;
	} else {
		// Trying to comment out from within a comment! Skip to the end of the comment.
		int x;
		for (x=0; x<range.length; x++) {
			if (commentDepth == 0) break;
			
			int chr = [self characterAtIndex: pos];
			pos++;
			if (chr == ']')	commentDepth--;
			if (chr == '[') commentDepth++;
		}
		range.length -= x;
		if (range.length <= 0) return NSMakeRange(finalPos, finalLength);

		// Insert the comment start character
		[self insertString: @"["
				   atIndex: pos];
		finalLength++;
		pos++;
	}
	
	// Add the close comment marker
	if (finalStringDepth > 0) {
		// Restart any strings that may have got commented out
		[self insertString: @"\"] \""
				   atIndex: pos + range.length];
		finalLength += 4;
	} else {
		// Just finish the comment (nesting should sort itself out if the code was valid originally)
		[self insertString: @"]"
				   atIndex: pos + range.length];
		finalLength++;
	}
	
	// Generate the final result
	return NSMakeRange(finalPos, finalLength);
}

///
/// Removes I7 comments from the specified range
///
- (NSRange) removeCommentsInform7: (NSRange) range {
	// Restrict the range to the length of the string
	if (range.location < 0 || range.location >= [self length]) {
		return range;
	}
	
	if (range.length <= 0) {
		return range;
	}
	
	int end = range.location + range.length;
	if (end > [self length]) {
		end				= [self length];
		range.length	= end - range.location;
	}
	
	// Work out the initial comment/string depth
	NSRange newRange	= range;
	int		pos			= range.location;
	int		stringDepth;
	int		commentDepth;
	I7Parse(self, pos, &commentDepth, &stringDepth, NULL);
	
	int finalCommentDepth;
	I7Parse(self, pos + range.length, &finalCommentDepth, NULL, NULL);
	
	// Close any comments that are in effect at the start of the range
	int x;
	for (x=0; x<commentDepth; x++) {
		[self insertString: @"]"
				   atIndex: pos];
		pos++;
		newRange.length++;
	}
	
	// Iterate through the string to strip out any further comments
	int newCommentDepth = 0;
	for (x=0; x<range.length; x++) {
		int chr = [self characterAtIndex: pos];
		
		if (stringDepth == 0 && commentDepth == 0) {
			if (chr == '"') {
				// Quote characters begin a new string
				stringDepth++;
			} else if (chr == '[') {
				// '[' begins a new comment
				commentDepth++;
				
				// Strip out a level of comments
				[self deleteCharactersInRange: NSMakeRange(pos, 1)];
				newRange.length--;
				pos--;
				newCommentDepth = 0;
			}
		} else if (stringDepth != 0) {
			// Strings are ended by '"' characters
			if (chr == '"') {
				stringDepth--;
			}
		} else if (commentDepth != 0) {
			// Comments nest and are ended by ']' characters
			if (chr == '[') {
				commentDepth++;
				newCommentDepth++;
			} else if (chr == ']') {
				commentDepth--;
				
				if (commentDepth == 0) {
					// Strip out a level of comments
					[self deleteCharactersInRange: NSMakeRange(pos, 1)];
					newRange.length--;
					pos--;
				} else {
					newCommentDepth--;
				}
			}
		}
		
		// Move on
		pos++;
	}
	
	// Fill in any missing comment markers
	for (x=newCommentDepth; x<finalCommentDepth; x++) {
		[self insertString: @"["
				   atIndex: pos];
		pos++;
		newRange.length++;
	}
	
	return newRange;
}

@end
