/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2009
	License:  Modified BSD (see COPYING)
 */

#import "ETNullLayout.h"

// TODO: We probably want to spare some memory with a better implementation 
// than a raw ETLayout instatiated every time -init or +layout are used to get 
// a new null layout. We could then use a single instance shared between 
// multiple items (which especially would be good with ETLayoutItem).

@implementation ETNullLayout

/** Returns YES. */
- (BOOL) isNull
{
	return YES;
}

/** Does nothing unlike the superclass implementation. */
- (void) tearDown
{
	NSParameterAssert(_layoutContext != nil);
}

/** Does nothing unlike the superclass implementation. */
- (void) setUp
{
	NSParameterAssert(_layoutContext != nil);
}

/** Does nothing unlike the superclass implementation. */
- (void) render: (NSDictionary *)inputValues isNewContent: (BOOL)isNewContent
{

}

/** Does nothing unlike the superclass implementation. */
- (void) resetLayoutSize
{

}

/** Does nothing unlike the superclass implementation. */
- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{	

}

/** Always returns nil unlike the superclass implementation. */
- (ETLayoutItemGroup *) rootItem
{
	return nil;
}

@end
