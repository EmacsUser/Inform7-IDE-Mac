//
//  IFPreferences.h
//  Inform
//
//  Created by Andrew Hunter on 02/02/2005.
//  Copyright 2005 Andrew Hunter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Notifications
extern NSString* IFPreferencesDidChangeNotification;
extern NSString* IFPreferencesChangedEarlierNotification;	// Delayed version of the above

// Types of font
extern NSString* IFPreferencesBaseFont;				// Base font
extern NSString* IFPreferencesBoldFont;				// Bold font (only used for 'Subtle' styling or more)
extern NSString* IFPreferencesItalicFont;			// Italic font (only used for 'Often' styling)
extern NSString* IFPreferencesHeaderFont;			// Font used for NI header
extern NSString* IFPreferencesCommentFont;			// Font used for comments

// Choices
enum IFPreferencesFontSet {
	IFFontSetStandard=0,	// SystemFont/boldSystemFont
	IFFontSetProgrammer=1,	// Monaco
	IFFontSetStylised=2,	// Gill Sans
	IFFontSetCustomised=255,
};

enum IFPreferencesFontStyling {
	IFStylingNone=0,		// Never use bold
	IFStylingSubtle=1,		// Bold comments, some bold keywords, bold headings
	IFStylingOften=2,		// Italic comments, bold keywords, etc
};

enum IFPreferencesColourChanges {
	IFChangeColsNever=0,	// Use the default colour always
	IFChangeColsRarely=1,	// Change for strings and keywords only
	IFChangeColsOften=2,	// Change all the time
};

enum IFPreferencesColourSet {
	IFColoursSubdued=0,		// Subtler version of the 'standard' colours
	IFColoursStandard=1,	// Standard colours, a bit like XCode
	IFColoursPsychedlic=2,	// Colours are as bright and different as possible
	IFColoursCustomised=255,
};

//
// General preferences class
//
// Inform's application preferences are stored here
//
@interface IFPreferences : NSObject {
	// The preferences dictionary
	NSMutableDictionary* preferences;
	
	// Notification flag
	BOOL willNotifyLater;
	
	// Caches
	NSMutableDictionary* cacheFontSet;		// Maps 'font types' to fonts
	NSMutableArray* cacheFontStyles;		// Maps styles to fonts
	NSMutableArray* cacheColourSet;			// Choice of colours
	NSMutableArray* cacheColours;			// Maps styles to colours
	
	NSMutableArray* styles;
}

// Constructing the object
+ (IFPreferences*) sharedPreferences;

// = Preferences =

- (void) preferencesHaveChanged;

// Style preferences
- (enum IFPreferencesFontSet) fontSet;
- (enum IFPreferencesFontStyling) fontStyling;
- (enum IFPreferencesColourChanges) changeColours;
- (enum IFPreferencesColourSet) colourSet;

- (void) setFontSet: (enum IFPreferencesFontSet) newFontSet;
- (void) setFontStyling: (enum IFPreferencesFontStyling) newFontStyling;
- (void) setChangeColours: (enum IFPreferencesColourChanges) newColourChanges;
- (void) setColourSet: (enum IFPreferencesColourSet) newColourSet;

- (void) recalculateStyles;
- (NSArray*) styles;

// Intelligence preferences
- (BOOL) enableSyntaxHighlighting;
- (BOOL) indentWrappedLines;
- (BOOL) enableIntelligence;
- (BOOL) intelligenceIndexInspector;
- (BOOL) indentAfterNewline;
- (BOOL) autoNumberSections;

- (void) setEnableSyntaxHighlighting: (BOOL) value;
- (void) setIndentWrappedLines: (BOOL) value;
- (void) setEnableIntelligence: (BOOL) value;
- (void) setIntelligenceIndexInspector: (BOOL) value;
- (void) setIndentAfterNewline: (BOOL) value;
- (void) setAutoNumberSections: (BOOL) value;

@end