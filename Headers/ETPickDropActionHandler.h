/*  <title>ETPickDropActionHandler</title>

	<abstract>Pick and drop actions produced by various instruments/tools.</abstract>

	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
    License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETActionHandler.h>

@class ETUTI;
@class ETLayoutItem, ETPickboard, ETPickDropCoordinator;

/** Marks an element which shouldn't be considered bound to a particular index 
in an ordered collection or whose index isn't yet determined.

Can be used to indicate a drop is not an insertion at precise index but a simple drop on. */
extern const NSInteger ETUndeterminedIndex;


@interface ETActionHandler (ETPickDropActionHandler)

/* Pick & Drop Actions */

- (BOOL) handlePickItem: (ETLayoutItem *)item coordinator: (id)aPickCoordinator;
- (BOOL) handleDragItem: (ETLayoutItem *)item coordinator: (id)aPickCoordinator;
- (ETLayoutItem *) handleValidateDropObject: (id)droppedObject
                                    atPoint: (NSPoint)dropPoint
                              proposedIndex: (NSInteger *)anIndex
                                     onItem: (ETLayoutItem *)dropTarget
                                coordinator: (ETPickDropCoordinator *)aPickCoordinator;
- (BOOL) handleDropObject: (id)droppedObject
                  atIndex: (NSInteger)anIndex
                   onItem: (ETLayoutItem *)dropTargetItem 
              coordinator: (ETPickDropCoordinator *)aPickDropCoordinator;

/* Pick and Drop Filtering */

- (NSArray *) allowedPickTypesForItem: (ETLayoutItem *)item;
- (NSArray *) allowedDropTypesForItem: (ETLayoutItem *)item;
- (BOOL) canDragItem: (ETLayoutItem *)item
         coordinator: (ETPickDropCoordinator *)aPickCoordinator;
- (BOOL) canDropObject: (id)droppedObject
               atIndex: (NSInteger)dropIndex
                onItem: (ETLayoutItem *)dropTarget
           coordinator: (ETPickDropCoordinator *)aPickCoordinator;

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)isLocal;
- (BOOL) shouldRemoveItemsAtPickTime;

/* Drag Destination Feedback */

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

/* Drag Source Feedback */

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

/* Cut, Copy and Paste Compatibility */

- (IBAction) copy: (id)sender onItem: (ETLayoutItem *)item;
- (IBAction) paste: (id)sender onItem: (ETLayoutItem *)item;
- (IBAction) cut: (id)sender onItem: (ETLayoutItem *)item;

/* Methods to be implemented and used...
- (IBAction) pick: (id)sender;
- (IBAction) pickCopy: (id)sender;
- (IBAction) drop: (id)sender;*/

@end
