//
//  ETViewLayout.h
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 26/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETContainer, ETViewLayoutLine, ETLayoutItem;


@interface ETViewLayout : NSObject
{
	IBOutlet ETContainer *_container;
	IBOutlet id _delegate;
	IBOutlet NSView *_displayViewPrototype;
	
	/* Layout and Content Size in Scrollview */
	NSSize _layoutSize;
	BOOL _layoutSizeCustomized;
	BOOL _maxSizeLayout;
	
	/* Items Sizing */
	NSSize _itemSize;
	BOOL _itemSizeConstrained;
	BOOL _itemSizeConstrainedV;
	BOOL _itemSizeConstrainedH;
}

/* Factory  Method */

- (id) layoutPrototype;

/* Main Accessors */

- (void) setContainer: (ETContainer *)newContainer;
- (ETContainer *) container;

/* Size And Utility Accessors */

- (void) setUsesCustomLayoutSize: (BOOL)flag;
- (BOOL) usesCustomLayoutSize;
- (void) setLayoutSize: (NSSize)size;
- (NSSize) layoutSize;
- (void) setContentSizeLayout: (BOOL)flag;
- (BOOL) isContentSizeLayout;

- (void) setDelegate: (id)delegate;
- (id) delegate;

/* Item Sizing Accessors */

// FIXME: Would be better to use -setItemSizeConstraintStyle: rather than
// distinct methods for horizontal, vertical and double constraints.

- (void) setUsesConstrainedItemSize: (BOOL)flag;
- (BOOL) usesContrainedItemSize;
- (void) setConstrainedItemSize: (NSSize)size;
- (NSSize) constrainedItemSize;
- (void) setVerticallyConstrainedItemSize: (BOOL)flag;
- (BOOL) verticallyConstrainedItemSize;
- (void) setHorizontallyConstrainedItemSize: (BOOL)flag;
- (BOOL) horizontallyConstrainedItemSize;

/* Sizing Methods */

- (BOOL) isAllContentVisible;
- (void) adjustLayoutSizeToContentSize;

/* Layouting */

- (void) render;
- (void) renderWithLayoutItems: (NSArray *)items inContainer: (ETContainer *)container;
- (void) renderWithSource: (id)source inContainer: (ETContainer *)container;

- (ETViewLayoutLine *) layoutLineForViews: (NSArray *)views inContainer: (ETContainer *)viewContainer;
- (NSArray *) layoutModelForViews: (NSArray *)views inContainer: (ETContainer *)viewContainer;
- (void) computeViewLocationsForLayoutModel: (NSArray *)layoutModel inContainer: (ETContainer *)container;

- (void) resizeLayoutItems: (NSArray *)items toScaleFactor: (float)factor;

/* Utility Methods */

- (ETLayoutItem *) itemAtLocation: (NSPoint)location;
- (NSRect) displayRectOfItem: (ETLayoutItem *)item;

// Private use
- (void) adjustLayoutSizeToSizeOfContainer: (ETContainer *)container;

/* Wrapping Existing View */

- (void) setDisplayViewPrototype: (NSView *)protoView;
- (NSView *) displayViewPrototype;

@end


@interface ETViewLayout (Delegate)

/** If you want to render layout items in different ways depending on the layout
	settings, you can implement this delegate method. When implemented in a
	delegate object, -[ETLayoutItem render] isn't called automatically anymore
	and you are in charge of calling it in this delegate method if you want to. */
- (void) layout: (ETViewLayout *) renderLayoutItem: (ETLayoutItem *)item;

@end
