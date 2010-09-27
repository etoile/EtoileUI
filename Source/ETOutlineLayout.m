/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETOutlineLayout.h"
#import "ETGeometry.h"
#import "ETLayout.h"
#import "ETLayoutItem.h"
#import "ETPickDropActionHandler.h"
#import "ETEvent.h"
#import "ETLayoutItemGroup.h"
#import "ETPickboard.h"
#import "ETPickDropCoordinator.h"
#import "ETCompatibility.h"

@interface NSOutlineView (EtoileUI)
- (NSIndexSet *) rowIndexesForItems: (NSArray *)items;
@end

@interface ETTableLayout (PackageVisibility)
- (void) tableViewSelectionDidChange: (NSNotification *)notif;
@end


@implementation ETOutlineLayout

- (NSOutlineView *) outlineView
{
	return (NSOutlineView *)[super tableView];
}

- (id) initWithLayoutView: (NSView *)aView
{
	self = [super initWithLayoutView: aView];
    if (nil == self)
		return nil;

	_treatsGroupsAsStacks = YES;

	NSParameterAssert([[self outlineView] isKindOfClass: [ETOutlineView class]]);
	return self;
}

- (NSString *) nibName
{
	return @"OutlinePrototype";
}

- (Class) widgetViewClass
{
	return [ETOutlineView class];
}

// NOTE: Dealloc and Awaking from nib handled by ETTableLayout superview.

- (BOOL) canRemoveTableColumn: (NSTableColumn *)aTableColumn
{
	return ([aTableColumn isEqual: [[self outlineView] outlineTableColumn]] == NO);
}

/* Requires the outline column to be the first column. */
- (BOOL) prepareTableColumn: (NSTableColumn *)column isFirst: (BOOL)isFirstColumn
{
	/* We cannot use -setOutlineTableColumn:, the outline indicator would be lost.
	   That's why we sync the outline column attribute-by-attribute with the first column. */
	NSTableColumn *outlineColumn = [[self outlineView] outlineTableColumn];
	BOOL shouldInsertColumn = ([[[self outlineView] tableColumns] containsObject: column] == NO);

	if (isFirstColumn)
	{
		[outlineColumn setIdentifier: [column identifier]];
		[outlineColumn setDataCell: [column dataCell]];
		[outlineColumn setHeaderCell: [column headerCell]];
		[outlineColumn setWidth: [column width]];
		[outlineColumn setMinWidth: [column minWidth]];
		[outlineColumn setMaxWidth: [column maxWidth]];
#ifdef GNUSTEP
		[outlineColumn setResizable: [column isResizable]];
#else
		[outlineColumn setResizingMask: [column resizingMask]];
#endif
		[outlineColumn setEditable: [column isEditable]];
		shouldInsertColumn = NO;
	}

	return shouldInsertColumn;
}

/* Returns YES when every groups are displayed as stacks which can be expanded
and collapsed by clicking on their related outline arrows. 

When only stacks can be expanded and collapsed (in other words when only 
stack-related rows have an outline arrow), returns NO. 

By default, returns YES. */
- (BOOL) treatsGroupsAsStacks
{
	return _treatsGroupsAsStacks;
}

/* Sets whether the receiver handles every groups as stacks which can be 
expanded and collapsed by getting automatically a related outline arrow. */
- (void) setTreatsGroupsAsStacks: (BOOL)flag
{
	_treatsGroupsAsStacks = flag;
}

- (ETLayoutItem *) itemAtLocation: (NSPoint)location
{
	int row = [[self outlineView] rowAtPoint: location];
	return (row != ETUndeterminedIndex ? [[self outlineView] itemAtRow: row] : nil);
}

- (NSRect) displayRectOfItem: (ETLayoutItem *)item
{
	int row = [[self outlineView] rowForItem: item];
	return [[self outlineView] rectOfRow: row];
}

- (void) selectionDidChangeInLayoutContext: (id <ETItemSelection>)aSelection
{
	NSIndexSet *rowIndexes = [[self outlineView] rowIndexesForItems: [aSelection selectedItems]];
	[[self outlineView] selectRowIndexes: rowIndexes byExtendingSelection: NO];
}

- (NSArray *) selectedItems
{
	NSOutlineView *outlineView = [self outlineView];
	NSIndexSet *indexes = [outlineView selectedRowIndexes]; 
	NSEnumerator *indexEnumerator = [indexes objectEnumerator];
	NSMutableArray *selectedItems = [NSMutableArray arrayWithCapacity: [indexes count]];
	
	FOREACHE(nil, index, NSNumber *, indexEnumerator)
	{
		[selectedItems addObject: [outlineView itemAtRow: [index intValue]]];
	}
	
	return selectedItems;
}

- (void) outlineViewSelectionDidChange: (NSNotification *)notif
{
	[self didChangeSelectionInLayoutView];
}

- (BOOL) outlineView: (NSOutlineView *)outlineView
	shouldEditTableColumn: (NSTableColumn *)column item: (id)item
{
	return [super tableView: outlineView shouldEditTableColumn: column 
		row: [outlineView rowForItem: item]];
}

- (int) outlineView: (NSOutlineView *)outlineView numberOfChildrenOfItem: (id)item
{
	BOOL isRootItem = (nil == item);
	int nbOfItems = 0;
	
	if (isRootItem)
	{
		nbOfItems = [[_layoutContext arrangedItems] count];

		/* First time. Useful when the layout context is browsed or 
		   inspected without having been loaded and displayed yet. 
		   Although most of time the use of -reloadAndUpdateLayout takes 
		   care of loading the items of the layout context. */
		if (nbOfItems == 0)
		{
			[(ETLayoutItemGroup *)_layoutContext reloadIfNeeded];
			nbOfItems = [[_layoutContext arrangedItems] count];
		}
	}
	else if ([item isGroup]) 
	{
		nbOfItems = [[item arrangedItems] count];
		
		/* First time */
		if (nbOfItems == 0)
		{
			[item reloadIfNeeded];
			nbOfItems = [[item arrangedItems] count];
		}
	}
	
	ETDebugLog(@"Returns %d as number of items in %@", nbOfItems, outlineView);
	
	return nbOfItems;
}

- (id) outlineView: (NSOutlineView *)outlineView child: (int)rowIndex ofItem: (id)item
{
	BOOL isRootItem = (nil == item);
	ETLayoutItem *childItem = nil; /* Leaf by default */
	
	if (isRootItem)
	{
		childItem = [[_layoutContext arrangedItems] objectAtIndex: rowIndex];
	}
	else if ([item isGroup])
	{
		childItem = [[(ETLayoutItemGroup *)item arrangedItems] objectAtIndex: rowIndex];
	}

	//ETLog(@"Returns %@ child item in outline view %@", childItem, outlineView);
	
	return childItem;
}

- (BOOL) outlineView: (NSOutlineView *)outlineView isItemExpandable: (id)item
{
	if ([item isGroup])
	{
		//ETLog(@"Returns item is expandable in outline view %@", outlineView);
		return YES;
	}

	return NO;
}

- (id) outlineView: (NSOutlineView *)outlineView 
	objectValueForTableColumn: (NSTableColumn *)column byItem: (id)item
{
	if (item == nil)
	{
		//ETLog(@"WARNING: Get nil item in -outlineView:objectValueForTableColumn:byItem: of %@", self);
		return nil;
	}

	return [self objectValueForTableColumn: column 
	                                   row: [outlineView rowForItem: item]
	                                  item: item];
}

- (void) outlineView: (NSOutlineView *)outlineView 
	setObjectValue: (id)value forTableColumn: (NSTableColumn *)column byItem: (id)item
{
	if (item == nil)
	{
		//ETLog(@"WARNING: Get nil item in -outlineView:objectValueForTableColumn:byItem: of %@", self);
		return;
	}

	/* Handles the case where a cell with no content is double-clicked/edited 
	   (NSImageCell or NSLevelIndicatorCell for example), this is only needed 
	   on GNUstep, because Cocoa won't let the editing happens in such case 
	   even if -isEditable returns YES for the cell. Moreover
	   -[NSImageCell isEditable] returns NO by default on Cocoa unlike GNUstep.

	   TODO: Don't call -setValue:forProperty: if the property is read-only. In 
	   theory, this should never happen since the cell shouldn't be editable if 
	   the property is read-only. But having a safety check, wouldn't hurt and 
	   also presently we don't modify the editable state of the cell depending 
	   on the characterics of the property. */
	if (value == nil)
		return;
	
	BOOL result = [item setValue: value forProperty: [column identifier]];
	BOOL blankColumnIdentifier = [column identifier] == nil || [[column identifier] isEqual: @""];
	
	if (result == NO && ([[self outlineView] numberOfColumns] == 1 || blankColumnIdentifier))
		[item setValue: value];

	//ETLog(@"Sets %@ as object value in outline view %@", value, outlineView);
}

- (BOOL) outlineView: (NSOutlineView *)outlineView 
	acceptDrop: (id < NSDraggingInfo >)info item: (id)item childIndex: (int)index
{
    ETDebugLog(@"Accept drop in %@", _layoutContext);

	id droppedObject = [[ETPickboard localPickboard] popObject];
	ETLayoutItem *dropTarget = (item != nil ? item : _layoutContext);

	return [[dropTarget actionHandler] handleDropObject: droppedObject
	                                            atIndex: index
	                                             onItem: dropTarget
		                                    coordinator: [ETPickDropCoordinator sharedInstance]];
}

- (NSDragOperation) outlineView: (NSOutlineView *)outlineView 
                   validateDrop: (id < NSDraggingInfo >)info 
                   proposedItem: (id)item 
             proposedChildIndex: (int)index
{
	ETLayoutItem *dropTarget = (item != nil ? item : _layoutContext);

    ETLog(@"Validate drop item %@ atIndex %d with dragging source %@ in %@", 
		[item primitiveDescription], index, [[info draggingSource] primitiveDescription], _layoutContext);
	
	id draggedObject = [[ETPickboard localPickboard] firstObject];
	int dropIndex = index;
	ETLayoutItem *validDropTarget = 
		[[dropTarget actionHandler] handleValidateDropObject: draggedObject
		                                             atPoint: ETNullPoint
		                                       proposedIndex: &dropIndex
	                                                  onItem: dropTarget
	                                             coordinator: [ETPickDropCoordinator sharedInstance]];

	/* -handleValidateXXX can return nil, the drop target, the drop target parent or another child */	
	if (nil == validDropTarget)
	{
		return NSDragOperationNone;
	}

	BOOL isRetargeted = ([validDropTarget isEqual: dropTarget] == NO || dropIndex != index);

	if (isRetargeted)
	{
		id dropItem = validDropTarget;

		if ([validDropTarget isEqual: _layoutContext])
		{
			dropItem = nil;
		}

		[outlineView setDropItem: dropItem dropChildIndex: dropIndex];

		ETLog(@"Retarget drop to %i in %@", dropIndex, dropItem);
	}

	return NSDragOperationEvery;
}

- (BOOL) outlineView: (NSOutlineView *)outlineView 
	writeItems: (NSArray *)items toPasteboard: (NSPasteboard *)pboard
{
	// NOTE: See -canDragRowsWithIndexes:atPoint: to understand -backendDragEvent
	NSEvent *backendEvent = [self backendDragEvent];
	NSEventType eventType = [backendEvent type];

	NSParameterAssert([[backendEvent window] isEqual: [outlineView window]]);
	NSParameterAssert(eventType == NSLeftMouseDown || eventType == NSLeftMouseDragged);

	/* Convert drag location from window coordinates to the receiver coordinates */
	NSPoint localPoint = [outlineView convertPoint: [backendEvent locationInWindow] fromView: nil];
	ETLayoutItem *draggedItem = [self itemAtLocation: localPoint];
	ETEvent *dragEvent = ETEVENT(backendEvent, nil, ETDragPickingMask);
	NSPoint point = NSZeroPoint;

	DESTROY(_dragImage);
	ASSIGN(_dragImage, [outlineView dragImageForRowsWithIndexes: [outlineView rowIndexesForItems: items]
	                                               tableColumns: [outlineView visibleTableColumns]
	                                                      event: backendEvent
	                                                     offset: &point]);

	NSAssert3([items containsObject: draggedItem], @"Dragged items %@ must "
		@"contain clicked item %@ in %@", items, draggedItem, self);

	return [[draggedItem actionHandler] handleDragItem: draggedItem 
		coordinator: [ETPickDropCoordinator sharedInstanceWithEvent: dragEvent]];
}

- (void) outlineView: (NSOutlineView *)outlineView sortDescriptorsDidChange: (NSArray *)oldDescriptors
{
	[self trySortRecursively: YES oldSortDescriptors: oldDescriptors];
}

- (ETLayoutItem *) doubleClickedItem
{
	//ETLog(@"-doubleClickedItem in %@", self);
	return [[self outlineView] itemAtRow: [[self outlineView] clickedRow]];
}

@end


@implementation ETOutlineView

- (BOOL) ignoreModifierKeysWhileDragging
{
	return [[ETPickDropCoordinator sharedInstance] ignoreModifierKeysWhileDragging];
}

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)isLocal
{
	return [[ETPickDropCoordinator sharedInstance] draggingSourceOperationMaskForLocal: isLocal];
}

- (void) draggedImage: (NSImage *)anImage beganAt: (NSPoint)aPoint
{
	if ([[NSOutlineView class] instancesRespondToSelector: @selector(draggedImage:beganAt:)])
	{
		[super draggedImage: anImage beganAt: aPoint];
	}
	[[ETPickDropCoordinator sharedInstance] draggedImage: anImage beganAt: aPoint];
}

- (void) draggedImage: (NSImage *)anImage movedTo: (NSPoint)aPoint
{
	if ([[NSOutlineView class] instancesRespondToSelector: @selector(draggedImage:movedTo:)])
	{
		[super draggedImage: anImage movedTo: aPoint];
	}
	[[ETPickDropCoordinator sharedInstance] draggedImage: anImage movedTo: aPoint];
}

- (void) draggedImage: (NSImage *)anImage endedAt: (NSPoint)aPoint operation: (NSDragOperation)operation
{
	if ([[NSOutlineView class] instancesRespondToSelector: @selector(draggedImage:endedAt:operation:)])
	{
		[super draggedImage: anImage endedAt: aPoint operation: operation];
	}
	[[ETPickDropCoordinator sharedInstance] draggedImage: anImage endedAt: aPoint operation: operation];
}

/* We implement this method only because [NSApp currentEvent] in 
   -outlineView:writeItems:toPasteboard: isn't the expected mouse down/dragged 
   event that triggered the drag when the mouse is moved/dragged very quickly. */
- (BOOL) canDragRowsWithIndexes: (NSIndexSet *)indexes atPoint: (NSPoint)point
{
	NSParameterAssert([[ETPickDropCoordinator sharedInstance] isDragging] == NO);

	NSEvent *event = [NSApp currentEvent];

	// FIXME: Looks -convertPoint:toView: isn't exactly symetric to 
	// -convertPoint:fromView: in -_startDragOperationWithEvent:
#ifndef GNUSTEP	
	NSPoint pointInWindow = [self convertPoint: point toView: nil];

	/* We check the current event is precisely the mouse down (cocoa) or dragged 
	   (gnustep) event that triggers the present drag request */
	NSParameterAssert(NSEqualPoints([event locationInWindow], pointInWindow));
#endif

	[[self dataSource] setBackendDragEvent: event];

	return YES;
}

/* See -dragImage:at:offset:event:pasteboard:source:slideback: comment */
- (NSImage *) dragImageForRowsWithIndexes: (NSIndexSet *)indexes
                             tableColumns: (NSArray *)columns
                                    event: (NSEvent *)dragEvent
                                   offset: (NSPointPointer)imgOffset
{
	BOOL isNewDrag = (nil == [[self dataSource] dragImage]);

	if (isNewDrag)
	{
		return [super dragImageForRowsWithIndexes: indexes 
			tableColumns: columns event: dragEvent offset: imgOffset];
	}

	return [[self dataSource] dragImage];
}

/* On Mac OS X, -[NSOutlineView -dragImage:at:offset:event:pasteboard:source:slideback:] 
invokes -_itemsFromRowsWithIndexes:.
When the dragged item(s) are removed at pick time, this results in a crash 
because the remembered indexes corresponds to the dragged items which are not 
present anymore in the outline view. Here is the stack trace:

_NSArrayRaiseInsertNilException
-[NSCFArray insertObject:atIndex:]
-[NSCFArray addObject:]
-[NSOutlineView _itemsFromRowsWithIndexes:]
-[NSOutlineView dragImage:at:offset:event:pasteboard:source:slideBack:]
-[ETOutlineView dragImage:at:offset:event:pasteboard:source:slideBack:]
-[NSTableView _doImageDragUsingRowsWithIndexes:event:pasteboard:source:slideBack:startRow:]
-[NSTableView _performDragFromMouseDown:]
-[NSTableView mouseDown:]
-[NSOutlineView mouseDown:]

So we work around this Cocoa AppKit issue by overriding the method. 
TODO: Report the issue to Apple since we have no idea whether the original 
NSOutlineView method is important or not really.

Take note we also override -dragImageForRowsWithIndexes:tableColumns:event:offset: 
in a similar way. */
- (void) dragImage: (NSImage *)anImage 
                at: (NSPoint)imageLoc 
            offset: (NSSize)mouseOffset 
             event: (NSEvent *)theEvent 
        pasteboard: (NSPasteboard *)pboard
            source: (id)sourceObject
         slideBack: (BOOL)slideBack
{
	NSPoint pointInWindow = [self convertPoint: imageLoc toView: nil] ;

	return [[self window] dragImage: anImage at: pointInWindow offset: mouseOffset 
		event: theEvent pasteboard: pboard source: sourceObject slideBack: slideBack];
}

- (NSIndexSet *) rowIndexesForItems: (NSArray *)items
{
	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];

	FOREACH(items, item, ETLayoutItem *)
	{
		[indexes addIndex: [self rowForItem: item]];
	}

	return indexes;
}

@end
