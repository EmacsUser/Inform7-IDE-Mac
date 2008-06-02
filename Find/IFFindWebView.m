//
//  IFFindWebView.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 23/02/2008.
//  Copyright 2008 Andrew Hunter. All rights reserved.
//

#import "IFFindWebView.h"


@implementation WebView(IFFindWebView)

// = Basic interface =

- (BOOL) findNextMatch:	(NSString*) match
				ofType: (IFFindType) type {
	BOOL insensitive = (type&IFFindCaseInsensitive)!=0;

	return [self searchFor: match
				 direction: YES
			 caseSensitive: !insensitive
					  wrap: YES];
}

- (BOOL) findPreviousMatch: (NSString*) match
					ofType: (IFFindType) type {
	BOOL insensitive = (type&IFFindCaseInsensitive)!=0;
	
	return [self searchFor: match
				 direction: NO
			 caseSensitive: !insensitive
					  wrap: YES];
}

- (BOOL) canUseFindType: (IFFindType) find {
	switch (find) {
		case IFFindContains:
			return YES;
			
		case IFFindBeginsWith:
		case IFFindCompleteWord:
		case IFFindRegexp:
		default:
			return NO;
	}
}

- (NSString*) currentSelectionForFind {
	return [[self selectedDOMRange] toString];
}

// = 'Find all' =

/*
- (NSArray*) findAllMatches: (NSString*) match
					 ofType: (IFFindType) type
		   inFindController: (IFFindController*) controller
			 withIdentifier: (id) identifier {
}

- (void) highlightFindResult: (IFFindResult*) result {
}
*/

@end
