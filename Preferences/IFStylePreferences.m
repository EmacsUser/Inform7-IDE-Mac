//
//  IFStylePreferences.m
//  Inform
//
//  Created by Andrew Hunter on 01/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import "IFStylePreferences.h"

#import "IFSyntaxStorage.h"
#import "IFNaturalHighlighter.h"

#import "IFPreferences.h"

@implementation IFStylePreferences

- (id) init {
	self = [super initWithNibName: @"StylePreferences"];
	
	if (self) {
		[self reflectCurrentPreferences];
		
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(reflectCurrentPreferences)
													 name: IFPreferencesDidChangeNotification
												   object: [IFPreferences sharedPreferences]];
		
		// Switch the preview with a IFInform6Highlighter
		NSTextStorage* oldStorage = [previewView textStorage];
		previewStorage = [[IFSyntaxStorage alloc] initWithString: [oldStorage string]];
		
		[previewStorage setHighlighter: [[[IFNaturalHighlighter alloc] init] autorelease]];
		
		[oldStorage removeLayoutManager: [previewView layoutManager]];
		[previewStorage addLayoutManager: [previewView layoutManager]];
	}
	
	return self;
}

// = PreferencePane overrides =

- (NSString*) preferenceName {
	return @"Styles";
}

- (NSImage*) toolbarImage {
	return [NSImage imageNamed: @"Styles"];
}

- (NSString*) tooltip {
	return [[NSBundle mainBundle] localizedStringForKey: @"Style preferences tooltip"
												  value: @"Style preferences tooltip"
												  table: nil];
}

// = Receiving data from/updating the interface =

- (float) fontSizeForTag: (int) tag {
	switch (tag) {
		case 0:
			return 1.0;
		case 1:
			return 1.25;
		case 2:
			return 1.5;
		case 3:
			return 2.5;
	}
	
	return 1.0;
}

- (int) tagForFontSize: (float) fontSize {
	if (fontSize >= 2.5)
		return 3;
	else if (fontSize >= 1.5)
		return 2;
	else if (fontSize >= 1.25)
		return 1;
	else
		return 0;
}

- (IBAction) styleSetHasChanged: (id) sender {
	IFPreferences* prefs = [IFPreferences sharedPreferences];
	
	if (sender == fontSet)			[prefs setFontSet:			[[fontSet selectedItem] tag]];
	if (sender == fontStyle)		[prefs setFontStyling:		[[fontStyle selectedItem] tag]];
	if (sender == fontSize)			[prefs setFontSize:			[self fontSizeForTag: [[fontSize selectedItem] tag]]];
	if (sender == colourSet)		[prefs setColourSet:		[[colourSet selectedItem] tag]];
	if (sender == changeColours)	[prefs setChangeColours:	[[changeColours selectedItem] tag]];
}

- (void) reflectCurrentPreferences {
	IFPreferences* prefs = [IFPreferences sharedPreferences];
	
	[fontSet selectItem:		[[fontSet menu]			itemWithTag: [prefs fontSet]]];
	[fontStyle selectItem:		[[fontStyle menu]		itemWithTag: [prefs fontStyling]]];
	[fontSize selectItem:		[[fontSize menu]		itemWithTag: [self tagForFontSize: [prefs fontSize]]]];
	[colourSet selectItem:		[[colourSet menu]		itemWithTag: [prefs colourSet]]];
	[changeColours selectItem:	[[changeColours menu]	itemWithTag: [prefs changeColours]]];
	
	[previewStorage preferencesChanged: nil];
	[previewStorage highlighterPass];
}

@end
