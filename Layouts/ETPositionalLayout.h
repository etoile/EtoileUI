/**
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  May 2013
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETLayout.h>

@class ETTemplateItemLayout;

// NOTE: May be this should be turned into a mask
/** Describes how the layouted items are resized at the beginning of the layout 
rendering.

When the constraint is not ETSizeConstraintStyleNone, the item autoresizing 
provided by -[ETLayoutItem autoresizingMask] won't be respected. */
typedef NS_ENUM(NSUInteger, ETSizeConstraintStyle)
{
/** The items are not resized but let as is. */
	ETSizeConstraintStyleNone,
/** The height of the items is set to the height of -[ETLayout constrainedItemSize]. */
	ETSizeConstraintStyleVertical,
/** The width of the items is set to the width of -[ETLayout constrainedItemSize]. */
	ETSizeConstraintStyleHorizontal,
/** The size of the items are set to -[ETLayout constrainedItemSize]. */
	ETSizeConstraintStyleVerticalHorizontal
};

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

- (instancetype) initWithObjectGraphContext: (COObjectGraphContext *)aContext NS_DESIGNATED_INITIALIZER;

/** @taskunit Layout Size Control and Feedback */

@property (nonatomic) BOOL isContentSizeLayout;

/** @taskunit Item Sizing */

@property (nonatomic) ETSizeConstraintStyle itemSizeConstraintStyle;
@property (nonatomic) NSSize constrainedItemSize;

- (void) resizeItems: (NSArray *)items toScaleFactor: (CGFloat)factor;

/** @taskunit Framework Private */

@property (nonatomic, readonly) ETTemplateItemLayout *contextLayout;

@end
