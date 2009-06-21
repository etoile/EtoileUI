/*
	ETLayout.h
	
	Base class to implement pluggable layouts as subclasses and make possible
	UI composition and transformation at runtime.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
 
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETContainer, ETLayoutLine, ETLayoutItem, ETLayoutItemGroup, ETView;

/** Methods which must be implemented by an object to be layouted by any
	ETLayout subclasses. The object whose layout items are layouted is the
	layout context (plays a role analog to the graphic context) 
	- layout context is where the layouting occurs
	- graphic context is where the drawing occurs */
@protocol ETLayoutingContext

/* Required */
- (NSArray *) items;
- (NSArray *) arrangedItems;
- (NSArray *) visibleItems;
- (void) setVisibleItems: (NSArray *)items;
- (NSSize) size;
- (void) setSize: (NSSize)size;
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

/** All subclasses which implement strictly positional layout algorithms as 
    described in ETComputedLayout description must conform to this prococol. */
@protocol ETPositionalLayout
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

@interface ETLayout : NSObject
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

+ (void) registerLayoutClass: (Class)layoutClass;
+ (NSSet *) registeredLayoutClasses;

/* Factory  Method */

+ (id) layout;
+ (id) layoutWithLayoutView: (NSView *)view;
- (id) layoutPrototype;

/* Initialization */

- (id) initWithLayoutView: (NSView *)layoutView;
- (NSString *) nibName;

/* Main Accessors */

- (void) setAttachedInstrument: (id)anInstrument;
- (id) attachedInstrument;
//- (void) setContainer: (ETContainer *)newContainer;
- (ETContainer *) container;

- (void) setLayoutContext: (id <ETLayoutingContext>)context;
- (id <ETLayoutingContext>) layoutContext;
- (void) tearDown;
- (void) setUp;

/* -isSemantic is initially defined by superclass ETStyle */
- (BOOL) isSemantic;
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

//-setStyleTemplate:
//-styleTemplate // apply to each layouted item (like a border)

/* Layouting */

- (BOOL) isRendering;
- (BOOL) canRender;
- (void) render: (NSDictionary *)inputValues;
- (void) render: (NSDictionary *)inputValues isNewContent: (BOOL)isNewContent;
- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent;

- (void) resetLayoutSize;
- (void) resizeLayoutItems: (NSArray *)items toScaleFactor: (float)factor;

/* Utility Methods */

- (ETLayoutItem *) itemAtLocation: (NSPoint)location;
- (NSRect) displayRectOfItem: (ETLayoutItem *)item;
//- (BOOL) isHitTestEnabledAtPoint: (NSPoint)location;

/* Wrapping Existing View */

- (ETLayoutItemGroup *) rootItem;
- (void) mapRootItemIntoLayoutContext;
- (void) unmapRootItemFromLayoutContext;

- (void) setLayoutView: (NSView *)protoView;
- (NSView *) layoutView;
- (void) setUpLayoutView;
- (void) syncLayoutViewWithItem: (ETLayoutItem *)item;

- (NSArray *) selectedItems;
- (NSArray *) selectionIndexPaths;
- (void) selectionDidChangeInLayoutContext;

/* ETDecoratorLayout */

//- (BOOL) isDecorator;

/** Returns the decorated item
	Overrides this method in your subclasses to implement a decorator layout */
//-representedItem
/** Sets the decorated item */
//-setRepresentedItem

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

