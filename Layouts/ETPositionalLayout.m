/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/NSObject+Etoile.h>
#import "ETPositionalLayout.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETCompatibility.h"

@implementation ETPositionalLayout

/** <init /> 
Returns a new positional layout.

The returned layout has both vertical and horizontal constraint on item size 
enabled. The size constraint is set to 256 * 256 px. You can customize item size 
constraint with -setItemSizeConstraint: and -setConstrainedItemSize:. */
- (id) init
{
	return [self initWithLayoutView: nil];
}

- (id) initWithLayoutView: (NSView *)aView
{
	NSParameterAssert(aView == nil);
	self = [super initWithLayoutView: aView];
	if (self == nil)
		return nil;
	
	_constrainedItemSize = NSMakeSize(256, 256); /* Default max item size */
	/* By default both width and height must be equal or inferior to related _constrainedItemSize values */
	_itemSizeConstraintStyle = ETSizeConstraintStyleNone;
	return self;
}

/** <override-dummy />
Returns a copy of the receiver.<br />
The given context which might be nil will be set as the layout context on the copy.

This method is ETLayout designated copier. Subclasses that want to extend 
the copying support must invoke it instead of -copyWithZone:.

Subclasses must be aware that this method calls -setAttachedTool: with an 
tool copy. */ 
- (id) copyWithZone: (NSZone *)aZone layoutContext: (id <ETLayoutingContext>)ctxt
{
	ETPositionalLayout *newLayout = [super copyWithZone: aZone layoutContext: ctxt];

	newLayout->_constrainedItemSize = _constrainedItemSize;
	newLayout->_itemSizeConstraintStyle = _itemSizeConstraintStyle;
	newLayout->_isContentSizeLayout  = _isContentSizeLayout;

	return newLayout;
}

/** Sets whether the layout context can be resized, when its current size is 
not enough to let the layout present the items in its own way. 

The only common case where -isContentSizeLayout should return YES is when the 
layout context is scrollable, and ETLayout does it transparently. Which means 
you very rarely need to use this method.
 
If -isContentSizeLayout is YES, the items are not autoresized.
 
Each time this method is called, the layout size is reset. This means resizing 
the layout context prior to -setIsContentSizeLayout: NO won't autoresize the 
items for the layout update at the end of the current event. If you want to 
autoresize the items, you must resize the layout context when 
-isContentSizeLayout returns NO (and ensure -isContentSizeLayout won't be 
switched again until the end of the currrent event).

See also -isContentSizeLayout:. */
- (void) setIsContentSizeLayout: (BOOL)flag
{
	//ETDebugLog(@"-setContentSizeLayout");
	_isContentSizeLayout = flag;
	[self resetLayoutSize];
}

/** Returns whether the layout context can be resized, when its current size is 
not enough to let the layout present the items in its own way. 

If -isContentSizeLayout is YES, the items are not autoresized.

When a scrollable area item decorates the layout context, -isContentSizeLayout 
always returns YES. */
- (BOOL) isContentSizeLayout
{
	if ([_layoutContext isScrollable])
		return YES;

	return _isContentSizeLayout;
}

/** <override-never />Returns self.

See -[ETLayout positionalLayout]. */
- (ETPositionalLayout *) positionalLayout
{
	return self;
}

/** Sets how the item is resized based on the constrained item size.

See ETSizeConstraintStyle enum. */
- (void) setItemSizeConstraintStyle: (ETSizeConstraintStyle)constraint
{
	_itemSizeConstraintStyle = constraint;
}

/** Returns how the item is resized based on the constrained item size.

See ETSizeConstraintStyle enum. */
- (ETSizeConstraintStyle) itemSizeConstraintStyle
{
	return _itemSizeConstraintStyle;
}

/** Sets the width and/or height to which the items should be resized when their 
width and/or is greater than the given one.

Whether the width, the height or both are resized is controlled by 
-itemSizeConstraintStyle.

See also setItemSizeConstraintStyle: and -resizeLayoutItems:toScaleFactor:. */
- (void) setConstrainedItemSize: (NSSize)size
{
	_constrainedItemSize = size;
}

/** Returns the width and/or height to which the items should be resized when 
their width and/or height is greater than the returned one.

See also -setContrainedItemSize:. */
- (NSSize) constrainedItemSize
{
	return _constrainedItemSize;
}

/** Resizes layout items by scaling -[ETLayoutItem defaultFrame] to the given 
factor.
 
The scaled rect is set using -[ETLayoutItem setFrame:].

Once the scaled rect has been computed, right before applying it to the 
item, this method checks for the item size contraint. If the size constraint 
is ETSizeConstraintStyleNone, the scaled rect is used as is.<br />
For other size constraint values, the scaled rect is checked against 
-constrainedItemSize for either width, height or both, then altered if the 
rect width or height is superior to the allowed maximum value. 

If -itemSizeConstraintStyle returns ETConstraintStyleNone, the layout will 
respect the autoresizing mask returned by -[ETLayoutItem autoresizingMask], 
otherwise it won't. */
- (void) resizeItems: (NSArray *)items toScaleFactor: (float)factor
{
	if ([self itemSizeConstraintStyle] == ETSizeConstraintStyleNone)
		return;

	for (ETLayoutItem *item in items)
	{
		/* Scaling is always computed from item default frame rather than
		   current item view size (or  item display area size) in order to
		   avoid rounding error that would increase on each scale change 
		   because of size width and height expressed as float. */
		NSRect itemFrame = ETScaleRect([item defaultFrame], factor);
		
		/* Apply item size constraint if needed */
		if ([self itemSizeConstraintStyle] != ETSizeConstraintStyleNone 
		 && (itemFrame.size.width > [self constrainedItemSize].width
		 || itemFrame.size.height > [self constrainedItemSize].height))
		{ 
			BOOL isVerticalResize = NO;
			
			if ([self itemSizeConstraintStyle] == ETSizeConstraintStyleVerticalHorizontal)
			{
				if (itemFrame.size.height > itemFrame.size.width)
				{
					isVerticalResize = YES;
				}
				else /* Horizontal resize */
				{
					isVerticalResize = NO;
				}
			}
			else if ([self itemSizeConstraintStyle] == ETSizeConstraintStyleVertical
			      && itemFrame.size.height > [self constrainedItemSize].height)
			{
				isVerticalResize = YES;	
			}
			else if ([self itemSizeConstraintStyle] == ETSizeConstraintStyleHorizontal
			      && itemFrame.size.width > [self constrainedItemSize].width)
			{
				isVerticalResize = NO; /* Horizontal resize */
			}
			
			if (isVerticalResize)
			{
				float maxItemHeight = [self constrainedItemSize].height;
				float heightDifferenceRatio = maxItemHeight / itemFrame.size.height;
				
				itemFrame.size.height = maxItemHeight;
				itemFrame.size.width *= heightDifferenceRatio;
					
			}
			else /* Horizontal resize */
			{
				float maxItemWidth = [self constrainedItemSize].width;
				float widthDifferenceRatio = maxItemWidth / itemFrame.size.width;
				
				itemFrame.size.width = maxItemWidth;
				itemFrame.size.height *= widthDifferenceRatio;				
			}
		}
		
		/* Apply Scaling */
		itemFrame.origin = [item origin];
		[item setFrame: itemFrame];
		ETDebugLog(@"Scale %@ to %@", NSStringFromRect([item defaultFrame]), 
			NSStringFromRect(ETScaleRect([item defaultFrame], factor)));
	}
}

@end
