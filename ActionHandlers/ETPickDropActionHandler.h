/*  <title>ETPickDropActionHandler</title>

	<abstract>Pick and drop actions produced by various tools/tools.</abstract>

	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
    License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETActionHandler.h>

@class ETUTI;
@class ETLayoutItem, ETPickboard, ETPickCollection, ETPickDropCoordinator;


/** ETUndeterminedIndex be used to indicate a drop is not an insertion at precise index but a simple drop on. */
@interface ETActionHandler (ETPickDropActionHandler)

/** @taskunit Pick and Drop Actions */

- (BOOL) handlePickItem: (ETLayoutItem *)item
          forceItemPick: (BOOL)forceItemPick
   shouldRemoveItemsNow: (BOOL)shouldRemoveItems
            coordinator: (id)aPickCoordinator;
- (BOOL) handleDragItem: (ETLayoutItem *)item
          forceItemPick: (BOOL)forceItemPick
   shouldRemoveItemsNow: (BOOL)shouldRemoveItems
            coordinator: (id)aPickCoordinator;
- (ETLayoutItem *) handleValidateDropObject: (id)droppedObject
                                       hint: (id)aHint
                                    atPoint: (NSPoint)dropPoint
                              proposedIndex: (NSInteger *)anIndex
                                     onItem: (ETLayoutItem *)dropTarget
                                coordinator: (ETPickDropCoordinator *)aPickCoordinator;
- (BOOL) handleDropObject: (id)droppedObject
                     hint: (id)aHint
                 metadata: (NSDictionary *)metadata
                  atIndex: (NSInteger)anIndex
                   onItem: (ETLayoutItem *)dropTarget
			  coordinator: (ETPickDropCoordinator *)aPickCoordinator;
			  
/** @taskunit Pick Collection Drop */

- (BOOL) handleDropCollection: (ETPickCollection *)aPickCollection
                     metadata: (NSDictionary *)metadata
                      atIndex: (NSInteger)anIndex
                       onItem: (ETLayoutItem *)dropTarget
			      coordinator: (ETPickDropCoordinator *)aPickCoordinator;

/** @taskunit Pick and Drop Filtering */

- (NSArray *) allowedPickTypesForItem: (ETLayoutItem *)item;
- (NSArray *) allowedDropTypesForItem: (ETLayoutItem *)item;
- (NSArray *) pickedObjectsForItems: (NSArray *)items
               shouldRemoveItemsNow: (BOOL *)shouldRemoveItems;
- (BOOL) canDragItem: (ETLayoutItem *)item
         coordinator: (ETPickDropCoordinator *)aPickCoordinator;
- (BOOL) canDropObject: (id)droppedObject
               atIndex: (NSInteger)dropIndex
                onItem: (ETLayoutItem *)dropTarget
           coordinator: (ETPickDropCoordinator *)aPickCoordinator;

- (unsigned int) dragOperationMaskForDestinationItem: (ETLayoutItem *)item
                                         coordinator: (ETPickDropCoordinator *)aPickCoordinator;

- (BOOL) boxingForcedForDroppedItem: (ETLayoutItem *)droppedItem 
                           metadata: (NSDictionary *)metadata;

/** @taskunit Drag Destination Feedback */

- (NSDragOperation) handleDragMoveOverItem: (ETLayoutItem *)item 
                                  withItem: (ETLayoutItem *)draggedItem
                               coordinator: (id)aPickCoordinator;
- (NSDragOperation) handleDragEnterItem: (ETLayoutItem *)item
                               withItem: (ETLayoutItem *)draggedItem
                            coordinator: (id)aPickCoordinator;
- (void) handleDragExitItem: (ETLayoutItem *)item
                   withItem: (ETLayoutItem *)draggedItem
                coordinator: (id)aPickCoordinator;
- (void) handleDragEndAtItem: (ETLayoutItem *)item
                    withItem: (ETLayoutItem *)draggedItem
                wasCancelled: (BOOL)cancelled
                 coordinator: (id)aPickCoordinator;

/** @taskunit Drag Source Feedback */

- (void) handleDragItem: (ETLayoutItem *)draggedItem 
           beginAtPoint: (NSPoint)aPoint 
            coordinator: (id)aPickCoordinator;
- (void) handleDragItem: (ETLayoutItem *)draggedItem 
             moveToItem: (ETLayoutItem *)item
            coordinator: (id)aPickCoordinator;
- (void) handleDragItem: (ETLayoutItem *)draggedItem 
              endAtItem: (ETLayoutItem *)item
           wasCancelled: (BOOL)cancelled
            coordinator: (id)aPickCoordinator;

/** @taskunit Cut, Copy and Paste Compatibility */

- (IBAction) copy: (id)sender onItem: (ETLayoutItem *)item;
- (IBAction) paste: (id)sender onItem: (ETLayoutItem *)item;
- (IBAction) cut: (id)sender onItem: (ETLayoutItem *)item;

/* Methods to be implemented and used...
- (IBAction) pick: (id)sender;
- (IBAction) pickCopy: (id)sender;
- (IBAction) drop: (id)sender;*/

@end
