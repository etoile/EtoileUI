/** <title>ETLayout</title>

	<abstract>Base class to implement pluggable layouts as subclasses and make 
	possible UI composition and transformation at runtime.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETUIObject.h>
#import <EtoileUI/ETResponder.h>

@class COObjectGraphContext;
@class ETDropIndicator, ETTool, ETLineFragment, ETLayoutItem, ETLayoutItemGroup, ETView;
@class ETPositionalLayout;

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
@property (nonatomic, readonly) NSArray *items;
/** See -[ETLayoutItemGroup arrangedItems]. */
@property (nonatomic, readonly) NSArray *arrangedItems;
/** See -[ETLayoutItem size]. */
@property (nonatomic, readonly) NSSize size;
/** See -[ETLayoutItemGroup setLayoutView:]. */
- (void) setLayoutView: (NSView *)aView;
/** See -[ETLayoutItem setNeedsDislay:]. */
- (void) setNeedsDisplay: (BOOL)now;
/** See -[ETLayoutItem isFlipped]. */
@property (nonatomic, getter=isFlipped, readonly) BOOL flipped;
/** See -[ETLayoutItemGroup isChangingSelection]. */
@property (nonatomic, getter=isChangingSelection, readonly) BOOL changingSelection;
/** See -[ETLayoutItemGroup itemScaleFactor]. */
@property (nonatomic, readonly) CGFloat itemScaleFactor;
/** See -[ETLayoutItemGroup visibleContentSize]. */
@property (nonatomic, readonly) NSSize visibleContentSize;
/** See -[ETLayoutItem setContentSize:]. */
- (void) setContentSize: (NSSize)size;
/** See -[ETLayoutItem(Scrollable) isScrollable]. */
@property (nonatomic, getter=isScrollable, readonly) BOOL scrollable;
/** See -[ETLayoutItemGroup visibleItems]. */
@property (nonatomic, readonly) NSArray *visibleItems;
/** See -[ETLayoutItemGroup exposedItems]. */
@property (nonatomic, copy) NSArray *exposedItems;
/** See -[ETLayoutItemGroup setExposedItems:]. */
@end

/** ETLayoutingContext optional methods the layout context might implement.

ETLayout subclasses must check the layout context responds to the method before 
using it. For example, <code>[[[self layoutContext] ifResponds] source]</code>. */
@interface NSObject (ETLayoutingContextOptional)
/** See -[ETLayoutItemGroup source]. */
@property (nonatomic, readonly, strong) id source;
@end

/** Represents a selection state in an item tree. */
@protocol ETItemSelection
/** See -[ETLayoutItemGroup selectionIndex]. */
@property (nonatomic, readonly) NSUInteger selectionIndex;
/** See -[ETLayoutItemGroup selectionIndexes]. */
@property (nonatomic, readonly) NSIndexSet *selectionIndexes;
/** See -[ETLayoutItemGroup selectionIndexPaths]. */
@property (nonatomic, readonly) NSArray *selectionIndexPaths;
/** See -[ETLayoutItemGroup selectedItems]. */
@property (nonatomic, readonly) NSArray *selectedItems;
@end

@protocol ETItemPropertyLayout
/** Returns the laid out item properties that should be visible in the layout.

Implements this method in your subclasses to return which properties are 
presented by the layout.<br />
You can choose to make the ordering in the property array reflects the order 
in which properties are presented by the layout.

If no properties are displayed, must return an empty array. */
@property (nonatomic, copy) NSArray *displayedProperties;
/** Sets the laid out item properties that should be visible in the layout.

Implements this method in your subclasses to adjust which properties are 
presented by the layout.<br />
You can choose to make the order in which properties are presented by the 
layout reflect the ordering in the property array. */
/** <override-dummy /> 
Returns an arbitrary style object used to draw the given property in the layout. 

The returned style object type is determined by each subclass. Usually the 
style will simply be an ETLayoutItem or ETStyle instance.

Implements in your subclass to return a style object per property and documents 
the class or type of the returned object. Several properties can share the 
same style object. */
- (id) styleForProperty: (NSString *)property;
/** Sets a style object to should be used to present the given property in the 
layout. 

The accepted style object type is determined by each subclass. Usually the 
style will simply be an ETLayoutItem or ETStyle instance.<br />
Subclasses must raise an exception when the style object type doesn't match 
their expectation or cannot be used in conjunction with the given property.

Implements in your subclass to adjust the style per property and documents the 
class or type of the accepted object. Suclasses can use the given style directly 
or interpret/convert it. e.g. ETTableLayout converts ETLayoutItem into NSCell 
(internal representation only relevant to the AppKit widget backend). */
- (void) setStyle: (id)style forProperty: (NSString *)property;
@end

/** All subclasses which implement strictly positional layout algorithms as 
described in ETComputedLayout description must conform to this prococol.

Warning: This protocol is very much subject to change. */
@protocol ETComputableLayout <NSObject>
/** See -[ETLayout tearDown]. */
- (void) tearDown;
/** See -[ETLayout setUp:]. */
- (void) setUp: (BOOL)isDeserialization;
/** See -[ETPositionalLayout setIsContentSizeLayout]. */
/** See -[ETPositionalLayout isContentSizeLayout]. */
@property (nonatomic) BOOL isContentSizeLayout;
/** See -[ETLayout validateLayoutContext:]. */
- (void) validateLayoutContext: (id <ETLayoutingContext>)context;
/** See -[ETLayout layoutContext:]. */
@property (nonatomic, readonly, weak) id<ETLayoutingContext> layoutContext;
/** See -[ETComputedLayout setBorderMargin:]. */
- (void) setBorderMargin: (CGFloat)margin;
/** See -[ETComputedLayout itemMargin:]. */
@property (nonatomic) CGFloat itemMargin;
/** See -[ETComputedLayout setItemMargin:]. */
/** See -[ETComputedLayout setHorizontalAlignmentGuidePosition:]. */
- (void) setHorizontalAlignmentGuidePosition: (CGFloat)aPosition;
/** See -[ETLayout renderWithItems:isNewContent:]. */
- (NSSize) renderWithItems: (NSArray *)items isNewContent: (BOOL)isNewContent;
/** See -[ETLayout itemAtLocation:]. */
- (ETLayoutItem *) itemAtLocation: (NSPoint)loc;
@end

/** Warning: Experimental protocol that is subject to change or be removed. */
@protocol ETCompositeLayout
@property (nonatomic, strong) id<ETComputableLayout> positionalLayout;
- (NSSize) renderWithItems: (NSArray *)items isNewContent: (BOOL)isNewContent;
@end

/** @section Layout Size

By default, the layout size is precisely matching the context to which the 
receiver is bound to, based on -[ETLayoutingContext visibleContentSize].

When the context is a scrollable area, the layout size is set to the mininal 
size which encloses all the items once -renderWithItems:isNewContent: has been 
run.

Whether the layout size is computed in horizontal, vertical direction or both
is up to subclasses such as ETComputedLayout, which take in account scroller 
visibility too.

@section Copying

For a copy, -attachedTool is copied. */
@interface ETLayout : ETUIObject <NSCopying>
{
	@private
	ETTool *_attachedTool;
	ETLayoutItemGroup *_layerItem; /* Lazily initialized */
	ETDropIndicator *_dropIndicator;

	BOOL _isSetUp;
	BOOL _isRendering;
	/* Layout and Content Size in Scrollview */
	NSSize _layoutSize;
	NSSize _oldProposedLayoutSize;
	@protected
	CGFloat _previousScaleFactor; // TODO: Remove
}

/** @taskunit Aspect Registration */

+ (void) registerAspects;
+ (void) registerLayout: (ETLayout *)aLayout;
+ (NSSet *) registeredLayouts;
+ (NSSet *) registeredLayoutClasses;

/** @taskunit Initialization */

+ (instancetype) layoutWithObjectGraphContext: (COObjectGraphContext *)aContext;
- (instancetype) initWithObjectGraphContext: (COObjectGraphContext *)aContext NS_DESIGNATED_INITIALIZER;

/** @taskunit Attached Tool */

- (void) setAttachedTool: (ETTool *)newTool;
- (id) attachedTool;
- (void) didChangeAttachedTool: (ETTool *)oldTool
                        toTool: (ETTool *)newTool;

@property (nonatomic, readonly) id responder;

/** @taskunit Layout Context */

@property (nonatomic, readonly, weak) id<ETLayoutingContext> layoutContext;

- (void) tearDown;
- (void) setUp: (BOOL)isDeserialization;

/** @taskunit Type Querying */

@property (nonatomic, getter=isComposite, readonly) BOOL composite;
@property (nonatomic, getter=isPositional, readonly) BOOL positional;
@property (nonatomic, readonly) BOOL isWidget;
@property (nonatomic, getter=isComputedLayout, readonly) BOOL computedLayout;
@property (nonatomic, getter=isOpaque, readonly) BOOL opaque;
@property (nonatomic, getter=isScrollable, readonly) BOOL scrollable;

@property (nonatomic, readonly) BOOL hasScrollers;

/** @taskunit Layout Size Control and Feedback */

@property (nonatomic) NSSize layoutSize;
@property (nonatomic, getter=isContentSizeLayout, readonly) BOOL contentSizeLayout;
@property (nonatomic, getter=isAllContentVisible, readonly) BOOL allContentVisible;
@property (nonatomic, readonly, strong) id<ETComputableLayout> positionalLayout;

/** @taskunit Requesting Internal Layout Updates */

@property (nonatomic, getter=isRendering, readonly) BOOL rendering;
@property (nonatomic, readonly) BOOL canRender;
- (void) renderAndInvalidateDisplay;

/** @taskunit Layouting */

- (NSSize) renderWithItems: (NSArray *)items isNewContent: (BOOL)isNewContent;
@property (nonatomic, readonly) NSSize resetLayoutSize;
- (void) resizeItems: (NSArray *)items
    forNewLayoutSize: (NSSize)newLayoutSize
             oldSize: (NSSize)oldLayoutSize;
- (BOOL) shouldResizeItemsToScaleFactor: (CGFloat)aFactor;
- (void) resizeItems: (NSArray *)items toScaleFactor: (CGFloat)factor;

/** @taskunit Layout Update Dependencies */

@property (nonatomic, getter=isLayoutExecutionItemDependent, readonly) BOOL layoutExecutionItemDependent;

/** @taskunit Presentational Item Tree */

@property (nonatomic, readonly, strong) ETLayoutItemGroup *layerItem;

- (void) mapLayerItemIntoLayoutContext;
- (void) unmapLayerItemFromLayoutContext;
- (void) syncLayerItemGeometryWithSize: (NSSize)aSize;

/** @taskunit Widget Wrapping Support */

- (void) syncLayoutViewWithItem: (ETLayoutItem *)item;

/** @taskunit Selection */

@property (nonatomic, readonly) NSArray *selectedItems;
@property (nonatomic, getter=isChangingSelection, readonly) BOOL changingSelection;

- (void) selectionDidChangeInLayoutContext: (id <ETItemSelection>)aSelection;

/** @taskunit Item Geometry and Display */

- (ETLayoutItem *) itemAtLocation: (NSPoint)location;
- (NSRect) displayRectOfItem: (ETLayoutItem *)item;
- (void) setNeedsDisplayForItem: (ETLayoutItem *)item;

/** @taskunit Item State Indicators */

@property (nonatomic, strong) ETDropIndicator *dropIndicator;
@property (nonatomic, readonly) BOOL preventsDrawingItemSelectionIndicator;

/** @taskunit Sorting */

- (NSArray *) customSortDescriptorsForSortDescriptors: (NSArray *)currentSortDescriptors;

/** @taskunit Framework Private */

- (void) render: (BOOL)isNewContent;
- (void) validateLayoutContext: (id <ETLayoutingContext>)context;

@property (nonatomic, readonly) NSSize proposedLayoutSize;
@property (nonatomic, readonly) ETLayoutItemGroup *contextItem;

@end
