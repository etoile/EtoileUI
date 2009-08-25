/*
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETComputedLayout.h"
#import "ETCompatibility.h"


@implementation ETComputedLayout

/* Ugly hacks to shut down the compiler, so it doesn't complain that inherited 
   methods also declared by ETPositionaLayout aren't implemented */
- (void) setLayoutContext: (id <ETLayoutingContext>)context { return [super setLayoutContext: context]; }
- (id <ETLayoutingContext>) layoutContext { return [super layoutContext]; }
- (ETLayoutItem *) itemAtLocation: (NSPoint)location { return [super itemAtLocation: location]; }

- (BOOL) isComputedLayout
{
	return YES;
}

/** Sets the size of the margin around each item to be layouted and triggers a 
layout update. */
- (void) setItemMargin: (float)aMargin
{
	_itemMargin = aMargin;

	// TODO: Evaluate whether we should add an API at ETLayout level to request 
	// layout refresh, or rather remove this code and let the developer triggers
	// the layout update.
	if ([self canRender])
	{	
		[self render: nil isNewContent: NO];
		[[self layoutContext] setNeedsDisplay: YES];
	}
}

/** Returns the size of the margin around each item to be layouted. */
- (float) itemMargin
{
	return _itemMargin;
}

/** <override-never />
Runs the layout computation.<br />
See also -[ETLayout renderLayoutItems:isNewContent:].

This method is usually called by -render and you should rarely need to do it by 
yourself. If you want to update the layout, just uses 
-[ETLayoutItemGroup updateLayout]. 
	
You may need to override this method in your layout subclasses if you want
to create a very special layout style. This method will sequentially invoke:
<list>
<item>-resetLayoutSize
<item>-resizeLayoutItems:toScaleFactor:</item>
<item>-layoutModelForLayoutItems:</item>
<item>-computeLayoutItemLocationsForLayoutModel:</item>.
</list>

Finally once the layout is computed, this method set the layout item visibility 
by calling -setVisibleItems: on the layout context. 

The scroll view visibility is handled by this method (this is subject to change). */
- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{	
	[super renderWithLayoutItems: items isNewContent: isNewContent];

	NSMutableArray *spacedItems = [NSMutableArray array];
	for (unsigned int i=0; i<[items count]; i++)
	{
		[spacedItems addObject: [items objectAtIndex: i]];
		if (i < [items count] - 1 && [self seperatorTemplateItem] != nil)
		{
			[spacedItems addObject: AUTORELEASE([[self seperatorTemplateItem] copy])];
		}
	}
	
	NSArray *layoutModel = [self layoutModelForLayoutItems: spacedItems];
	/* Now computes the location of every items by relying on the line by line 
	   decomposition already made. */
	[self computeLayoutItemLocationsForLayoutModel: layoutModel];
	
	// TODO: May be worth to optimize by computing set intersection of visible 
	// and unvisible layout items
	[[self layoutContext] setVisibleItems: [NSArray array]];
	
	/* Adjust layout context size when it is embedded in a scroll view */
	if ([[self layoutContext] isScrollViewShown])
	{
		NSAssert([self isContentSizeLayout], 
			@"Any layout done in a scroll view must be based on content size");
			
		[[self layoutContext] setContentSize: [self layoutSize]];
		ETDebugLog(@"Layout size is %@ with layout context size %@ and clip view size %@", 
			NSStringFromSize([self layoutSize]), 
			NSStringFromSize([[self layoutContext] size]), 
			NSStringFromSize([[self layoutContext] visibleContentSize]));
	}

	NSMutableArray *visibleItems = [NSMutableArray array];
	
	/* Flatten layout model by putting all items into a single array */
	FOREACH(layoutModel, line, ETLayoutLine *)
	{
		[visibleItems addObjectsFromArray: [line items]];
	}
	
	[[self layoutContext] setVisibleItems: visibleItems];
}

/* 
 * Line-based layouts methods 
 */

/** <override-subclass />
Overrides this method to generate a layout line based on the layout context 
constraints. Usual layout context constraints are size, vertical and horizontal 
scroller visibility. */
- (ETLayoutLine *) layoutLineForLayoutItems: (NSArray *)items
{
	return nil;
}

/** <override-dummy />
Returns a layout model where layouts lines have been collected inside an array, 
whose indexes indicate in which order these layout lines should be presented.

Overrides this method to generate your own layout model based on the layout 
context constraints. Usual layout context constraints are size, vertical and 
horizontal scrollers visibility. How the layout model is structured is up to you.

This layout model will be interpreted by -computeViewLocationsForLayoutModel:. */
- (NSArray *) layoutModelForLayoutItems: (NSArray *)items
{
	ETLayoutLine *line = [self layoutLineForLayoutItems: items];
	
	if (line != nil)
		return A(line);

	return nil;
}

/** <override-subclass />
Overrides this method to interpret the layout model and compute the layout item 
geometrical attributes (position, size, scale etc.) accordingly. */
- (void) computeLayoutItemLocationsForLayoutModel: (NSArray *)layoutModel
{

}

/* Seperator support */

- (void) setSeparatorTemplateItem: (ETLayoutItem *)seperator
{
	ASSIGN(_seperatorTemplateItem, seperator);
	
	if ([self canRender])
	{	
		[self render: nil isNewContent: NO];
		[[self layoutContext] setNeedsDisplay: YES];
	}
}
			
- (ETLayoutItem *) seperatorTemplateItem
{
	return _seperatorTemplateItem;
}

@end
