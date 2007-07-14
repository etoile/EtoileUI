//
//  ETContainer.h
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 26/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETLayoutItem, ETViewLayout, ETLayer, ETLayoutGroupItem;

/** Forwarding Chain 

	View returned by -[ETLayoutItem view] --> ETLayer (optional) -
	-> ETContainer --> ETLayout --> View returned by -[ETLayout displayView]
	
	By default, the forwarding chain is broken is two separate chains:
	
	-[ETLayoutItem view] --> ETLayer (optional) -> ETContainer
	
	and
	
	ETContainer --> ETLayout --> -[ETLayout displayView]
	
	The possibility to use the first separate chain and the whole one is still
	under evaluation.
	
 */


// ETComponentView
@interface ETContainer : NSControl
{
	/* Stores items when no source is used. May stores layers when no source is 
	   used, this is not yet decided. */
	NSMutableArray *_layoutItems;
	ETViewLayout *_containerLayout;
	NSView *_displayView;
	NSScrollView *_scrollView;
	
	BOOL _autolayout;
	
	// NOTE: path ivar may move to ETLayoutItem later, it could make more sense
	// in this way. Then we would have a method -owner or -layoutItemOwner on
	// ETContainer that returns an ETLayoutItemGroup (generated on the fly if needed).
	NSString *_path; /* A path type will replace NSString later */
	id _dataSource;
	id _delegate; // TODO: check this ivar doesn't overshadow a superclass ivar
	
	BOOL _subviewHitTest;
	SEL _doubleClickAction;
	id _target;
	ETLayoutItem *_clickedItem;
	
	float _itemScale;
	
	/* Acts as a cache, selection state is stored in layout item by default */
	NSMutableIndexSet *_selection;
	NSRect _selectionRect;
	BOOL _multipleSelectionAllowed;
	BOOL _emptySelectionAllowed;
	BOOL _internalDragAllowed;
	/* Insertion indicator to erase on next mouse move event in a drag */
	NSRect _prevInsertionIndicatorRect; 

	/* Used by ETViewLayout to know which items are displayed whether the 
	   container uses a source or simple provides items directly. */
	NSMutableArray *_layoutItemCache;
}

- (id) initWithFrame: (NSRect)rect views: (NSArray *)views;

- (NSString *) path;
- (void) setPath: (NSString *)path;
//- (ETLayoutItem *) layoutItemAtPath: (NSString *)path;

- (BOOL) isAutolayout;
- (void) setAutolayout: (BOOL)flag;
- (void) updateLayout;

- (ETViewLayout *) layout;
- (void) setLayout: (ETViewLayout *)layout;

- (NSView *) displayView;

- (id) source;
- (void) setSource: (id)source;

- (id) delegate;
- (void) setDelegate: (id) delegate;

- (BOOL) letsLayoutControlsScrollerVisibility;
- (void) setLetsLayoutControlsScrollerVisibility: (BOOL)layoutControl;
- (BOOL) hasVerticalScroller;
- (void) setHasVerticalScroller: (BOOL)scroll;
- (BOOL) hasHorizontalScroller;
- (void) setHasHorizontalScroller: (BOOL)scroll;

/*
- (ETLayoutAlignment) layoutAlignment;
- (void) setLayoutAlignment: (ETLayoutAlignment)alignment;

- (ETLayoutOverflowStyle) overflowStyle;
- (void) setOverflowStyle: (ETLayoutOverflowStyle);
*/

/* Primary methods to interact with layout item and container
   NOTE: Throw an exception when a source is used */

- (void) addItem: (ETLayoutItem *)item;
- (void) insertItem: (ETLayoutItem *)item atIndex: (int)index;
- (void) removeItem: (ETLayoutItem *)item;
- (void) removeItemAtIndex: (int)index;
- (ETLayoutItem *) itemAtIndex: (int)index;
- (int) indexOfItem: (ETLayoutItem *)item;
- (NSArray *) items;
- (void) addItems: (NSArray *)items;
- (void) removeItems: (NSArray *)items;
- (void) removeAllItems;

/* Facility Methods For View-based Layout Items
   NOTE: Throw an exception when a source is used */
- (void) addView: (NSView *)view;
- (void) removeView: (NSView *)view;
- (void) removeViewAtIndex: (int)index;
- (NSView *) viewAtIndex: (int)index;
- (void) addViews: (NSArray *)views;
- (void) removeViews: (NSArray *)views;

/*- (void) addView: (NSView *)view withIdentifier: (NSString *)identifier;
- (void) removeViewForIdentifier:(NSString *)identifier;
- (NSView *) viewForIdentifier: (NSString *)identifier;*/

// Private use
- (void) setDisplayView: (NSView *)view;
- (BOOL) hasScrollView;
- (void) setHasScrollView: (BOOL)scroll;

/* Selection */

- (void) setSelectionIndexes: (NSIndexSet *)selection;
- (NSMutableIndexSet *) selectionIndexes;
- (void) setSelectionIndex: (int)index;
- (int) selectionIndex;
- (BOOL) allowsMultipleSelection;
- (void) setAllowsMultipleSelection: (BOOL)multiple;
- (BOOL) allowsEmptySelection;
- (void) setAllowsEmptySelection: (BOOL)empty;

/* Dragging */

- (void) setAllowsInternalDragging: (BOOL)flag;
- (BOOL) allowsInternalDragging;

/* Groups and Stacks */

/*- (ETLayoutGroupItem *) groupAllItems;
- (ETLayoutGroupItem *) groupItems: (NSArray *)items;
- (ETLayoutGroupItem *) ungroupItems: (ETLayoutGroupItem *)itemGroup;*/

// NOTE: Not sure it is worth to have these methods since we can stack a group
// by using ETLayoutGroupItem API
/*- (ETLayoutGroupItem *) stackAllItems;
- (ETLayoutGroupItem *) stackItems: (NSArray *)items;
- (ETLayoutGroupItem *) unstackItems: (ETLayoutGroupItem *)itemGroup;*/

/* Item scaling */

- (float) itemScaleFactor;
- (void) setItemScaleFactor: (float)factor;

/* Layers */

- (void) addLayer: (ETLayoutItem *)item;
- (void) insertLayer: (ETLayoutItem *)item atIndex: (int)layerIndex;
- (void) insertLayer: (ETLayoutItem *)item atZIndex: (int)z;
- (void) removeLayer: (ETLayoutItem *)item;
- (void) removeLayerAtIndex: (int)layerIndex;

/* Rendering Chain */

- (void) render;

/* Actions */

- (void) setDoubleAction: (SEL)selector;
- (SEL) doubleAction;
- (ETLayoutItem *) clickedItem;

- (BOOL) enablesSubviewHitTest;
- (void) setEnablesSubviewHitTest: (BOOL)hit;

@end

@interface ETContainer (ETContainerSource)

/* Basic index retrieval */
- (int) numberOfItemsInContainer: (ETContainer *)container;
- (ETLayoutItem *) itemAtIndex: (int)index inContainer: (ETContainer *)container;

/* Key and index path retrieval useful with containers displaying tree structure */
- (int) numberOfItemsAtPath: (NSString *)keyPath inContainer: (ETContainer *)container;
- (ETLayoutItem *) itemAtPath: (NSString *)keyPath inContainer: (ETContainer *)container;

/* Extra infos */
- (NSArray *) displayedItemPropertiesInContainer: (ETContainer *)container;
- (int) firstVisibleItemInContainer: (ETContainer *)container;
- (int) lastVisibleItemInContainer: (ETContainer *)container;

/* Pick and drop support and Bindings support by index */
/* When operation is a pick and drop one (either copy/paste or drag/drop), 
   - 'container:addItems:operation:' is called when no selection is set
   - 'container:insertItems:atIndexes:operation:' is called when a selection exists */
/* These methods make also possible to use your data source with bindings if 
   you use the specifically designed controller ETSourceController */
- (BOOL) container: (ETContainer *)container addItems: (NSArray *)items operation: (id)op;
- (BOOL) container: (ETContainer *)container insertItems: (NSArray *)items atIndexes: (NSIndexSet *)indexes operation: (id)op;
- (BOOL) container: (ETContainer *)container removeItems: (NSArray *)items atIndexes: (NSIndexSet *)indexes operation: (id)op;

/* Pick and drop support and Bindings support by key and index path */
- (BOOL) container: (ETContainer *)container addItems: (NSArray *)items atPath: (NSString *)path operation: (id)op;
- (BOOL) container: (ETContainer *)container insertItems: (NSArray *)items atPaths: (NSArray *)paths operation: (id)op;
- (BOOL) container: (ETContainer *)container removeItems: (NSArray *)items atPaths: (NSArray *)paths operation: (id)op;


/* Custom drag and drop support by index (only needed if you want to override 
   pick and drop support to get a more precise control over drag and drop) */
- (BOOL) container: (ETContainer *)container writeItems: (NSArray *)layoutItems toPasteboard: (NSPasteboard *)pboard;
- (BOOL) container: (ETContainer *)container acceptDrop: (id <NSDraggingInfo>)info atIndex: (int)index;
- (NSDragOperation) container: (ETContainer *)container validateDrop: (id <NSDraggingInfo>)info atIndex: (int)index;

/* Custom Drag and drop support by key and index path */
// FIXME: Create new set structure NSPathSet rather than using NSArray
- (BOOL) container: (ETContainer *)container writeItems: (NSArray *)items toPasteboard: (NSPasteboard *)pboard;
- (BOOL) container: (ETContainer *)container acceptDrop: (id <NSDraggingInfo>)info atPath: (NSString *)path;
- (NSDragOperation) container: (ETContainer *)container validateDrop: (id <NSDraggingInfo>)info atPath: (NSString *)path;

/*- (BOOL) container: (ETContainer *)container writeDraggedItems: (NSArray *)items toPasteboard: (NSPasteboard *)pboard;
- (BOOL) container: (ETContainer *)container acceptDroppedItem: (ETLayoutItem *)item atPath: (NSString *)path draggingInfo: (id <NSDraggingInfo>)info;
- (NSDragOperation) container: (ETContainer *)container validateDroppedItem: (ETLayoutItem *)item atPath: (NSString *)path draggingInfo:(id <NSDraggingInfo>)info;*/
/*- (BOOL) container: (ETContainer *)container dragItems: ;
- (BOOL) container: (ETContainer *)container acceptDropItems: atIndex: (int)index;
- (NSDragOperation) container: (ETContainer *)container dropItems: atIndex: (int)index;*/

// TODO: Extend the informal protocol to propogate group/ungroup actions in 
// they can be properly reflected on model side.

@end

@interface ETContainer (ETContainerDelegate)

- (void) containerSelectionDidChange: (NSNotification *)notif;
- (void) containerShouldStackItem: (NSNotification *)notif;
- (void) containerDidStackItem: (NSNotification *)notif;
- (void) containerShouldGroupItem: (NSNotification *)notif;
- (void) containerDidGroupItem: (NSNotification *)notif;
//- (void) containerDoubleClickedItem: (NSNotification *)notif;

@end

@interface ETContainer (WindowServerMetamodel)

+ rootContainer;
+ screenRootContainer;
+ localRootContainer;
+ windowRootContainer;

@end


extern NSString *ETContainerSelectionDidChangeNotification;
