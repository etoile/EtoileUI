/*
	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2009
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETFixedLayout.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETCompatibility.h"


@implementation ETFixedLayout

/** Always returns YES since items are positioned based on their persistent 
geometry. */
- (BOOL) isPositional
{
	return YES;
}

/** Always returns NO since items are positioned based on their persistent 
geometry and not computed by the receiver. */
- (BOOL) isComputedLayout
{
	return NO;
}

/** Loads the persistent geometry of every item that belong to the layout context. */
- (void) setUp
{
	[super setUp];
	/* Frame must be set to persistent frame before -resizeItems:toScale: is 
	   called by -renderWithLayoutItems:isNewContent:, otherwise the scaling 
	   is computed based on the frame computed by the last layout in use which 
	   may not be ETFreeLayout (when switching from another layout). */
	[self loadPersistentFramesForItems: [[self layoutContext] items]];
}

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{

	[super renderWithLayoutItems: items isNewContent: isNewContent];

	// TODO: May be worth to optimize computing the set union between the 
	// previously and newly rendered items. Roughly something like...
	// NSSet unionSet = [prevRenderedItems setByAddingObjectsFromArray: items];
	// [[self layoutContext] setVisibileItems: items 
	//                               forItems: unionSet];

	//[[self layoutContext] setVisibleItems: [NSArray array]];
	[[self layoutContext] setVisibleItems: items];
}

/** Synchronizes the frames of every layout items provided by the layout 
context, with their persistent frame values.

When an item has no persistent frame value, the sync is done the other way 
around: the persistent frame is initialized with the frame value. */
- (void) loadPersistentFramesForItems: (NSArray *)items
{
	FOREACH(items, item, ETLayoutItem *)
	{
		/* First time persistent frame is accessed, initialize it */
		if (ETIsNullRect([item persistentFrame]))
		{
			[item setPersistentFrame: [item frame]];
		}
		else
		{
			[item setFrame: [item persistentFrame]];
		}
	}
}

@end
