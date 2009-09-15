/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETFlowLayout.h"
#import "ETGeometry.h"
#import "ETLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutLine.h"
#import "ETCompatibility.h"
#include <float.h>

#define DEFAULT_ITEM_MARGIN 15
#define DEFAULT_MAX_ITEM_SIZE NSMakeSize(256, 256)

@implementation ETFlowLayout

- (id) init
{
	SUPERINIT

	/* Overriden default property values */
	[self setConstrainedItemSize: DEFAULT_MAX_ITEM_SIZE];
	[self setItemSizeConstraintStyle: ETSizeConstraintStyleVerticalHorizontal];
	[self setItemMargin: DEFAULT_ITEM_MARGIN];
	
	_layoutConstraint = ETSizeConstraintStyleHorizontal;

	return self;
}

/** Runs the layout computation which assigns a location in the layout context
to the items, which are expected to be already broken into lines in layoutModel. */
- (void) computeLocationsForFragments: (NSArray *)layoutModel
{
	float itemMargin = [self itemMargin];
	NSPoint itemLocation = NSMakePoint(0, itemMargin);
	float newLayoutHeight = 0;
	BOOL isFlipped = [[self layoutContext] isFlipped];

	if (isFlipped == NO)
	{
		ETLog(@"WARNING: Flow layout doesn't handle non-flipped coordinates inside a scroll view");
		itemLocation.y = [self layoutSize].height - itemMargin;
	}

	FOREACH(layoutModel, line, ETLayoutLine *)
	{
    /*
         A +---------------------------------------
           |          ----------------
           |----------|              |    Layout
           | Layouted |   Layouted   |    Line
           |  Item 1  |   Item 2     |
         --+--------------------------------------- <-- here is the baseline
           B
       
       In the layout context coordinates we have:   
       baselineLocation.x = A.x and baselineLocation.y = A.y - B.y
       
     */

		[line setOrigin: itemLocation];
    
		/* Before computing the following items location in 'x' on the next line, 
		   we have to reset the 'x' accumulator and take in account the end of 
		   the current line, by substracting to 'y' the last layout line height. */
		if (isFlipped)
		{
			itemLocation.y = [line origin].y + [line height] + itemMargin;
		}
		else
		{
			itemLocation.y = [line origin].y - [line height] - itemMargin;		
		}

		/* Increase height of the content size. Used to adjust the document 
		   view size in scroll view */
		newLayoutHeight += [line height] + itemMargin;

		ETDebugLog(@"Item locations computed by layout line :%@", line);
	}

	[self setLayoutSize: NSMakeSize([self layoutSize].width, newLayoutHeight)];
}

/** Breaks the items into lines and returns the resulting array as a layout model. */
- (NSArray *) generateFragmentsForItems: (NSArray *)items
{
	NSMutableArray *unlayoutedItems = [NSMutableArray arrayWithArray: items];
	NSMutableArray *layoutModel = [NSMutableArray array];

	while ([unlayoutedItems count] > 0)
	{
		ETLayoutLine *line = [self layoutFragmentWithSubsetOfItems: unlayoutedItems];
		
		if ([[line fragments] count] > 0)
		{
			[layoutModel addObject: line];    
				
			/* In unlayoutedItems, remove the items which have just been 
			   layouted on the previous line. */
			[unlayoutedItems removeObjectsInArray: [line fragments]];
		}
		else
		{
			ETDebugLog(@"Unlayouted items: %@", unlayoutedItems);
			break;
		}
	}

	return layoutModel;
}

/** Returns a line filled with items to layout.

Fills the layout line by iterating over the items until the total width extends 
beyond the right boundary. At that point, the new line is returned whether or 
not every items have been inserted into it.

When items is empty, returns an empty layout line. */
- (ETLayoutLine *) layoutFragmentWithSubsetOfItems: (NSArray *)items
{
	float layoutWidth = FLT_MAX;
	
	if ([self layoutSizeConstraintStyle] == ETSizeConstraintStyleHorizontal)
	{
		layoutWidth = [self layoutSize].width;
	}

	ETLayoutLine *line = [ETLayoutLine horizontalLineWithFragmentMargin: [self itemMargin] 
	                                                           maxWidth: layoutWidth];
	NSArray *acceptedItems = [line fillWithFragments: items];
	float lineLength = [line length];

	// NOTE: Not really useful for now because we don't support filling the 
	// layout horizontally, only vertical filling is in place.
	// We only touch the layout size height in -computeItemLocationsForLayoutModel:
	if ([self isContentSizeLayout] && [self layoutSize].width < lineLength)
	{
		[self setLayoutSize: NSMakeSize(lineLength, [self layoutSize].height)];
	}

	if ([acceptedItems isEmpty])
		return nil;

	return line;
}

/** Lets you control the constraint applied on the layout when 
-isContentSizeLayout returns YES. The most common case is when the layout is set 
on a layout item embbeded in a scroll view. 

By passing ETSizeConstraintStyleVertical, the layout will try to fill the 
limited height (provided by -layoutSize) with as many lines of equal width as 
possible. In this case, layout width and line width are stretched.

By passing ETSizeConstraintStyleHorizontal, the layout will try to fill the 
unlimited height with as many lines of equally limited width (returned
by -layoutSize) as needed. In this case, only layout height is stretched. 

ETSizeConstraintStyleNone and ETSizeConstraintStyleVerticalHorizontal are not 
supported. If you use them, the receiver resets ETSizeConstraintStyleHorizontal 
default value. */
- (void) setLayoutSizeConstraintStyle: (ETSizeConstraintStyle)constraint
{
	if (constraint == ETSizeConstraintStyleHorizontal 
	 || constraint == ETSizeConstraintStyleVertical)
	{ 
		_layoutConstraint = constraint;
	}
	else
	{
		_layoutConstraint = ETSizeConstraintStyleHorizontal;
	}
}

/** Returns the constraint applied on the layout which are only valid when 
-isContentSizeLayout returns YES. 

Default value is ETSizeConstraintStyleHorizontal. */
- (ETSizeConstraintStyle) layoutSizeConstraintStyle
{
	return _layoutConstraint;
}

/** Not yet implemented */
- (BOOL) usesGrid
{
	return _grid;
}

/** Not yet implemented */
- (void) setUsesGrid: (BOOL)constraint
{
	_grid = constraint;
}

@end
