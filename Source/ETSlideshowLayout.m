/*
	Copyright (C) 2009 Eric Wasylishen
 
	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  August 2009
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETCompatibility.h"
#import "ETSlideshowLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutLine.h"
#import "ETGeometry.h"


/**
 * FIXME: Currently, all layout items are shown - not just the current "slide",
 * even though layoutLineForLayoutItems: returns a layout line with only one
 * layout item.
 * 
 * -[ETComputedLayout renderWithLayoutItems:isNewContent:] is correctly setting
 * the visible item set. The problem is that the visible item set isn't respected
 * and all layout items get rendered.
 *
 * A quick fix which worked was to add 
 *
 * if (![item isVisible])
 *     return;
 *
 * to -[ETBasicItemStyle render:layoutItem:dirtyRect:].
 *
 * Not sure if that is correct, or maybe I am misinterpreting what should be
 * happening?
 */
@implementation ETSlideshowLayout

/** Returns a line filled with the one item to layout (stored in an array). */
- (ETLayoutLine *) layoutLineForLayoutItems: (NSArray *)items
{
	if ([items count] == 0)
	{
		return nil;
	}

	/* Only include one layout item in the layout */
	ETLayoutLine *line = [ETLayoutLine layoutLineWithLayoutItems:
						  A([items objectAtIndex: _currentItem])];
	

	if ([self isContentSizeLayout])
	{
		// FIXME: currently ETSlideshowLayout doesn't work in this case
		// (i.e. in a scroll view)
		[self setLayoutSize: [[items objectAtIndex: 0] persistentFrame].size];
	}
	else
	{
		[self setLayoutSize: [[self layoutContext] size]];
	}
	
	return line;
}

// Must override unless you use a display view
- (void) computeLayoutItemLocationsForLayoutModel: (NSArray *)layoutModel
{
	if ([layoutModel count] > 1)
	{
		ETLog(@"%@ -computeLayoutItemLocationsForLayoutModel: receives a model "
			  @"with %d objects and not one, this usually means "
			  @"-layoutLineForLayoutItems: isn't overriden as it should.", self, 
			  [layoutModel count]);
	}
	
	[self computeLayoutItemLocationsForLayoutLine: [layoutModel lastObject]];
}

- (void) computeLayoutItemLocationsForLayoutLine: (ETLayoutLine *)line
{	
	ETLayoutItem *item = [[line items] objectAtIndex: 0];

	NSSize layoutSize = [self layoutSize];
	NSSize itemSize = [item size];
	NSSize newItemSize;
	
	layoutSize.width -= 2*[self itemMargin];
	layoutSize.height -= 2*[self itemMargin];
	
	if (layoutSize.width <= 0 || layoutSize.height <= 0 ||
		itemSize.width <= 0 || itemSize.height <= 0)
	{
		return;
	}
	
	float layoutAspectRatio = layoutSize.width / layoutSize.height;
	float itemAspectRatio = itemSize.width / itemSize.height;
	
	if (itemAspectRatio > layoutAspectRatio)
	{
		newItemSize = NSMakeSize(layoutSize.width, layoutSize.width / itemAspectRatio);
	}
	else
	{
		newItemSize = NSMakeSize(layoutSize.height * itemAspectRatio, layoutSize.height);
	}
	NSPoint itemPosition = NSMakePoint(([self layoutSize].width - newItemSize.width) / 2, 
									   ([self layoutSize].height - newItemSize.height) / 2);
	
	// FIXME: Why is [item setWidth:]; [item setHeight: ]; not equivelant to setSize:?
	// FIXME: Why is setFrame: not equivelant to [setSize:]; [setPosition:]; ?
	
	//[item setSize: newItemSize];
	//[item setPosition: itemPosition];
	
	[item setFrame: ETMakeRect(itemPosition, newItemSize)];
}

- (unsigned int) currentItem
{
	return _currentItem;
}
- (void) setCurrentItem: (unsigned int)item
{
	_currentItem = MAX(0, MIN([[[self layoutContext] items] count] - 1, item));
	[(ETLayoutItemGroup *)[self layoutContext] updateLayout];
}
- (void) nextItem
{
	[self setCurrentItem: _currentItem + 1];
}
- (void) previousItem
{
	[self setCurrentItem: _currentItem - 1];
}

@end
