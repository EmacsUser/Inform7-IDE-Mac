//
//  IFRandomSettings.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 17/09/2009.
//  Copyright 2009 Andrew Hunter. All rights reserved.
//

#import "IFRandomSettings.h"


@implementation IFRandomSettings

- (id) init {
	return [self initWithNibName: @"RandomSettings"];
}

- (NSString*) title {
	return [[NSBundle mainBundle] localizedStringForKey: @"Randomness Settings"
												  value: @"Randomness Settings"
												  table: nil];
}

// = Setting up =

- (void) updateFromCompilerSettings {
    IFCompilerSettings* settings = [self compilerSettings];
	
	[makePredictable setState: [settings nobbleRng]?NSOnState:NSOffState];
}

- (void) setSettings {
    IFCompilerSettings* settings = [self compilerSettings];
	
	[settings setNobbleRng: [makePredictable state] == NSOnState];
}

- (BOOL) enableForCompiler: (NSString*) compiler {
	// These settings only apply to Natural Inform
	if ([compiler isEqualToString: IFCompilerNaturalInform])
		return YES;
	else
		return NO;
}

@end
