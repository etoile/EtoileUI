/** <title>ETComputedLayout</title>
	
	<abstract>An abstract layout class whose subclasses position items by 
	computing their location based on a set of rules.</asbtract>
 
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date: July 2008
	License:  Modified BSD (see COPYING)
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayout.h>
#import <EtoileUI/ETFragment.h>

@class ETLayoutLine;

/** Describes how the content is horizontally positioned inside the layout 
context.

The horizontal aligment computation takes in account all the margins previously 
specified on the layout. */
typedef enum
{
	ETLayoutHorizontalAlignmentCenter,
/** Centers the content horizontally in the layout context. */
	ETLayoutHorizontalAlignmentLeft,
/** Shifts the content as much as possible towards the left edge of the layout context. */
	ETLayoutHorizontalAlignmentRight,
/** Shifts the content as much as possible towards the right edge of the layout context. */
	ETLayoutHorizontalAlignmentGuided
/** Positions the content on the right of the horizontal alignment guide.<br />
Each layouted item origin will use -horizontalAlignmentGuidePosition as its 'x' value. */
} ETLayoutHorizontalAlignment;


/** ETComputedLayout is a basic abstract class that must be subclassed everytime 
a layout role only consists in positioning, orienting and sizing the layout 
items handed to it.

The layout logic must be strictly positional and not touch anything else than 
the item geometry (position, width, height, scale, rotation etc.).

Subclasses must not hide, replace or modify the layout item tree structure bound 
to the layout context in any way, unlike what ETCompositeLayout or 
ETTemplateItemLayout are allowed to do. */
@interface ETComputedLayout : ETLayout <ETPositionalLayout, ETLayoutFragmentOwner>
{
	float _itemMargin;
	ETLayoutHorizontalAlignment _horizontalAlignment;
	float _horizontalAlignmentGuidePosition;
	ETLayoutItem *_separatorTemplateItem;
	BOOL _computesItemRectFromBoundingBox;
}

/* Alignment and Margins */

- (void) setItemMargin: (float)margin;
- (float) itemMargin;
- (ETLayoutHorizontalAlignment) horizontalAlignment;
- (void) setHorizontalAligment: (ETLayoutHorizontalAlignment)anAlignment;
- (float) horizontalAlignmentGuidePosition;
- (void) setHorizontalAlignmentGuidePosition: (float)aPosition;

/* Layout Computation */

- (BOOL) computesItemRectFromBoundingBox;
- (void) setComputesItemRectFromBoundingBox: (BOOL)usesBoundingBox;
- (NSRect) rectForItem: (ETLayoutItem *)anItem;
- (void) setOrigin: (NSPoint)newOrigin forItem: (ETLayoutItem *)anItem;

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent;

/* Fragment-based Layout */

- (ETLayoutLine *) layoutFragmentWithSubsetOfItems: (NSArray *)unlayoutedItems;
- (NSArray *) generateFragmentsForItems: (NSArray *)items;
- (NSPoint) originOfFirstFragment: (id)aFragment 
                 forContentHeight: (float)contentHeight;
- (void) computeLocationsForFragments: (NSArray *)layoutModel;

/* Seperator support */

- (void) setSeparatorTemplateItem: (ETLayoutItem *)separator;
- (ETLayoutItem *) separatorTemplateItem;

@end
