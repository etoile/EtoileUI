/** <title>ETComputedLayout</title>
	
	<abstract>An abstract layout class whose subclasses position items by 
	computing their locations based on a set of rules.</abstract>
 
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date: July 2008
	License:  Modified BSD (see COPYING)
*/

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETPositionalLayout.h>
#import <EtoileUI/ETFragment.h>

@class ETLayoutItem, ETLineFragment;

extern CGFloat ETAlignmentHintNone;

@protocol ETAlignmentHint
- (CGFloat) alignmentHintForLayout: (ETLayout *)aLayout;
@property (nonatomic, readonly) CGFloat maxCombinedBoundingWidth;
@end

/** Describes how the content is horizontally positioned inside the layout 
context.

The horizontal aligment computation takes in account all the margins previously 
specified on the layout. */
typedef NS_ENUM(NSUInteger, ETLayoutHorizontalAlignment)
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
};


/** ETComputedLayout is the base class for layouts whose role is only consists 
in positioning, orienting and sizing the layout items handed to it.

The layout logic must be strictly positional and not touch anything else than 
the item geometry (position, width, height, scale, rotation etc.).

Subclasses must not hide, replace or modify the item tree structure bound to the 
layout context in any way, unlike what ETTemplateItemLayout is allowed to do.

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
-renderWithItems:isNewContent:.  */
@interface ETComputedLayout : ETPositionalLayout <ETComputableLayout, ETLayoutFragmentOwner>
{
	@private
	CGFloat _borderMargin;
	CGFloat _itemMargin;
	BOOL _autoresizesItemToFill;
	ETLayoutHorizontalAlignment _horizontalAlignment;
	CGFloat _horizontalAlignmentGuidePosition;
	BOOL _usesAlignmentHint;
	ETLayoutItem *_separatorTemplateItem;
	CGFloat _separatorItemEndMargin;
	BOOL _computesItemRectFromBoundingBox;
}

/** @taskunit Alignment and Margins */

@property (nonatomic) CGFloat borderMargin;
@property (nonatomic) CGFloat itemMargin;
@property (nonatomic) BOOL autoresizesItemToFill;
@property (nonatomic) ETLayoutHorizontalAlignment horizontalAlignment;
@property (nonatomic) CGFloat horizontalAlignmentGuidePosition;
@property (nonatomic) BOOL usesAlignmentHint;

/** @taskunit Layout Computation */

@property (nonatomic) BOOL computesItemRectFromBoundingBox;

- (NSRect) rectForItem: (ETLayoutItem *)anItem;
- (void) setOrigin: (NSPoint)newOrigin forItem: (ETLayoutItem *)anItem;

- (NSSize) renderWithItems: (NSArray *)items isNewContent: (BOOL)isNewContent;

/** @taskunit Fragment-based Layout */

- (ETLineFragment *) layoutFragmentWithSubsetOfItems: (NSArray *)unlayoutedItems;
- (NSArray *) generateFragmentsForItems: (NSArray *)items;
- (NSPoint) originOfFirstFragment: (id)aFragment 
                 forContentHeight: (CGFloat)contentHeight;
- (NSSize) computeLocationsForFragments: (NSArray *)layoutModel;

/** @taskunit Flexible Items */

- (void) prepareFlexibleItem: (ETLayoutItem *)anItem;
- (BOOL) isFlexibleItem: (ETLayoutItem *)anItem;
/** <override-dummy />
Returns the size of each flexible item by splitting the remaining space among
the given number of flexible items in the current layout size.

If the current layout size is bigger than the max allowed size, then the
item width or height should be set to zero or to a minimum value. There is no 
space remaining to be divided among of the flexible items, so they should hidden 
or shrinked as much as possible.

If the current layout size is smaller than the max allowed size, then the 
available width or height should be distributed between items according to a 
strategy specific to each subclass.

Any subclass implementation must subtract the item bouding insets from the 
returned size. For example, a line layout would return 
<code>item.width - (item.boundingInsets.left + item.boundingInsets.right)</code>.

See also -setOrigin:forItem: which takes in account the bounding insets to 
update the item position. */
- (NSSize) sizeOfFlexibleItem: (ETLayoutItem *)anItem
         forCurrentLayoutSize: (NSSize)aLayoutSize 
        numberOfFlexibleItems: (NSUInteger)nbOfFlexibleItems
                inMaxAreaSize: (NSSize)maxSize;

/** @taskunit Separator support */

@property (nonatomic, strong) ETLayoutItem *separatorTemplateItem;
@property (nonatomic) CGFloat separatorItemEndMargin;

- (NSArray *) insertSeparatorsBetweenItems: (NSArray *)items;
- (void) prepareSeparatorItem: (ETLayoutItem *)separator;

- (void) adjustSeparatorItem: (ETLayoutItem *)separator forLayoutSize: (NSSize)newLayoutSize;

@end
