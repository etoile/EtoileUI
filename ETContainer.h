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
	BOOL _multipleSelectionAllowed;
	BOOL _emptySelectionAllowed;

	/* Used by ETViewLayout to know which items are displayed whether the 
	   container uses a source or simple provides items directly. */
	NSMutableArray *_layoutItemCache;
}

- (id) initWithFrame: (NSRect)rect views: (NSArray *)views;

- (NSString *) path;
- (void) setPath: (NSString *)path;
//- (ETLayoutItem *) layoutItemAtPath: (NSString *)path;

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

/* Basic drag and drop support by index */
- (BOOL) container: (ETContainer *)container writeItemsWithIndexes: (NSIndexSet *)indexes toPasteboard: (NSPasteboard *)pboard;
- (BOOL) container: (ETContainer *)container acceptDrop: (id <NSDraggingInfo>)info atIndex: (int)index;
- (NSDragOperation) container: (ETContainer *)container validateDrop: (id <NSDraggingInfo>)info atIndex: (int)index;

/* Drag and drop support by key and index path */
// FIXME: Create new set structure NSPathSet rather than using NSArray
- (BOOL) container: (ETContainer *)container writeItemsWithPaths: (NSArray *)paths toPasteboard: (NSPasteboard *)pboard;
- (BOOL) container: (ETContainer *)container acceptDrop: (id <NSDraggingInfo>)info atPath: (NSString *)path;
- (NSDragOperation) container: (ETContainer *)container validateDrop: (id <NSDraggingInfo>)info atPath: (NSString *)path;

- (BOOL) container: (ETContainer *)container writeItemsWithPaths: (NSArray *)paths toPasteboard: (NSPasteboard *)pboard;
- (BOOL) container: (ETContainer *)container acceptDrop: (id <NSDraggingInfo>)info atPath: (NSString *)path;
- (NSDragOperation) container: (ETContainer *)container validateDrop: (id <NSDraggingInfo>)info atPath: (NSString *)path;

/*- (BOOL) container: (ETContainer *)container writeDraggedItems: (NSArray *)items toPasteboard: (NSPasteboard *)pboard;
- (BOOL) container: (ETContainer *)container acceptDroppedItem: (ETLayoutItem *)item atPath: (NSString *)path draggingInfo: (id <NSDraggingInfo>)info;
- (NSDragOperation) container: (ETContainer *)container validateDroppedItem: (ETLayoutItem *)item atPath: (NSString *)path draggingInfo:(id <NSDraggingInfo>)info;*/

// TODO: Extend the informal protocol to propogate group/ungroup actions in 
// they can be properly reflected on model side.

@end

/*- (BOOL) container: (ETContainer *)container writeRowsWithIndexes: (NSIndexSet *)indexes toPasteboard: (NSPasteboard *)pboard;
- (BOOL) container: (ETContainer *)container acceptDrop: (id <NSDraggingInfo>)info atIndex: (int)index inParentItem: (ETLayoutItem *)targetItem;
- (NSDragOperation) container: (ETContainer *)container validateDrop: (id <NSDraggingInfo>)info atProposedIndex: (int)selection inParentItem: (ETLayoutItem *)targetItem;*/

/*- (BOOL) container: (ETContainer *)container writeRowsWithIndexes: (NSIndexSet *)indexes toPasteboard: (NSPasteboard *)pboard
- (BOOL) container: (ETContainer *)container acceptDrop: (id <NSDraggingInfo>)info index: (int)index dropOperation :(ETContainerDropOperation)operation
- (NSDragOperation) container: (ETContainer *)container validateDrop: (id <NSDraggingInfo>)info proposedIndex: (int)selection proposedDropOperation: (ETContainerDropOperation)operation*/

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
