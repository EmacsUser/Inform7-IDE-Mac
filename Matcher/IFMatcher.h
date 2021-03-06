//
//  IFMatcher.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 26/06/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ndfa.h"

///
/// Class for lexing regular expressions
///
@interface IFMatcher : NSObject<NSCopying> {
	NSLock*		matcherLock;						// Lock used to allow us to compile the NDFA in the background
	
	ndfa		nfa;								// Lexer in the process of being built
	ndfa		dfa;								// Lexer that's ready to run
	
	NSMutableArray* results;						// Array of objects that can be results

	NSMutableDictionary* namedRegexps;				// Array of named regular expressions
		
	// TODO: could put these in an independent class to make this class completely thread-safe
	NSString* matchString;							// The string currently being matched against
	int matchPosition;								// Position of the last known match (while match is running)
	id matchDelegate;								// The delegate passed to the matcher function
	BOOL continueMatching;							// YES while we should continue performing matches
	BOOL caseSensitive;								// If NO, then the string is made into lower case before matching
	
	NSArray* lastMatch;								// The last match we made
	NSRange lastMatchRange;							// The range of the last match
}

// Initialisation
- (id) initWithMatcher: (IFMatcher*) matcher;		// Builds a clone of this matcher (so subclasses can implement NSCopying)

// Building the lexer
- (void) clear;										// Clears this matcher
- (void) addNamedExpression: (NSString*) regexp		// Adds a new named expression to the lexer
				   withName: (NSString*) name;
- (void) addExpression: (NSString*) regexp			// Adds a new regular expression to the lexer
			withObject: (NSObject*) result;
- (void) compileLexer;								// Starts compiling the lexer in the background, ready for later use

// Running the lexer
- (void) match: (NSString*) string					// Runs the lexer against a specific string
  withDelegate: (id) lexDelegate;
- (void) setCaseSensitive: (BOOL) isCaseSensitive;	// If isCaseSensitive is NO, then all the string is changed to lowercase before matching

- (BOOL) nextMatchFromString: (NSString*) string	// Finds the next match of in the specified string without using a delegate
				 searchRange: (NSRange) range
					  result: (NSArray**) result
				 resultRange: (NSRange*) resultRange;

@end

@interface NSObject(IFMatcherDelegate)

- (BOOL) match: (NSArray*) match					// Reports a match on on the specified string. Should return YES to continue matching, or NO to abandon the parse here
	  inString: (NSString*) matchString
		 range: (NSRange) range;

@end
