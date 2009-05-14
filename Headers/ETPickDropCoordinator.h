/** <title>ETPickDropCoordinator</title>

	<abstract>ETPickDropCoordinator drives EtoileUI pick and drop and allows to 
	leverage the drag and drop support provided by the widget backend.</abstract>

	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2009
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItem.h>

@class ETEvent;

/* WARNING: API still a bit unstable */

/* For behavior, special keys:
- drop into the window layer
- recursive hit test in the hovered item tree
- force drag over translate
- enable drag everywhere

   All dragging destination call backs are propagated to the drop target item 
   and not the hovered item. The drop target item is the dragging destination
   unlike the hovered item which is the top visible item right under the drag 
   location. The hovered item is different from the drop target item when the
   hovered item doesn't accept drop. */
@interface ETPickDropCoordinator : NSObject
{
	ETEvent *_event;
	ETLayoutItem *_dragSource;
	id <NSDraggingInfo> _dragInfo;
	ETLayoutItem *_previousDropTarget;
	ETLayoutItem *_previousHoveredItem;
}

+ (id) sharedInstance;
+ (id) sharedInstanceWithEvent: (ETEvent *)anEvent;
+ (unsigned int) forceEnablePickAndDropModifier;

- (void) beginDragItem: (ETLayoutItem *)item image: (NSImage *)customDragImage;

- (BOOL) isPasting;
- (BOOL) isDragging;
- (BOOL) isPickDropForced;
- (unsigned int) modifierFlags;

/* Drag Session Infos */

- (ETEvent *) pickEvent;

- (ETLayoutItem *) dragSource;
- (unsigned int) dragModifierFlags;
- (unsigned int) dragOperationMask; // TODO: Rename -dropOperationMask?
- (NSPoint) dragLocationInWindow;

/* Drop Insertion */

- (int) itemGroup: (ETLayoutItemGroup *)itemGroup 
	dropIndexAtLocation: (NSPoint)localDropPosition 
               withItem: (id)item 
                 onItem: (id)dropTargetItem;
- (void) itemGroup: (ETLayoutItemGroup *)itemGroup 
	insertDroppedObject: (id)movedObject atIndex: (int)index;
- (void) itemGroup: (ETLayoutItemGroup *)itemGroup 
	insertDroppedItem: (id)movedObject atIndex: (int)index;

/* AppKit Interface (should be in a concrete subclass) */

- (NSDragOperation) draggingUpdated: (id <NSDraggingInfo>)drag;
- (NSDragOperation) draggingEntered: (id <NSDraggingInfo>)drag;
- (void) draggingExited: (id <NSDraggingInfo>)drag;
- (void) draggingEnded: (id <NSDraggingInfo>)drag;
- (BOOL) prepareForDragOperation: (id <NSDraggingInfo>)drag;
- (BOOL) performDragOperation: (id <NSDraggingInfo>)dragInfo;
- (void) concludeDragOperation: (id <NSDraggingInfo>)drag;

@end

/** Informal Pick and Drop Integration protocol that ETLayout subclasses can
implement to customize the built-in ETPickDropCoordinator behavior. This allows 
to reuse the widget backend drag and drop support exactly as complex widgets 
such as NSTableView, NSOutlineView etc. provides it.

ETPickDropCoordinator automatically checks whether the layout implements one or 
several methods in the protocol. */
@interface NSObject (ETLayoutPickDropIntegration)
- (void) beginDrag: (ETEvent *)event forItem: (id)item 
	image: (NSImage *)customDragImage layout: (id)layout;
- (int) dropIndexAtLocation: (NSPoint)localDropPosition forItem: (id)item 
	on: (id)dropTargetItem;
@end

extern NSString *ETLayoutItemPboardType;
