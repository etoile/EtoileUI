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
#import <EtoileFoundation/ETCollection.h>
#import <EtoileUI/ETView.h>
#import <EtoileUI/ETLayout.h>

@class ETLayoutItem, ETLayout, ETLayer, ETLayoutItemGroup, ETSelection, 
	ETPickboard, ETEvent, ETDecoratorItem;

extern NSString *ETLayoutItemPboardType;

@interface ETContainer : ETView
{
	NSView *_layoutView;
	
	float _itemScale;

	BOOL _dragAllowed;
	BOOL _dropAllowed;
	BOOL _removeItemsAtPickTime;
	/* Insertion indicator to erase on next mouse move event in a drag */
	NSRect _prevInsertionIndicatorRect; 
}

- (id) initWithLayoutView: (NSView *)layoutView;

- (id) layoutItem;

- (id) deepCopy;

/* Basic Accessors */

- (NSView *) layoutView;
- (void) setLayoutView: (NSView *)view;

/* - (ETLayoutAlignment) layoutAlignment;
- (void) setLayoutAlignment: (ETLayoutAlignment)alignment;

- (ETLayoutOverflowStyle) overflowStyle;
- (void) setOverflowStyle: (ETLayoutOverflowStyle); */

/* Pick & Drop */

/*- (void) setDraggingAllowedForTypes: (NSArray *)types;
- (NSArray *) allowedDraggingTypes;
- (void) setDroppingAllowedForTypes: (NSArray *)types;
- (NSArray *) allowedDroppingTypes;
- (void) setDropTargetTypes: (NSArray *)types;
- (NSArray *)dropTargetTypes;*/

- (BOOL) shouldRemoveItemsAtPickTime;
- (void) setShouldRemoveItemsAtPickTime: (BOOL)flag;

// NOTE: Following methods are deprecated
- (void) setAllowsDragging: (BOOL)flag;
- (BOOL) allowsDragging;
- (void) setAllowsDropping: (BOOL)flag;
- (BOOL) allowsDropping;

/* Groups and Stacks */

- (IBAction) stack: (id)sender;

/* Item scaling */

- (float) itemScaleFactor;
- (void) setItemScaleFactor: (float)factor;
/*- (id) scaleItemsToRect: (NSRect)rect;
- (id) scaleItemsToFit: (id)sender;
// This method is equivalent to calling -setItemScaleFactor with 1.0 value
- (id) scaleItemsToActualSize: (id)sender;*/
// FIXME: Implement the following methods
/*- (float) itemRotationAngle;
- (void) setItemRotationAngle: (float)factor;*/

/* Rendering Chain */

- (void) render;

@end

/* Deprecated (DO NOT USE, WILL BE REMOVED LATER) */

@interface NSObject (ETContainerSource)

/* Coordinates retrieval useful with containers oriented towards graphics and 
   spreadsheet */
/*- (ETVector *) container: (ETContainer *)container 
	locationForItem: (ETLayoutItem *)item;
- (void) container: (ETContainer *)container setLocation: (ETVector *)vectorLoc 
	forItem: (ETLayoutItem *)item;*/

/* Extra infos */
- (NSArray *) editableItemPropertiesInContainer: (ETContainer *)container;
- (NSView *) container: (ETContainer *)container 
	editorObjectForProperty: (NSString *)property ;
- (int) firstVisibleItemInContainer: (ETContainer *)container;
- (int) lastVisibleItemInContainer: (ETContainer *)container;

/* Pick and drop support and Bindings support by index */
/* When operation is a pick and drop one (either copy/paste or drag/drop), 
   - 'container:addItems:operation:' is called when no selection is set
   - 'container:insertItems:atIndexes:operation:' is called when a selection 
      exists */
/* These methods make also possible to use your data source with bindings if 
   you use the specifically designed controller ETSourceController */
- (BOOL) container: (ETContainer *)container addItems: (NSArray *)items 
	operation: (ETEvent *)op;
- (BOOL) container: (ETContainer *)container insertItems: (NSArray *)items 
	atIndexes: (NSIndexSet *)indexes operation: (ETEvent *)op;
- (BOOL) container: (ETContainer *)container removeItems: (NSArray *)items 
	atIndexes: (NSIndexSet *)indexes operation: (ETEvent *)op;

/* Pick and drop support and Bindings support by index path */
- (BOOL) container: (ETContainer *)container addItems: (NSArray *)items 
	atPath: (NSIndexPath *)path operation: (ETEvent *)op;
- (BOOL) container: (ETContainer *)container insertItems: (NSArray *)items 
	atPaths: (NSArray *)paths operation: (ETEvent *)op;
- (BOOL) container: (ETContainer *)container 
	removeItemsAtPaths: (NSArray *)paths operation: (ETEvent *)op;

/* Advanced pick and drop support 
   Only needed if you want to override pick and drop support. Useful to get more
   control over drag an drop. */
- (BOOL) container: (ETContainer *)container handlePick: (ETEvent *)event 
	forItems: (NSArray *)items pickboard: (ETPickboard *)pboard;
- (BOOL) container: (ETContainer *)container handleAcceptDrop: (id)dragInfo 
	forItems: (NSArray *)items on: (id)item pickboard: (ETPickboard *)pboard;
- (BOOL) container: (ETContainer *)container handleDrop: (id)dragInfo 
	forItems: (NSArray *)items on: (id)item pickboard: (ETPickboard *)pboard;

// TODO: Extend the informal protocol to propogate group/ungroup actions in 
// they can be properly reflected on model side.

@end

@interface ETContainer (ETContainerDelegate)

- (void) containerShouldStackItem: (NSNotification *)notif;
- (void) containerDidStackItem: (NSNotification *)notif;
- (void) containerShouldGroupItem: (NSNotification *)notif;
- (void) containerDidGroupItem: (NSNotification *)notif;
// NOTE: We use a double action instead of the delegate to handle double-click
//- (void) containerDoubleClickedItem: (NSNotification *)notif;

@end

@interface ETContainer (Deprecated)

- (NSString *) representedPath;
- (void) setRepresentedPath: (NSString *)path;
- (id) source;
- (void) setSource: (id)source;
- (id) delegate;
- (void) setDelegate: (id)delegate;

/* Inspecting */

- (IBAction) inspect: (id)sender;
- (IBAction) inspectSelection: (id)sender;

/* Layout */

- (BOOL) isAutolayout;
- (void) setAutolayout: (BOOL)flag;
- (BOOL) canUpdateLayout;
- (void) updateLayout;
- (void) reloadAndUpdateLayout;

- (ETLayout *) layout;
- (void) setLayout: (ETLayout *)layout;

/* Layout Item Tree */

- (void) addItem: (ETLayoutItem *)item;
- (void) insertItem: (ETLayoutItem *)item atIndex: (int)index;
- (void) removeItem: (ETLayoutItem *)item;
- (void) removeItemAtIndex: (int)index;
- (ETLayoutItem *) itemAtIndex: (int)index;
- (int) indexOfItem: (ETLayoutItem *)item;
- (BOOL) containsItem: (ETLayoutItem *)item;
- (int) numberOfItems;
- (NSArray *) items;
- (void) addItems: (NSArray *)items;
- (void) removeItems: (NSArray *)items;
- (void) removeAllItems;

/* Selection */

- (NSArray *) selectedItemsInLayout;
- (NSArray *) selectionIndexPaths;
- (void) setSelectionIndexPaths: (NSArray *)indexPaths;
- (void) setSelectionIndexes: (NSIndexSet *)selection;
- (NSMutableIndexSet *) selectionIndexes;
- (void) setSelectionIndex: (unsigned int)index;
- (unsigned int) selectionIndex;

- (BOOL) allowsMultipleSelection;
- (void) setAllowsMultipleSelection: (BOOL)multiple;
- (BOOL) allowsEmptySelection;
- (void) setAllowsEmptySelection: (BOOL)empty;

/* Scrolling */

- (BOOL) hasVerticalScroller;
- (void) setHasVerticalScroller: (BOOL)scroll;
- (BOOL) hasHorizontalScroller;
- (void) setHasHorizontalScroller: (BOOL)scroll;
- (NSScrollView *) scrollView;
- (BOOL) isScrollViewShown;

/* Actions */

- (void) setTarget: (id)target;
- (id) target;
- (void) setDoubleAction: (SEL)selector;
- (SEL) doubleAction;
- (ETLayoutItem *) doubleClickedItem;
- (BOOL) isHitTestEnabled;
- (void) setEnablesHitTest: (BOOL)hit;

@end
