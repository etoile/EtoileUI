/** <title>ETLayout</title>

	<abstract>Base class to implement pluggable layouts as subclasses and make 
	possible UI composition and transformation at runtime.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETDropIndicator, ETTool, ETLineFragment, ETLayoutItem, ETLayoutItemGroup, ETView;

/** Methods which must be implemented by an object to be layouted by any 
ETLayout subclasses. The object whose layout items are layouted is the layout 
context (plays a role analog to the graphic context):

<list>
<item>layout context is where the layouting occurs</item>
<item>graphic context is where the drawing occurs</item>
</list>

Some ETLayout subclasses might extend the protocol (e.g. ETWidgetLayout 
requires the layout context to conform to ETWidgetLayoutingContext), but in 
most cases requiring additional methods shouldn't be necessary.

Although the layout context is expected to be an ETLayoutItemGroup usually, 
it doesn't have to.<br />
ETLayoutingContext describes how a layout is expected to interact with a layout 
item and limit the interaction complexity between ETLayoutItemGroup and 
ETLayout. */
@protocol ETLayoutingContext <NSObject>
// TODO: Remove in favor of -arrangedItems
- (NSArray *) items;
/** See -[ETLayoutItemGroup arrangedItems]. */
- (NSArray *) arrangedItems;
/** See -[ETLayoutItem size]. */
- (NSSize) size;
/** See -[ETLayoutItem setSize:]. */
- (void) setSize: (NSSize)size;
/** See -[ETLayoutItemGroup setLayoutView:]. */
- (void) setLayoutView: (NSView *)aView;
/** See -[ETLayoutItem setNeedsDislay:]. */
- (void) setNeedsDisplay: (BOOL)now;
/** See -[ETLayoutItem isFlipped]. */
- (BOOL) isFlipped;
/** See -[ETLayoutItemGroup isChangingSelection]. */
- (BOOL) isChangingSelection;
/** See -[ETLayoutItemGroup itemScaleFactor]. */
- (float) itemScaleFactor;
/** See -[ETLayoutItemGroup visibleContentSize]. */
- (NSSize) visibleContentSize;
/** See -[ETLayoutItem setContentSize:]. */
- (void) setContentSize: (NSSize)size;
// TODO: Replace with -isScrollable
- (BOOL) isScrollViewShown;
/** See -[ETLayoutItemGroup visibleItems]. */
- (NSArray *) visibleItems;
/** See -[ETLayoutItemGroup setVisibleItems:]. */
- (void) setVisibleItems: (NSArray *)items;
@end

/** ETLayoutingContext optional methods the layout context might implement.

ETLayout subclasses must check the layout context responds to the method before 
using it. For example, <code>[[[self layoutContext] ifResponds] source]</code>. */
@interface NSObject (ETLayoutingContextOptional)
/** See -[ETLayoutItemGroup source]. */
- (id) source;
@end

/** Represents a selection state in an item tree. */
@protocol ETItemSelection
/** See -[ETLayoutItemGroup selectionIndex]. */
- (unsigned int) selectionIndex;
/** See -[ETLayoutItemGroup selectionIndexes]. */
- (NSMutableIndexSet *) selectionIndexes;
/** See -[ETLayoutItemGroup selectionIndexPaths]. */
- (NSArray *) selectionIndexPaths;
/** See -[ETLayoutItemGroup selectedItems]. */
- (NSArray *) selectedItems;
@end

/** All subclasses which implement strictly positional layout algorithms as 
described in ETComputedLayout description must conform to this prococol.

Warning: This protocol is very much subject to change. */
@protocol ETPositionalLayout <NSObject>
/** See -[ETLayout copyWithZone:layoutContext:]. */
- (id) copyWithZone: (NSZone *)aZone layoutContext: (id <ETLayoutingContext>)newContext;
/** See -[ETLayout setLayoutContext:]. */
- (void) setLayoutContext: (id <ETLayoutingContext>)context;
/** See -[ETLayout layoutContext:]. */
- (id <ETLayoutingContext>) layoutContext;
/** See -[ETComputedLayout setBorderMargin:]. */
- (void) setBorderMargin: (float)margin;
/** See -[ETComputedLayout setItemMargin:]. */
- (void) setItemMargin: (float)margin;
/** See -[ETLayout renderWithLayoutItems:isNewContent:]. */
- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent;
/** See -[ETLayout itemAtLocation:]. */
- (ETLayoutItem *) itemAtLocation: (NSPoint)loc;
@end

/** Warning: Experimental protocol that is subject to change or be removed. */
@protocol ETCompositeLayout
- (id <ETPositionalLayout>) positionalLayout;
- (void) setPositionalLayout: (id <ETPositionalLayout>)layout;
- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent;
@end

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


@interface ETLayout : NSObject <NSCopying>
{
	id _layoutContext; /* Weak reference */
	ETLayoutItemGroup *_rootItem; /* Lazily initialized */

	@private
	IBOutlet id delegate; /* Weak reference */
	IBOutlet NSView *layoutView;
	ETTool *_tool;
	ETDropIndicator *_dropIndicator;

	BOOL _isLayouting; /* -isRendering */	
	/* Layout and Content Size in Scrollview */
	NSSize _layoutSize;
	BOOL _layoutSizeCustomized;
	BOOL _maxSizeLayout;

	/* Items Sizing */
	NSSize _itemSize;
	ETSizeConstraintStyle _itemSizeConstraintStyle;
	@protected
	float _previousScaleFactor; // TODO: Remove
}

+ (void) registerAspects;
+ (void) registerLayout: (ETLayout *)aLayout;
+ (NSSet *) registeredLayouts;
+ (NSSet *) registeredLayoutClasses;

+ (Class) layoutClassForLayoutView: (NSView *)layoutView;

/* Factory  Method */

+ (id) layout;
+ (id) layoutWithLayoutView: (NSView *)view;

/* Initialization */

- (id) initWithLayoutView: (NSView *)aView;

- (id) copyWithZone: (NSZone *)aZone layoutContext: (id <ETLayoutingContext>)newContext;
- (void) setUpCopyWithZone: (NSZone *)aZone 
                  original: (ETLayout *)layoutOriginal;

/* Main Accessors */

- (void) setAttachedTool: (ETTool *)newTool;
- (id) attachedTool;
- (void) didChangeAttachedTool: (ETTool *)oldTool
                        toTool: (ETTool *)newTool;

- (void) setLayoutContext: (id <ETLayoutingContext>)context;
- (id <ETLayoutingContext>) layoutContext;
- (void) tearDown;
- (void) setUp;

- (BOOL) isComposite;
- (BOOL) isPositional;
- (BOOL) isWidget;
- (BOOL) isComputedLayout;
- (BOOL) isOpaque;
- (BOOL) isScrollable;

- (BOOL) hasScrollers;

/* Size And Utility Accessors */

- (void) setUsesCustomLayoutSize: (BOOL)flag;
- (BOOL) usesCustomLayoutSize;
- (void) setLayoutSize: (NSSize)size;
- (NSSize) layoutSize;
// Not sure the two next methods will be kept public
- (void) setIsContentSizeLayout: (BOOL)flag;
- (BOOL) isContentSizeLayout;

- (void) setDelegate: (id)aDelegate;
- (id) delegate;

/* Item Sizing Accessors */

- (void) setItemSizeConstraintStyle: (ETSizeConstraintStyle)constraint;
- (ETSizeConstraintStyle) itemSizeConstraintStyle;
- (void) setConstrainedItemSize: (NSSize)size;
- (NSSize) constrainedItemSize;

/* Sizing Methods */

- (BOOL) isAllContentVisible;
//- (void) adjustLayoutSizeToContentSize;

/* Layouting */

- (BOOL) isRendering;
- (BOOL) canRender;
- (void) render: (NSDictionary *)inputValues isNewContent: (BOOL)isNewContent;
- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent;
- (void) renderAndInvalidateDisplay;

- (void) resetLayoutSize;
- (void) resizeLayoutItems: (NSArray *)items toScaleFactor: (float)factor;

/* Presentational Item Tree */

- (ETLayoutItemGroup *) rootItem;
- (void) mapRootItemIntoLayoutContext;
- (void) unmapRootItemFromLayoutContext;
- (void) syncRootItemGeometryWithSize: (NSSize)aSize;

/* Wrapping Existing View */

- (void) setLayoutView: (NSView *)protoView;
- (NSView *) layoutView;
- (void) setUpLayoutView;
- (void) syncLayoutViewWithItem: (ETLayoutItem *)item;

/* Selection */

- (NSArray *) selectedItems;
- (void) selectionDidChangeInLayoutContext: (id <ETItemSelection>)aSelection;
- (BOOL) isChangingSelection;

/* Item Geometry and Display */

- (ETLayoutItem *) itemAtLocation: (NSPoint)location;
- (NSRect) displayRectOfItem: (ETLayoutItem *)item;
- (void) setNeedsDisplayForItem: (ETLayoutItem *)item;

/* Item Property Display */

- (NSArray *) displayedProperties;
- (void) setDisplayedProperties: (NSArray *)properties;
- (id) styleForProperty: (NSString *)property;
- (void) setStyle: (id)style forProperty: (NSString *)property;

/* Pick & Drop */

- (ETDropIndicator *) dropIndicator;
- (void) setDropIndicator: (ETDropIndicator *)aStyle;

/* Sorting */

- (NSArray *) customSortDescriptorsForSortDescriptors: (NSArray *)currentSortDescriptors;

@end
