/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayout.h>

// NOTE: May be this should be turned into a mask
/** Describes how the layouted items are resized at the beginning of the layout 
rendering.

When the constraint is not ETSizeConstraintStyleNone, the item autoresizing 
provided by -[ETLayoutItem autoresizingMask] won't be respected. */
typedef enum _ETSizeConstraintStyle 
{
/** The items are not resized but let as is. */
	ETSizeConstraintStyleNone,
/** The height of the items is set to the height of -[ETLayout constrainedItemSize]. */
	ETSizeConstraintStyleVertical,
/** The width of the items is set to the width of -[ETLayout constrainedItemSize]. */
	ETSizeConstraintStyleHorizontal,
/** The size of the items are set to -[ETLayout constrainedItemSize]. */
	ETSizeConstraintStyleVerticalHorizontal
} ETSizeConstraintStyle;

/** @group Layout
 
@abstract Abstract class to implement layouts that position and resize items 
based on rules or constraints.

For positional layouts that can be used, see ETFixedLayout and ETComputedLayout 
subclasses. */
@interface ETPositionalLayout : ETLayout
{
	@private
	NSSize _constrainedItemSize;
	ETSizeConstraintStyle _itemSizeConstraintStyle;
	BOOL _isContentSizeLayout;
}

/** @taskunit Initialization */

- (id) init;

/** @taskunit Layout Size Control and Feedback */

- (void) setIsContentSizeLayout: (BOOL)flag;
- (BOOL) isContentSizeLayout;

/** @taskunit Item Sizing */

- (void) setItemSizeConstraintStyle: (ETSizeConstraintStyle)constraint;
- (ETSizeConstraintStyle) itemSizeConstraintStyle;
- (void) setConstrainedItemSize: (NSSize)size;
- (NSSize) constrainedItemSize;
- (void) resizeItems: (NSArray *)items toScaleFactor: (float)factor;

@end
