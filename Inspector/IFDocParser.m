//
//  IFDocParser.m
//  Inform-xc2
//
//  Created by Andrew Hunter on 28/10/2006.
//  Copyright 2006 Andrew Hunter. All rights reserved.
//

#import "IFDocParser.h"


@implementation IFDocParser

NSString* IFDocHtmlTitleAttribute = @"IFDocHtmlTitle";
NSString* IFDocTitleAttribute = @"IFDocTitle";
NSString* IFDocSectionAttribute = @"IFDocSection";
NSString* IFDocSortAttribute = @"IFDocSort";

// = Static dictionaries =

static NSSet* ignoreTags = nil;
static NSDictionary* entities = nil;

// = Initialisation =

+ (void) initialize {
	if (ignoreTags == nil) {
		ignoreTags = [[NSSet alloc] initWithObjects:
			@"head", @"script", 
			nil];
		entities = [[NSDictionary alloc] initWithObjectsAndKeys:
			@"<", @"lt",
			@">", @"gt",
			@"\"", @"quot",
			@" ", @"nbsp",
			nil];
	}
}

enum ParseState {
	PlainText,
	HtmlTagOrComment,
	HtmlTag,
	HtmlCloseTag,
	HtmlComment,
	HtmlCommentEnd1,
	HtmlCommentEnd2,
	HtmlEntity
};

- (id) initWithHtml: (NSString*) html {
	self = [super init];
	
	if (self) {
		// Prepare the results string
		NSMutableDictionary* attr = [[NSMutableDictionary alloc] init];
		
		// Parse the HTML
		int len = [html length];
		unichar* chrs = malloc(sizeof(unichar)*(len+1));
		unichar* result = malloc(sizeof(unichar)*(len+1));
		unichar* exampleResult = malloc(sizeof(unichar)*(len+1));
		[html getCharacters: chrs];
		int resultLength = 0;
		int exampleLength = 0;
		
		int x;
		enum ParseState state = PlainText;
		BOOL whitespace = YES;
		BOOL inTitle = NO;
		BOOL inExample = NO;
		
		unichar* title = malloc(sizeof(unichar)*(len+1));
		int titleLength = 0;
		
		int tagStart = 0;
		int ignoreCount = 0;
		
		for (x=0; x<len; x++) {
			switch (state) {
				case PlainText:
					// This is a plain text section
					switch (chrs[x]) {
						case ' ':
						case '\t':
						case '\n':
						case '\r':
							// This is whitespace: append a maximum of one item of whitespace at a time
							if (inTitle && !whitespace) {
								whitespace = YES;
								title[titleLength++] = ' ';
							}
							if (ignoreCount) break;
							if (!whitespace) {
								whitespace = YES;
								result[resultLength++] = ' ';
								if (inExample) exampleResult[exampleLength++] = ' ';
							}
							break;
							
						case '<':
							// This is the beginning of a comment or a tag
							state = HtmlTagOrComment;
							tagStart = x;
							break;
							
						case '&':
							// This is the beginning of an entity
							state = HtmlEntity;
							tagStart = x;
							break;
							
						default:
							// This is a non-whitespace character
							if (inTitle) {
								whitespace = NO;
								title[titleLength++] = chrs[x];
							}
							if (ignoreCount) break;
							whitespace = NO;
							result[resultLength++] = chrs[x];
							if (inExample) exampleResult[exampleLength++] = chrs[x];
							break;
					}
					break;
					
				case HtmlEntity:
					switch (chrs[x]) {
						case ' ':
						case '\t':
						case '\n':
						case '\r':
						case ';':
						{
							NSString* entity = [NSString stringWithCharacters: chrs + tagStart+1
																	   length: x - (tagStart+1)];
							entity = [entity lowercaseString];
							NSString* entityValue = [entities objectForKey: entity];

							// End of this entity
							state = PlainText;
							if (inTitle) {
								whitespace = NO;
								title[titleLength++] = [entityValue characterAtIndex: 0];
							}
							if (ignoreCount) break;
							
							whitespace = NO;
							if (entityValue != nil) {
								result[resultLength++] = [entityValue characterAtIndex: 0];
								if (inExample) exampleResult[exampleLength++] = [entityValue characterAtIndex: 0];
							}
							break;
						}
							
						default:
							// The entity continues
							break;
					}
					break;
					
				case HtmlTagOrComment:
					// This is either the beginning of a tag, or the beginning of a comment, or the beginning of a close tag
					switch (chrs[x]) {
						case '/':
							state = HtmlCloseTag;
							tagStart = x;
							break;
							
						case '!':
							state = HtmlComment;
							break;
							
						case '>':
							state = PlainText;
							break;
							
						default:
							state = HtmlTag;
							break;
					}
					break;
					
				case HtmlTag:
				case HtmlCloseTag:
					switch (chrs[x]) {
						case '>':
						{
							// End of this tag

							// Get the tag
							NSString* tag = [NSString stringWithCharacters: chrs + tagStart + 1
																	length: x - (tagStart + 1)];
							NSInteger spaceLoc = [tag rangeOfString: @" "].location;
							if (spaceLoc != NSNotFound) tag = [tag substringToIndex: spaceLoc];
								
							tag = [tag lowercaseString];
							
							// If this is an ignore tag, then increase/decrease the ignore count
							if ([ignoreTags containsObject: tag]) {
								if (state == HtmlTag) {
									ignoreCount++;
								} else {
									ignoreCount--;
								}
							}
							
							if (ignoreCount <= 0 && ([tag isEqualToString: @"br"] || [tag isEqualToString: @"p"])) {
								if (!whitespace) {
									whitespace = YES;
									result[resultLength++] = ' ';
									if (inExample) exampleResult[exampleLength++] = ' ';
								}
							}
							
							if ([tag isEqualToString: @"title"]) {
								if (state == HtmlTag) {
									inTitle = YES;
									whitespace = YES;
								} else {
									inTitle = NO;
									whitespace = YES;
								}
							}

							state = PlainText;
							break;
						}
							
						default:
							// The tag continues
							break;
					}
					break;
					
				case HtmlComment:
					switch (chrs[x]) {
						case '-':
							state = HtmlCommentEnd1;
							break;
							
						default:
							// The comment continues
							break;
					}
					break;
					
				case HtmlCommentEnd1:
					switch (chrs[x]) {
						case '-':
							// '--' has been matched if we get here
							state = HtmlCommentEnd2;
							break;
							
						default:
							// The comment continues
							state = HtmlComment;
							break;
					}
					break;
					
				case HtmlCommentEnd2:
					switch (chrs[x]) {
						case '>':
							// End of this comment
							state = PlainText;

							NSString* comment = [NSString stringWithCharacters: chrs + tagStart
																		length: x - tagStart];
							
							// Strip down this comment
							comment = [comment substringFromIndex: 5];					// Removes <!-- 
							comment = [comment substringToIndex: [comment length]-3];	// Removes --
							
							// Look for interesting comments
							if ([comment hasPrefix: @"EXAMPLE START"]) {
								inExample = YES;
							} else if ([comment hasPrefix: @"EXAMPLE END"]) {
								inExample = NO;
							} else if ([comment hasPrefix: @"SEARCH TITLE \""]) {
								int len = [@"SEARCH TITLE \"" length];
								comment = [comment substringWithRange: NSMakeRange(len, [comment length]-(len+1))];
								
								[attr setObject: comment
										 forKey: IFDocTitleAttribute];
							} else if ([comment hasPrefix: @"SEARCH SECTION \""]) {
								int len = [@"SEARCH SECTION \"" length];
								comment = [comment substringWithRange: NSMakeRange(len, [comment length]-(len+1))];
								
								[attr setObject: comment
										 forKey: IFDocSectionAttribute];
							} else if ([comment hasPrefix: @"SEARCH SORT \""]) {
								int len = [@"SEARCH SORT \"" length];
								comment = [comment substringWithRange: NSMakeRange(len-1, [comment length]-(len+2))];
								
								[attr setObject: comment
										 forKey: IFDocSortAttribute];
							}
							break;
							
						case '-':
							// Comment might end later on
							break;
							
						default:
							// The comment continues
							state = HtmlComment;
							break;
					}
			}
		}
		
		// Sanity check
		if (resultLength > len) {
			NSLog(@"Crap: plain text is longer than HTML (stack corrupted; bombing out)");
			abort();
		}
		
		// Tidy up
		[attr setObject: [NSString stringWithCharacters: title
												 length: titleLength]
				 forKey: IFDocHtmlTitleAttribute];
		
		plainText = [[NSString stringWithCharacters: result
											 length: resultLength] retain];
		if (exampleLength > 0)
			example = [[NSString stringWithCharacters: exampleResult
											   length: exampleLength] retain];

		attributes = attr;
		
		free(chrs);
		free(result);
		free(exampleResult);
		free(title);
	}
	
	return self;
}

- (void) dealloc {
	[plainText release];
	[attributes release];
	[example release];
	
	[super dealloc];
}

// = The results =

- (NSString*) plainText {
	return plainText;
}

- (NSDictionary*) attributes {
	return attributes;
}

- (NSString*) example {
	return example;
}

@end
