/*
 *  regexp.c
 *  Inform-xc2
 *
 *  Created by Andrew Hunter on 15/06/2007.
 *  Copyright 2007 Andrew Hunter. All rights reserved.
 *
 */

/*
 * Routines for building regular expressions into ndfas
 */

#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "ndfa.h"


/* =============================
 * Compiling regular expressions
 */

typedef struct char_range {
	ndfa_token start;
	ndfa_token end;
} char_range;

/* Sorts character ranges */
static int compare_char_ranges(const void* a, const void* b) {
	const char_range* ar = a;
	const char_range* br = b;
	
	if (ar->start > br->start) 		return  1;
	else if (ar->start < br->start)	return -1;
	else if (ar->end > br->end) 	return  1;
	else if (ar->end < br->end) 	return -1;
	else 							return  0;
}

/* Given a character that follows a '\' returns the 'real' character to use */
static int quoted_char(int quoted) {
	switch (quoted)
	{
		case '0':
			return 0;
			
		case 'a':
			return '\a';
			
		case 'b':
			return '\b';
			
		case 'f':
			return '\f';
		
		case 't':
			return '\t';
			
		case 'n':
			return '\n';
			
		case 'r':
			return '\r';
			
		case 'v':
			return '\v';
			
		case 'w':
			/* Special case: this is a set of characters */
			return ' ';
		
		default:
			/* Default is just the character that was quoted */
			return quoted;
	}
}

/* Compiles in the whitespace set into the nfa */
static void add_whitespace_set(ndfa nfa) {
	ndfa_push(nfa);
	
	/* Excludes NBSP characters */
	ndfa_transition(nfa, ' ', NULL); 
	ndfa_or(nfa);
	ndfa_transition_range(nfa, 0x9, 0xd, NULL); 		/* Unicode whitespace control characters */
	ndfa_or(nfa);
	ndfa_transition(nfa, 0x85, NULL);					/* NEL */
	ndfa_or(nfa);
	ndfa_transition(nfa, 0x1680, NULL); 				/* Ogham space mark */
	ndfa_or(nfa);
	ndfa_transition(nfa, 0x180E, NULL); 				/* Mongolian vowel separator */
	ndfa_or(nfa);
	ndfa_transition_range(nfa, 0x2000, 0x200a, NULL); 	/* Various */
	ndfa_or(nfa);
	ndfa_transition_range(nfa, 0x2028, 0x2029, NULL); 	/* LSP/PSP */
	ndfa_or(nfa);
	ndfa_transition(nfa, 0x205F, NULL); 				/* Medium mathematical space */
	ndfa_or(nfa);
	ndfa_transition(nfa, 0x3000, NULL); 				/* Ideographic space */
	
	ndfa_rejoin(nfa);
}

/* Compiles a UCS-4 regexp into a ndfa */
int ndfa_compile_regexp_ucs4(ndfa nfa, const ndfa_token* regexp, void* data) {
	int was_successful = 1;
	int bracket_stack = 0;
	ndfa_pointer recent_state;		/* State to go back to for ?, *, etc */
	
	/* Create an initial state for this regexp */
	ndfa_pointer original_state = ndfa_get_pointer(nfa);
	ndfa_pointer start_state = ndfa_create_state(nfa);
	
	ndfa_set_pointer(nfa, start_state);
	
	/* Run through the regular expression */
	int x;
	int this_state;
	ndfa_push(nfa);
	for (x=0; regexp[x] != 0; x++) {
		/* Perform actions depending on the character we encounter */
		switch (regexp[x]) {
			case '(':
				/* Start a new bracketed list */
				ndfa_push(nfa);
				bracket_stack++;
				break;
				
			case ')':
				if (bracket_stack <= 0) {
					/* Mismatched bracket */
					was_successful = 0;
					goto failed;
				}
				
				/* Finish this bracketed list */
				recent_state = ndfa_peek(nfa);
				ndfa_rejoin(nfa);
				bracket_stack--;
				break;
				
			case '+':
				/* Repeat from recent_state */
				this_state = ndfa_get_pointer(nfa);
				ndfa_set_pointer(nfa, recent_state);
				ndfa_push(nfa);
				ndfa_set_pointer(nfa, this_state);
				ndfa_repeat(nfa);
				ndfa_pop(nfa);
				break;

			case '*':
				/* Repeat from recent_state 0 or more times */
				this_state = ndfa_get_pointer(nfa);
				ndfa_set_pointer(nfa, recent_state);
				ndfa_push(nfa);
				ndfa_or(nfa);
				ndfa_set_pointer(nfa, this_state);
				ndfa_repeat(nfa);
				ndfa_rejoin(nfa);
				break;

			case '?':
				/* Optional recent_state */
				this_state = ndfa_get_pointer(nfa);
				ndfa_set_pointer(nfa, recent_state);
				ndfa_push(nfa);
				ndfa_or(nfa);
				ndfa_set_pointer(nfa, this_state);
				ndfa_rejoin(nfa);
				break;
				
			case '|':
				/* Perform an OR with the last state on the stack */
				ndfa_or(nfa);
				break;
			
			case '\\':
				/* Quoted character */
				x++;
				if (regexp[x] == 0) {
					/* Unterminated quote */
					was_successful = 0;
					goto failed;
				}
				
				if (regexp[x] == 'w') {
					/* Whitespace set */
					recent_state = ndfa_get_pointer(nfa);
					add_whitespace_set(nfa);
				} else {
					/* Add the quoted character */
					recent_state = ndfa_get_pointer(nfa);
					ndfa_transition(nfa, quoted_char(regexp[x]), NULL);
				}
				break;
				
			case '[':
			{
				/* Character range */
				int negated = 0;
				int y;

				recent_state = ndfa_get_pointer(nfa);
				
				/* This is a negated expression if it begins '[^*/
				x++;
				if (regexp[x] == '^') {
					negated = 1;
					x++;
				}
				
				/* Work out the character ranges included by this expression */
				char_range* ranges = NULL;
				int num_ranges = 0;
				for (;regexp[x] != 0 && regexp[x] != ']'; x++) {
					ndfa_token chr;
					int toend = 0;

					if (regexp[x] == '-' && num_ranges > 0 && regexp[x+1] != 0 && regexp[x+1] != ']') {
						/* The next character indicates the end of a range */
						toend = 1;
						x++;
					}
					
					/* Work out the character to include */
					switch (regexp[x]) {
						case '\\':
							x++;
							if (regexp[x] == 0) {
								was_successful = 0;
								goto failed;
							}
							
							/* Quoted character */
							if (regexp[x] == 'w' && !toend && regexp[x+1] != '-') {
								/* Complete whitespace set */
								chr = 0xffffffff;

								num_ranges+=9;
								ranges = realloc(ranges, sizeof(char_range)*num_ranges);
								assert(ranges != NULL);
								
								ranges[num_ranges-9].start = ' ';		ranges[num_ranges-9].end = ' ';
								ranges[num_ranges-8].start = 0x9;		ranges[num_ranges-8].end = 0xd;
								ranges[num_ranges-7].start = 0x85;		ranges[num_ranges-7].end = 0x85;
								ranges[num_ranges-6].start = 0x1680;	ranges[num_ranges-6].end = 0x1680;
								ranges[num_ranges-5].start = 0x180E;	ranges[num_ranges-5].end = 0x180E;
								ranges[num_ranges-4].start = 0x2000;	ranges[num_ranges-4].end = 0x200A;
								ranges[num_ranges-3].start = 0x2028;	ranges[num_ranges-3].end = 0x2029;
								ranges[num_ranges-2].start = 0x205F;	ranges[num_ranges-2].end = 0x205F;
								ranges[num_ranges-1].start = 0x3000;	ranges[num_ranges-1].end = 0x3000;
							} else {
								/* Individual character */
								chr = quoted_char(regexp[x]);
							}
							break;

						default:
							chr = regexp[x];
							break;
					}
					
					/* Store this character */
					if (chr != 0xffffffff) {
						if (toend) {
							ranges[num_ranges-1].end	= chr;
						} else {
							num_ranges++;
							ranges = realloc(ranges, sizeof(char_range)*num_ranges);
							assert(ranges != NULL);

							ranges[num_ranges-1].start	= chr;
							ranges[num_ranges-1].end 	= chr;
						}
					}
				}
				
				/* Sort the character ranges into order */
				qsort(ranges, num_ranges, sizeof(char_range), compare_char_ranges);
				
				/* Combine any overlapping ranges */
				for (y=0; y<num_ranges-1; y++) {
					/* See if this range overlaps the following range */
					if (ranges[y].end >= ranges[y+1].start) {
						/* If it does, see if we need to move the end marker */
						if (ranges[y+1].end > ranges[y].end) {
							ranges[y].end = ranges[y+1].end;
						}
						
						/* Remove the following range */
						num_ranges--;
						memmove(ranges + y, ranges + y + 1, sizeof(char_range)*(num_ranges-y));
					}
				}
				
				/* Negate the ranges if necessary */
				if (negated) {
					/* TODO */
					#warning TODO: negate ranges
				}
				
				/* Send the ranges to the NDFA */
				ndfa_push(nfa);
				for (y=0; y<num_ranges; y++) {
					if (y > 0) ndfa_or(nfa);
					ndfa_transition_range(nfa, ranges[y].start, ranges[y].end, NULL);
				}
				ndfa_rejoin(nfa);
				
				/* Clean up */
				free(ranges);
				break;
			}
				
			case '{':
				/* A named regular expression or a repeat count */
				break;
				
			case '^':
				recent_state = ndfa_get_pointer(nfa);
				if (x == 0) {
					/* Start character */
					ndfa_transition(nfa, NDFA_START, NULL);
				} else {
					/* Just add this chararcter to the nfa */
					ndfa_transition(nfa, regexp[x], NULL);					
				}
				break;
				
			case '$':
				recent_state = ndfa_get_pointer(nfa);
				if (regexp[x+1] == 0) {
					/* End character */
					ndfa_transition(nfa, NDFA_END, NULL);
				} else {
					/* Just add this chararcter to the nfa */
					ndfa_transition(nfa, regexp[x], NULL);					
				}
				break;
				
			case '.':
				/* Anything */
				recent_state = ndfa_get_pointer(nfa);
				ndfa_transition_range(nfa, 0, 0x7fffffff, NULL);
				break;
			
			default:
				/* Just add this chararcter to the nfa */
				recent_state = ndfa_get_pointer(nfa);
				ndfa_transition(nfa, regexp[x], NULL);
				break;
		}
	}
	
	/* Rejoin any ORed states */
	ndfa_rejoin(nfa);
	
	/* Record the success data */
	if (data != NULL) {
		ndfa_add_data(nfa, data);
	}
	
	/* Join the initial state with the original state */
	ndfa_pointer join_states[2];
	join_states[0] = original_state;
	join_states[1] = start_state;
	ndfa_join(nfa, 2, join_states);
	
	/* Report success */
failed:;
	return was_successful;
}

/* Compiles an ASCII regexp into a ndfa */
int ndfa_compile_regexp(ndfa nfa, const char* regexp, void* data) {
	/* Convert the regexp to UCS-4 */
	int len = strlen((const char*)regexp);
	int x;
	ndfa_token* ucs4 = malloc(sizeof(ndfa_token)*(len+1));
	
	for (x=0; regexp[x] != 0; x++) {
		ucs4[x] = (unsigned char)regexp[x];
	}
	ucs4[x] = 0;
	
	/* Compile it */
	int result = ndfa_compile_regexp_ucs4(nfa, ucs4, data);
	free(ucs4);
	
	return result;
}
