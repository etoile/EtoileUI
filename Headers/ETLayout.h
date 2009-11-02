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

@class ETInstrument, ETLineFragment, ETLayoutItem, ETLayoutItemGroup, ETView;

/** Methods which must be implemented by an object to be layouted by any
	ETLayout subclasses. The object whose layout items are layouted is the
	layout context (plays a role analog to the graphic context) 
	- layout context is where the layouting occurs
	- graphic context is where the drawing occurs */
@protocol ETLayoutingContext <NSObject>

/* Required */
- (NSArray *) items;
- (NSArray *) arrangedItems;
- (NSArray *) visibleItems;
- (void) setVisibleItems: (NSArray *)items;
- (NSSize) size;
- (void) setSize: (NSSize)size;
- (void) setLayoutView: (NSView *)aView;
- (ETView *) supervisorView;
- (void) setNeedsDisplay: (BOOL)now;
- (BOOL) isFlipped;

/* Required 
   The protocol doesn't truly need these methods, yet they simplify writing new 
   layouts. ETBrowserLayout is the only layout currently relying on them. */
- (ETLayoutItem *) itemAtIndexPath: (NSIndexPath *)path;
- (ETLayoutItem *) itemAtPath: (NSString *)path;

/* Required
   May be next methods should be optional. */
- (float) itemScaleFactor;
- (NSSize) visibleContentSize; /* -documentVisibleRect size */
- (void) setContentSize: (NSSize)size;
//- (NSSize) contentSize;
- (BOOL) isScrollViewShown;

/* Not sure the protocol needs to or should include the next methods */
- (NSArray *) visibleItems;
- (void) setVisibleItems: (NSArray *)items;
- (NSArray *) visibleItemsForItems: (NSArray *)items;
- (void) setVisibleItems: (NSArray *)visibleItems forItems: (NSArray *)items;
- (void) sortWithSortDescriptors: (NSArray *)descriptors recursively: (BOOL)recursively;
//- (void) setShowsScrollView: (BOOL)scroll;

@end

@interface NSObject (ETLayoutingContextOptional)
- (id) source;
@end

/** All subclasses which implement strictly positional layout algorithms as 
    described in ETComputedLayout description must conform to this prococol. */
@protocol ETPositionalLayout <NSObject>
- (void) setLayoutContext: (id <ETLayoutingContext>)context;
- (id <ETLayoutingContext>) layoutContext;
- (void) setItemMargin: (float)margin;
- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent;
- (ETLayoutItem *) itemAtLocation: (NSPoint)loc;
@end

@protocol ETCompositeLayout
- (id <ETPositionalLayout>) positionalLayout;
- (void) setPositionalLayout: (id <ETPositionalLayout>)layout;
- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent;
@end

// NOTE: May be this should be turned into a mask
typedef enum _ETSizeConstraintStyle 
{
	ETSizeConstraintStyleNone,
	ETSizeConstraintStyleVertical,
	ETSizeConstraintStyleHorizontal,
	ETSizeConstraintStyleVerticalHorizontal
} ETSizeConstraintStyle;

/** When you compute your layout in methods -layoutLineForLayoutItems:, 
	-layoutModelForLayoutItems: and -computeLayoutItemLocationsForLayoutModel:
	be careful not to reverse the item order, else selection and sorting will 
	be messed. */

@interface ETLayout : NSObject <NSCopying>
{
	IBOutlet id _layoutContext;
	IBOutlet id _delegate;
	IBOutlet NSView *_displayViewPrototype;
	id _instrument;
	ETLayoutItemGroup *_rootItem;

	BOOL _isLayouting; /* -isRendering */
	
	/* Layout and Content Size in Scrollview */
	NSSize _layoutSize;
	BOOL _layoutSizeCustomized;
	BOOL _maxSizeLayout;
	
	/* Items Sizing */
	NSSize _itemSize;
	ETSizeConstraintStyle _itemSizeConstraintStyle;
	float _previousScaleFactor;
}

+ (void) registerAspects;
+ (void) registerLayout: (ETLayout *)aLayout;
+ (NSSet *) registeredLayouts;
+ (NSSet *) registeredLayoutClasses;

/* Factory  Method */

+ (id) layout;
+ (id) layoutWithLayoutView: (NSView *)view;

/* Initialization */

- (id) initWithLayoutView: (NSView *)layoutView;
- (NSString *) nibName;

- (id) copyWithZone: (NSZone *)aZone layoutContext: (id <ETLayoutingContext>)newContext;
- (void) setUpCopyWithZone: (NSZone *)aZone 
                  original: (ETLayout *)layoutOriginal;

/* Main Accessors */

- (void) setAttachedInstrument: (ETInstrument *)newInstrument;
- (id) attachedInstrument;
- (void) didChangeAttachedInstrument: (ETInstrument *)oldInstrument
                        toInstrument: (ETInstrument *)newInstrument;

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
- (void) setContentSizeLayout: (BOOL)flag;
- (BOOL) isContentSizeLayout;

- (void) setDelegate: (id)delegate;
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
- (void) selectionDidChangeInLayoutContext;

/* Item Geometry and Display */

- (ETLayoutItem *) itemAtLocation: (NSPoint)location;
- (NSRect) displayRectOfItem: (ETLayoutItem *)item;
- (void) setNeedsDisplayForItem: (ETLayoutItem *)item;

/* Item Property Display */

- (NSArray *) displayedProperties;
- (void) setDisplayedProperties: (NSArray *)properties;
- (id) styleForProperty: (NSString *)property;
- (void) setStyle: (id)style forProperty: (NSString *)property;

@end


@interface ETLayout (Delegate)

/** If you want to render layout items in different ways depending on the layout
	settings, you can implement this delegate method. When implemented in a
	delegate object, -[ETLayoutItem render] isn't called automatically anymore
	and you are in charge of calling it in this delegate method if you want to. */
- (void) layout: (ETLayout *)layout renderLayoutItem: (ETLayoutItem *)item;
- (NSView *) layout: (ETLayout *)layout replacementViewForItem: (ETLayoutItem *)item;

@end

