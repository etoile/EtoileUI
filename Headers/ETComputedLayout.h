/** <title>ETComputedLayout</title>
	
	<abstract>An abstract layout class whose subclasses position items by 
	computing their locations based on a set of rules.</abstract>
 
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date: July 2008
	License:  Modified BSD (see COPYING)
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayout.h>
#import <EtoileUI/ETFragment.h>

@class ETLayoutItem, ETLineFragment;

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


/** ETComputedLayout is the base class for layouts whose role is only consists 
in positioning, orienting and sizing the layout items handed to it.

The layout logic must be strictly positional and not touch anything else than 
the item geometry (position, width, height, scale, rotation etc.).

Subclasses must not hide, replace or modify the item tree structure bound to the 
layout context in any way, unlike what ETCompositeLayout or ETTemplateItemLayout 
are allowed to do.

In a subclass, you must override at least two methods:

<list>
<item>-computeLocationsForFragments:</item>
<item>-layoutFragmentWithSubsetOfItems: or -generateFragmentsForItems:</item>
</list>

You can override both -layoutFragmentWithSubsetOfItems: and 
-generateFragmentsForItems: if you need to.<br />
If you introduce other margins than the built-in ones or want to support extra 
empty areas in the layout, you probably need to override 
-originOfFirstFragment:forContentHeight: too.<br />
In the rare case where more control is required, you might want to reimplement 
-renderLayoutItems:isNewContent:.  */
@interface ETComputedLayout : ETLayout <ETPositionalLayout, ETLayoutFragmentOwner>
{
	@private
	float _borderMargin;
	float _itemMargin;
	ETLayoutHorizontalAlignment _horizontalAlignment;
	float _horizontalAlignmentGuidePosition;
	ETLayoutItem *_separatorTemplateItem;
	float _separatorItemEndMargin;
	BOOL _computesItemRectFromBoundingBox;
}

/* Alignment and Margins */

- (float) borderMargin;
- (void) setBorderMargin: (float)aMargin;
- (void) setItemMargin: (float)aMargin;
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

- (ETLineFragment *) layoutFragmentWithSubsetOfItems: (NSArray *)unlayoutedItems;
- (NSArray *) generateFragmentsForItems: (NSArray *)items;
- (NSPoint) originOfFirstFragment: (id)aFragment 
                 forContentHeight: (float)contentHeight;
- (void) computeLocationsForFragments: (NSArray *)layoutModel;

/* Seperator support */

- (void) setSeparatorTemplateItem: (ETLayoutItem *)separator;
- (ETLayoutItem *) separatorTemplateItem;
- (void) setSeparatorItemEndMargin: (float)aMargin;
- (float) separatorItemEndMargin;

- (NSArray *) insertSeparatorsBetweenItems: (NSArray *)items;
- (void) prepareSeparatorItem: (ETLayoutItem *)separator;
- (void) adjustSeparatorItem: (ETLayoutItem *)separator 
               forLayoutSize: (NSSize)newLayoutSize;

@end
