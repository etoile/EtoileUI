/*
	ETContainer.h
	
	Description forthcoming.
 
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
#import <EtoileUI/ETView.h>

@class ETLayoutItem, ETLayout, ETLayer, ETLayoutItemGroup, ETSelection;
@protocol ETLayoutingContext, ETObjectInspection, ETInspector;

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
@interface ETContainer : ETView <ETObjectInspection> //ETLayoutingContext
{
	IBOutlet NSScrollView *_scrollView;

	NSView *_displayView;
	BOOL _flipped;
	
	// NOTE: path ivar may move to ETLayoutItem later, it could make more sense
	// in this way. Then we would have a method -owner or -layoutItemOwner on
	// ETContainer that returns an ETLayoutItemGroup (generated on the fly if needed).
	NSString *_path; /* A path type will replace NSString later */
	id _dataSource;
	id _delegate; // TODO: check this ivar doesn't overshadow a superclass ivar
	
	BOOL _subviewHitTest;
	SEL _doubleClickAction;
	id _target;
	ETLayoutItem *_doubleClickedItem;
	
	float _itemScale;
	
	/* Acts as a cache, selection state is stored in layout item by default */
	NSMutableIndexSet *_selection;
	ETSelection *_selectionShape;
	NSRect _selectionRect;
	BOOL _multipleSelectionAllowed;
	BOOL _emptySelectionAllowed;
	BOOL _dragAllowed;
	BOOL _dropAllowed;
	/* Insertion indicator to erase on next mouse move event in a drag */
	NSRect _prevInsertionIndicatorRect; 
	
	id <ETInspector> _inspector;
}

- (id) initWithLayoutView: (NSView *)layoutView;

- (ETLayoutItem *) layoutItem;

/* Basic Accessors */

- (NSString *) representedPath;
- (void) setRepresentedPath: (NSString *)path;
- (id) source;
- (void) setSource: (id)source;
- (id) delegate;
- (void) setDelegate: (id)delegate;

- (BOOL) isFlipped;
- (void) setFlipped: (BOOL)flag;

/* Layout */

- (BOOL) isAutolayout;
- (void) setAutolayout: (BOOL)flag;
- (void) updateLayout;
- (void) reloadAndUpdateLayout;

- (ETLayout *) layout;
- (void) setLayout: (ETLayout *)layout;

- (NSView *) displayView;
- (void) setDisplayView: (NSView *)view;

/* - (ETLayoutAlignment) layoutAlignment;
- (void) setLayoutAlignment: (ETLayoutAlignment)alignment;

- (ETLayoutOverflowStyle) overflowStyle;
- (void) setOverflowStyle: (ETLayoutOverflowStyle); */

/* Inspecting */

- (IBAction) inspect: (id)sender;
- (void) setInspector: (id <ETInspector>)inspector;
/** Returns inspector based on selection */
- (id <ETInspector>) inspector;
- (id <ETInspector>) inspectorForItems: (NSArray *)items;

/* Scrolling */

- (BOOL) letsLayoutControlsScrollerVisibility;
- (void) setLetsLayoutControlsScrollerVisibility: (BOOL)layoutControl;
- (BOOL) hasVerticalScroller;
- (void) setHasVerticalScroller: (BOOL)scroll;
- (BOOL) hasHorizontalScroller;
- (void) setHasHorizontalScroller: (BOOL)scroll;
- (NSScrollView *) scrollView;
- (void) setScrollView: (NSScrollView *)scrollView;
   
/* Layout Item Tree */

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

/* Selection */

- (NSArray *) selectionIndexPaths;
- (void) setSelectionIndexPaths: (NSArray *)indexPaths;
- (void) setSelectionIndexes: (NSIndexSet *)selection;
- (NSMutableIndexSet *) selectionIndexes;
- (void) setSelectionIndex: (int)index;
- (int) selectionIndex;
- (BOOL) allowsMultipleSelection;
- (void) setAllowsMultipleSelection: (BOOL)multiple;
- (BOOL) allowsEmptySelection;
- (void) setAllowsEmptySelection: (BOOL)empty;

/*- (void) setSelectionShape: (ETSelection *)shape;
- (ETSelection *) selectionShape;*/

/* Dragging */

/*- (void) setDraggingAllowedForTypes: (NSArray *)types;
- (NSArray *) allowedDraggingTypes;
- (void) setDroppingAllowedForTypes: (NSArray *)types;
- (NSArray *) allowedDroppingTypes;
- (void) setDropTargetTypes: (NSArray *)types;
- (NSArray *)dropTargetTypes;*/

// NOTE: Following methods are deprecated
- (void) setAllowsDragging: (BOOL)flag;
- (BOOL) allowsDragging;
- (void) setAllowsDropping: (BOOL)flag;
- (BOOL) allowsDropping;

/* Groups and Stacks */

- (void) stack: (id)sender;

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

- (void) setTarget: (id)target;
- (id) target;
- (void) setDoubleAction: (SEL)selector;
- (SEL) doubleAction;
- (ETLayoutItem *) doubleClickedItem;

- (BOOL) isHitTestEnabled;
- (void) setEnablesHitTest: (BOOL)hit;

@end

@interface ETContainer (ETContainerSource)

/* Basic index retrieval */
- (int) numberOfItemsInContainer: (ETContainer *)container;
- (ETLayoutItem *) itemAtIndex: (int)index inContainer: (ETContainer *)container;

/* Key and index path retrieval useful with containers displaying tree structure */
- (int) container: (ETContainer *)container numberOfItemsAtPath: (NSIndexPath *)indexPath;
- (ETLayoutItem *) container: (ETContainer *)container itemAtPath: (NSIndexPath *)indexPath;

/* Coordinates retrieval useful with containers oriented towards graphics and spreadsheet */
/*- (ETVector *) container: (ETContainer *)container locationForItem: (ETLayoutItem *)item;
- (void) container: (ETContainer *)container setLocation: (ETVector *)vectorLoc forItem: (ETLayoutItem *)item;*/

/* Extra infos */
- (NSArray *) displayedItemPropertiesInContainer: (ETContainer *)container;
- (NSArray *) editableItemPropertiesInContainer: (ETContainer *)container;
- (NSView *) container: (ETContainer *)container editorObjectForProperty: (NSString *)property ;
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
- (BOOL) container: (ETContainer *)container writeItemsAtIndexes: (NSIndexSet *)indexes toPasteboard: (NSPasteboard *)pboard;
- (BOOL) container: (ETContainer *)container acceptDrop: (id <NSDraggingInfo>)info atIndex: (int)index;
- (NSDragOperation) container: (ETContainer *)container validateDrop: (id <NSDraggingInfo>)info atIndex: (int)index;

/* Custom Drag and drop support by key and index path */
// FIXME: Create new set structure NSPathSet rather than using NSArray
- (BOOL) container: (ETContainer *)container writeItemsAtPaths: (NSArray *)paths toPasteboard: (NSPasteboard *)pboard;
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
extern NSString *ETLayoutItemPboardType;
