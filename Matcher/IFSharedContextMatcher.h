//
//  IFSharedContextMatcher.h
//  Inform-xc2
//
//  Created by Andrew Hunter on 01/07/2007.
//  Copyright 2007 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "IFContextMatcher.h"

@interface IFSharedContextMatcher : IFContextMatcher {

}

+ (IFSharedContextMatcher*) matcherForInform7;			// The shared context matcher
+ (IFSharedContextMatcher*) matcherForInform6;			// The shared context matcher

- (void) build: (BOOL) inform7;							// (Re)builds the matcher from the standard XML files

@end
