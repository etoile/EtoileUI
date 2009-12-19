/*
	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/NSObject+HOM.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETTableLayout.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETEvent.h"
#import "ETPickboard.h"
#import "ETPickDropActionHandler.h"
#import "ETPickDropCoordinator.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"

@interface NSTableColumn (Etoile) <ETColumnFragment>
@end

/* Private Interface */

@interface ETTableLayout (Private)
- (void) _updateDisplayedPropertiesFromSource;
- (NSArray *) selectionIndexPaths;
@end

@interface ETTableLayout (ETableLayoutDisplayViewGeneration)
- (NSScrollView *) scrollingTableView;
@end

#define DEFAULT_ROW_HEIGHT 16


@implementation ETTableLayout

- (NSString *) nibName
{
	return @"TablePrototype";
}

- (void) dealloc
{
	/* ivar lazily initialized in -setLayoutView: */
	DESTROY(_propertyColumns);
	DESTROY(_currentSortDescriptors);
	DESTROY(_contentFont);
	[super dealloc];
}

- (id) copyWithZone: (NSZone *)aZone layoutContext: (id <ETLayoutingContext>)ctxt
{
	ETTableLayout *newLayout = [super copyWithZone: aZone layoutContext: ctxt];
	NSParameterAssert([newLayout tableView] != [self tableView]);

	/* Will initialize the ivars in the layout copy */
	[newLayout setLayoutView: [newLayout layoutView]];

	return newLayout;
}

- (void) awakeFromNib
{
	/* Finish to initialize attributes that cannot be set in the nib/gorm and 
	   are specific to the builtin table view prototype. As such they cannot 
	   be set in -setLayoutView: since they could override the settings of a  
	   custom table view provided as a replacement to the builtin prototype. */

	// NOTE: Gorm doesn't allow to set the table view resizing style unlike IB
	[[self tableView] setAutoresizesAllColumnsToFit: NO];
	 // TODO: Remove next line by modifying GNUstep to match Cocoa behavior
	[[self tableView] setVerticalMotionCanBeginDrag: YES];
	/* Enable double-click */
	[[[self tableView] tableColumnWithIdentifier: @"icon"] setEditable: NO];
}

- (void) setLayoutView: (NSView *)protoView
{
	NSParameterAssert(nil != protoView);
	[super setLayoutView: protoView];

	NSTableView *tv = [self tableView];
	
	/* ivar cannot be initialized by overriding -initWithLayoutView: because 
	   superclass initializer called -loadNibNamed: before returning, moreover
	   the ivar must be reset for each new layout view. */
	ASSIGN(_propertyColumns, [NSMutableDictionary dictionary]);

	/* Retain initial columns to be able to restore exactly identical columns later */	
	FOREACH([tv tableColumns], column, NSTableColumn *)
	{
		NSString *colId = [column identifier];
		
		// NOTE: May be should insert a positional number because the current
		// blank string limits us to a single column without identifier
		if (colId == nil)
			colId = @"";
		
		[_propertyColumns setObject: column forKey: colId];
	}
	/* Set up a list view using a single column without identifier */
	[tv registerForDraggedTypes: A(ETLayoutItemPboardType)];

	// NOTE: When a table view is archived/unarchived on GNUstep, a nil data 
	// source or delegate in the initial instance becomes the table view itself 
	// in the unarchived instance.
	[tv setDataSource: self];
	[tv setDelegate: self];
}

- (NSTableView *) tableView
{
	id layoutView = [self layoutView];
	
	NSAssert2([layoutView isKindOfClass: [NSScrollView class]], @"Layout view "
		@" %@ of %@ must be an NSScrollView instance", layoutView, self);

	return [(NSScrollView *)[self layoutView] documentView];
}

- (NSArray *) allTableColumns
{
	return [_propertyColumns allValues];
}

- (void) setAllTableColumns: (NSArray *)columns
{
	ASSIGN(_propertyColumns, columns);
}

/* Item Property Display */

/** Returns the property names associated with the visible columns. 

The property names are used as the column identifiers. */
- (NSArray *) displayedProperties
{
	return [[[self tableView] tableColumns] valueForKey: @"identifier"];
}

/** Makes visible the columns associated with the given property names. If a 
column doesn't exist as an invisible column for a property, then it is created 
and inserted immediately.

The property names are used as the column identifiers. */
- (void) setDisplayedProperties: (NSArray *)properties
{
	ETDebugLog(@"Set displayed properties %@ of layout %@", properties, self);

	if (properties == nil)
	{
		[NSException raise: NSInvalidArgumentException format: @"For %@ "
			@"-setDisplayedProperties argument must never be nil", self];
	}

	NSTableView *tv = [self tableView];
	NSArray *tableViewSortKeys = (id)[[[tv sortDescriptors] mappedCollection] key];

	/* Prepare the current sort descriptors */
	ASSIGN(_currentSortDescriptors, [NSMutableArray arrayWithArray: [tv sortDescriptors]]);

	/* Remove all existing columns
	   NOTE: We cannot enumerate [tv tableColumns] directly because we remove columns */
	FOREACH([NSArray arrayWithArray: [tv tableColumns]], column, NSTableColumn *)
	{
		[tv removeTableColumn: column];
	}

	/* Add all columns to be displayed */	
	FOREACH(properties, property, NSString *)
	{
		NSTableColumn *column = [_propertyColumns objectForKey: property];

		if (column == nil)
			column = [self _createTableColumnWithIdentifier: property];
		
		[tv addTableColumn: column];
		
		BOOL usesSortDescriptorProto = ([tableViewSortKeys containsObject: property] == NO
			&& [column sortDescriptorPrototype] != nil);

		if (usesSortDescriptorProto)
		{
			[_currentSortDescriptors addObject: [column sortDescriptorPrototype]];
		}
	}
}

- (void) _updateDisplayedPropertiesFromSource: (id)aSource
{
	if (nil == aSource)
		return;

	NSArray *properties = [[aSource ifResponds] 
		displayedItemPropertiesInItemGroup: _layoutContext];

	if (nil == properties)
		return;

	[self setDisplayedProperties: properties];
}

/** Returns the column header title associated with the given property. */
- (NSString *) displayNameForProperty: (NSString *)property
{
	return [[[_propertyColumns objectForKey: property] headerCell] stringValue];
}

/** Sets the column header title associated with the given property. The 
property display name should usually be passed as argument. */
- (void) setDisplayName: (NSString *)displayName forProperty: (NSString *)property
{
	NSTableColumn *column = [self tableColumnWithIdentifierAndCreateIfAbsent: property];
	[[column headerCell] setStringValue: displayName];
}

/** Returns whether the column associated with the given property is editable.

By default, columns are not editable and NO is returned. */
- (BOOL) isEditableForProperty: (NSString *)property
{
	return [[_propertyColumns objectForKey: property] isEditable];
}

/** Sets whether the column associated with the given property is editable. */
- (void) setEditable: (BOOL)flag forProperty: (NSString *)property
{
	NSTableColumn *column = [self tableColumnWithIdentifierAndCreateIfAbsent: property];
	[[column dataCell] setEditable: flag]; // FIXME: why column setEditable: isn't enough
	[column setEditable: flag];	
}

/** Returns the data cell of the column associated with the given property, but 
this is temporary.

TODO: Return a layout item built dynamically by determining the cell subclass 
kind. May be add -[ETLayoutItemFactory itemWithCell:]. */
- (id) styleForProperty: (NSString *)property
{
	return [[_propertyColumns objectForKey: property] dataCell];
}

/** Sets the widget style used by the column associated with the given property.
You must pass a layout item bound a view that responds to -cell, otherwise style 
will be ignored. The view is typically an NSControl subclass instance.

NOTE: The documented behavior is subject to further changes in future to become 
more widget backend agnostic. */
- (void) setStyle: (id)style forProperty: (NSString *)property
{
	NSTableColumn *column = [self tableColumnWithIdentifierAndCreateIfAbsent: property];
	NSCell *cell = nil;

	if ([style isLayoutItem] && [[style view] respondsToSelector: @selector(cell)])
	{
		cell = [(id)[style view] cell];	

		[column setDataCell: cell];
		// NOTE: For cell editability, -[NSTableColumn isEditable] takes over the 
		// the NSCell method of the data cell (at least for GNUstep, may be 
		// different for Cocoa).
		[column setEditable: [cell isEditable]];
	}
}

/** Returns the font used to display each row/column cell value. 

By default, returns nil and uses the font set individually on each column. */
- (NSFont *) contentFont
{
	return _contentFont;
}

/** Sets the font used to display each row/column cell value.

This overrides any specific font you might have set individually on colums 
returned by -allTableColumns. */
- (void) setContentFont: (NSFont *)aFont
{
	ASSIGN(_contentFont, aFont);
	FOREACH([self allTableColumns], column, NSTableColumn *)
	{
		[[column dataCell] setFont: _contentFont];
	}
}

/** Returns the column associated with the given property, the column might be 
visible or not depending on -displayedProperties. If the column doesn't exist 
yet, it is created. */
- (NSTableColumn *) tableColumnWithIdentifierAndCreateIfAbsent: (NSString *)property
{
	NSTableColumn *column = [_propertyColumns objectForKey: property];

	if (column == nil)
	{
		column = [self _createTableColumnWithIdentifier: property];
		[_propertyColumns setObject: column forKey: property];
	}

	return column;
}

- (NSTableColumn *) _createTableColumnWithIdentifier: (NSString *)property
{
	NSTableHeaderCell *headerCell = [[NSTableHeaderCell alloc] initTextCell: property]; // FIXME: Use display name
	NSCell *dataCell = [[NSCell alloc] initTextCell: @""];
	NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier: property];
	// FIXME: Implement sort descriptor support on NSTableView and NSTableColumn
#ifndef GNUSTEP
	// TODO: -compare: is really a suboptimal choice in various cases.
	// For example, NSString provides -localizedCompare: unlike NSNumber, NSDate etc.
	NSSortDescriptor *sortDescriptor = AUTORELEASE([[NSSortDescriptor alloc] 
		initWithKey: property ascending: YES selector: @selector(compare:)]);
#endif

	[column setHeaderCell: headerCell];
	RELEASE(headerCell);
	[dataCell setFont: [self contentFont]];
#ifdef GNUstep // FIXME: Probably don't needed on GNUstep either...
	NSParameterAssert([[column dataCell] isKindOfClass: [NSTextFieldCell class]]);
	[column setDataCell: dataCell];
#endif
	RELEASE(dataCell);
	[column setEditable: NO];
#ifndef GNUSTEP
	[column setSortDescriptorPrototype: sortDescriptor];
#endif

	return AUTORELEASE(column);
}

- (id <ETColumnFragment>) columnForProperty: (NSString *)property
{
	return [self tableColumnWithIdentifierAndCreateIfAbsent: property];
}

/* Layouting */

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	if ([[self layoutContext] supervisorView] == nil)
	{
		ETLog(@"WARNING: Layout context %@ must have a supervisor view otherwise "
			@"view-based layout %@ cannot be set", _layoutContext, self);
		return;
	}

	[self resizeLayoutItems: items 
	          toScaleFactor: [[self layoutContext] itemScaleFactor]];

	/* Only reload from the data source if the layout item tree visible in the 
	   table/outline view has been mutated */
	if (isNewContent)
	{
		id source = [[_layoutContext ifResponds] source];
		[self _updateDisplayedPropertiesFromSource: source];

		[[self tableView] reloadData];
		[[self tableView] setNeedsDisplay: YES]; // FIXME: -updateLayout redisplay should be enough
	}
}

- (void) resizeLayoutItems: (NSArray *)items toScaleFactor: (float)factor
{
	// NOTE: Always recompute row height from the original one to avoid really
	// value shifting quickly because of rounding.
	float rowHeight = DEFAULT_ROW_HEIGHT * factor;
	
	/* Enforce a minimal row height to avoid redisplay crashes especially */
	if (rowHeight < 1.0)
		rowHeight = 1.0;

	[[self tableView] setRowHeight: rowHeight];
}

- (ETLayoutItem *) itemAtLocation: (NSPoint)location
{
	int row = [[self tableView] rowAtPoint: location];
	id item = nil;
	
	// NOTE: Table view returns -1 when no row exists at location (but not 
	// NSNotFound as we could expect it)
	if (row != -1 && row != NSNotFound)
		return [[[self layoutContext] arrangedItems] objectAtIndex: row];
	
	return item;
}

- (NSRect) displayRectOfItem: (ETLayoutItem *)item
{
	int row = [[[self layoutContext] arrangedItems] indexOfObject: item];

	return [[self tableView] rectOfRow: row];
}

/** Invalidates the row associated with the given item. */
- (void) setNeedsDisplayForItem: (ETLayoutItem *)anItem
{
	[[self tableView] setNeedsDisplayInRect: [self displayRectOfItem: anItem]];
}

- (NSArray *) selectedItems
{
	NSIndexSet *indexes = [[self tableView] selectedRowIndexes];
	NSArray *items = [[self layoutContext] arrangedItems];
	NSMutableArray *selectedItems = 
		[NSMutableArray arrayWithCapacity: [indexes count]];
	
	FOREACH(indexes, index, NSNumber *)
	{
		[selectedItems addObject: [items objectAtIndex: [index intValue]]];
	}
	
	return selectedItems;
}

- (void) tableViewSelectionDidChange: (NSNotification *)notif
{
	[self didChangeSelectionInLayoutView];
}

// NOTE: Only for Cocoa presently but we'll be probably be used everywhere later.
#ifndef GNUSTEP
- (BOOL) tableView: (NSTableView *)tv
	shouldEditTableColumn: (NSTableColumn *)column row: (int)rowIndex
{
	// TODO: If we pose our own NSTableColumn subclass as an NSTableColumn 
	// replacement class, we could provide multiple custom data cells per 
	// column. That would useful to enable/disable the cell editing based on 
	// whether the object owning the property specifies it as read-only or not.
	// Another approach, probably better is to implement the new 10.5 delegate 
	// method -tableview:dataCellForTableColumn:row: and then calls 
	// -preparedCellAtColumn:row:
	NSCell *dataCell = [column dataCellForRow: rowIndex];

	/* NSTableView only considers if the column is editable by default to allow 
	   or deny the editing, at least on GNUstep. And...
	   Cocoa seems to contradict the documentation of -setDoubleAction: by 
	   always disabling all editing if a double action is set. iirc you can take 
	   over this behavior by implementing the present method, but that needs to 
	   be tested since this code is currently written on GNUstep. */
	return [dataCell isEditable];
}
#endif

- (int) numberOfRowsInTableView: (NSTableView *)tv
{
	NSArray *layoutItems = [[self layoutContext] arrangedItems];
	
	ETDebugLog(@"Returns %d as number of items in table view %@", [layoutItems count], tv);
	
	return [layoutItems count];
}

- (id) tableView: (NSTableView *)tv objectValueForTableColumn: (NSTableColumn *)column row: (int)rowIndex
{
	NSArray *layoutItems = [[self layoutContext] arrangedItems];
	ETLayoutItem *item = nil;
	
	if (rowIndex >= [layoutItems count])
	{
		ETLog(@"WARNING: Row index %d uncoherent with number of items %d in %@", rowIndex, [layoutItems count], self);
		return nil;
	}
	
	item = [layoutItems objectAtIndex: rowIndex];
	
	//ETDebugLog(@"Returns %@ as object value in table view %@", [item valueForProperty: [column identifier]], tv);
	
	id value = [item valueForProperty: [column identifier]];
	BOOL blankColumnIdentifier = [column identifier] == nil || [[column identifier] isEqual: @""];
	
	if (value == nil && ([tv numberOfColumns] == 1 || blankColumnIdentifier))
		value = [item value];

	// NOTE: 'value' could be any objects at this point and NSCell only accepts
	// some common object values like string and number or image for 
	// NSImageCell. Unless a custom formatter has been set on the column or a 
	// custom cell has been provided, non common object values must be 
	// converted to a string or number representation, -objectValue precisely 
	// takes care of converting it to a string value. See -objectValue in 
	// NSObject+Model for more details.	
	return [value objectValue];
}

- (void) tableView: (NSTableView *)tv setObjectValue: (id)value forTableColumn: (NSTableColumn *)column row: (int)rowIndex
{
	NSArray *layoutItems = [[self layoutContext] arrangedItems];
	ETLayoutItem *item = nil;
	
	if (rowIndex >= [layoutItems count])
	{
		ETLog(@"WARNING: Row index %d uncoherent with number of items %d in %@", rowIndex, [layoutItems count], self);
		return;
	}
	
	item = [layoutItems objectAtIndex: rowIndex];
	
	//ETDebugLog(@"Sets %@ as object value in table view %@", value, tv);

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
	
	if (result == NO && ([tv numberOfColumns] == 1 || blankColumnIdentifier))
		[item setValue: value];
}

- (void) beginDrag: (ETEvent *)event forItem: (id)item 
	image: (NSImage *)customDragImage layout: (id)layout
{
	ETDebugLog(@"Overriden -beginDrag:forItem:image: in %@", self);
	/* Overriden to do nothing and let the table view creates and manages the 
	   drag object. This method is called by -handleDrag:forItem:. */
}

- (BOOL) tableView: (NSTableView *)tv writeRowsWithIndexes: (NSIndexSet *)rowIndexes 
	toPasteboard: (NSPasteboard*)pboard 
{
	// NOTE: On Mac OS X and GNUstep, -[NSApp currentEvent] returns a later 
	// event rather than the mouse down or dragged that began the drag when the 
	// user moves the mouse too quickly.
	NSEvent *backendEvent = [self lastDragEvent]; 
	NSEventType eventType = [backendEvent type];

	NSAssert3([[backendEvent window] isEqual: [tv window]], @"Backend event %@ in %@"
		"-tableView:writeRowsWithIndexes:toPasteboard: doesn't belong to the "
		"table view %@", backendEvent, self, tv);
	NSAssert2(eventType == NSLeftMouseDown || eventType == NSLeftMouseDragged, 
		@"Backend event %@ in %@ -tableView:writeRowsWithIndexes:toPasteboard: "
		"must be of type NSLeftMouseDown/Dragged", eventType, self);
	
	/* Convert drag location from window coordinates to the receiver coordinates */
	NSPoint localPoint = [tv convertPoint: [backendEvent locationInWindow] fromView: nil];
	ETLayoutItem *draggedItem = [self itemAtLocation: localPoint];
	ETLayoutItem *baseItem = [_layoutContext baseItem];
	ETEvent *dragEvent = ETEVENT(backendEvent, nil, ETDragPickingMask);

	// TODO: May be better to use [draggedItem actionHandler]
	return [[baseItem actionHandler] handleDragItem: draggedItem 
		coordinator: [ETPickDropCoordinator sharedInstanceWithEvent: dragEvent]];
}

- (NSDragOperation) tableView:(NSTableView*)tv 
                 validateDrop: (id <NSDraggingInfo>)info 
				  proposedRow: (int)row 
	    proposedDropOperation: (NSTableViewDropOperation)op 
{
	ETLayoutItem *dropTarget = (ETLayoutItem *)_layoutContext;

	if (ETUndeterminedIndex != row && NSTableViewDropOn == op)
	{
		dropTarget = [[_layoutContext items] objectAtIndex: row];
	}

	ETLog(@"Validate drop on %@ with dragging source %@ in %@ drag mask %d drop op %d", 
		[dropTarget primitiveDescription], [[info draggingSource] primitiveDescription], 
		_layoutContext, [info draggingSourceOperationMask], op);
	
	id draggedObject = [[ETPickboard localPickboard] firstObject];
	ETLayoutItem *baseItem = [_layoutContext baseItem];
	NSInteger dropIndex = (NSTableViewDropAbove == op ? row : ETUndeterminedIndex);
	ETLayoutItem *validDropTarget = 
		[[baseItem actionHandler] handleValidateDropObject: draggedObject
		                                           atPoint: ETNullPoint
		                                     proposedIndex: &dropIndex
	                                                onItem: dropTarget
	                                           coordinator: [ETPickDropCoordinator sharedInstance]];

	/* -handleValidateXXX can return nil, the drop target, the drop target parent or another child */	
	if (nil == validDropTarget)
	{
		return NSDragOperationNone;
	}

	BOOL isRetargeted = ([validDropTarget isEqual: dropTarget] == NO || dropIndex != row);

	if (isRetargeted)
	{
		NSInteger dropOp;
		NSInteger dropRow;

		if ([validDropTarget isEqual: _layoutContext])
		{
			dropOp = (ETUndeterminedIndex == dropIndex ? NSTableViewDropOn : NSTableViewDropAbove);
			dropRow = dropIndex;
		}
		else
		{
			dropOp = NSTableViewDropOn;
			dropRow = [_layoutContext indexOfObject: validDropTarget];

			if (NSNotFound == dropRow) /* NSNotFound is not ETUndeterminedIndex */
			{
				ETLog(@"WARNING: Drop target %@ doesn't belong to %@", validDropTarget, _layoutContext);
				return NSDragOperationNone;
			}
		}
		[tv setDropRow: dropRow dropOperation: dropOp];

		ETLog(@"Retarget drop to %i with op %i", dropRow, dropOp);
	}

	return NSDragOperationEvery;
}

- (BOOL) tableView: (NSTableView *)aTableView 
        acceptDrop: (id <NSDraggingInfo>)info 
               row: (int)row 
	 dropOperation: (NSTableViewDropOperation)op
{
    ETDebugLog(@"Accept drop in %@ drag mask %d drop op %d", _layoutContext, 
		[info draggingSourceOperationMask], op);

	id droppedObject = [[ETPickboard localPickboard] popObject];
	ETLayoutItem *baseItem = [(ETLayoutItem *)_layoutContext baseItem];
	ETLayoutItemGroup *dropTarget = _layoutContext;
	
	if (op == NSTableViewDropOn)
	{
		dropTarget = [[dropTarget arrangedItems] objectAtIndex: row];
	}

	[[baseItem actionHandler] handleDropObject: droppedObject 
	                                   atIndex: row
	                                    onItem: dropTarget
	                               coordinator: [ETPickDropCoordinator sharedInstance]];

	return YES;
}

- (void) tableView: (NSTableView *)tv sortDescriptorsDidChange: (NSArray *)oldDescriptors
{
	ETLog(@"Did change sort from %@ to %@", oldDescriptors, [tv sortDescriptors]);
	[[self layoutContext] sortWithSortDescriptors: [tv sortDescriptors] recursively: NO];
	[tv reloadData];
}

- (ETLayoutItem *) doubleClickedItem
{
	NSTableView *tv = [self tableView];
	NSArray *layoutItems = [[self layoutContext] arrangedItems];
	ETLayoutItem *item = [layoutItems objectAtIndex: [tv clickedRow]];
	
	return item;
}

/* Subclassing */

- (NSEvent *) lastDragEvent
{
	return _lastDragEvent;
}

- (void) setLastDragEvent: (NSEvent *)event
{
	ETDebugLog(@"Set last drag event to %@", event);
	_lastDragEvent = event;
}

@end

/* NSTableView overriden methods for dragging 

   NSTableViewDataSource doesn't provide a way to know whether a drag has been 
   cancelled (validated or moved). ETTableLayout must be aware of dragging 
   cancellation in order to pop the object just pushed on the pickboard in 
   -tableView:writeRowsWithIndexes:toPasteboard: and -handleDrag:forItem: 
   That's why we override dragging source related methods to simply call the
   default behavior implemented in ETEventHandler (see ETActionHandler). */

@interface NSTableView (ETTableLayoutDraggingSource)
- (id) actionHandler;
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)isLocal;
- (void) draggedImage: (NSImage *)anImage beganAt: (NSPoint)aPoint;
- (void) draggedImage: (NSImage *)draggedImage movedTo: (NSPoint)screenPoint;
- (void) draggedImage: (NSImage *)anImage endedAt: (NSPoint)aPoint operation: (NSDragOperation)operation;
@end
@interface NSTableView (ShutCompilerWarning)
- (BOOL) _writeRows: (NSIndexSet *)rows toPasteboard: (NSPasteboard *)pboard;
@end

@implementation NSTableView (ETTableLayoutDraggingSource)

// FIXME: Sort out the responsabilities more clearly between the coordinator, 
// the action handler and the table view

- (id) actionHandler
{
	// NOTE: Returning the delegate would equivalent.
	return [(ETLayoutItem *)[[self dataSource] layoutContext] actionHandler];
}

- (BOOL) ignoreModifierKeysWhileDragging
{
	return [[self actionHandler] ignoreModifierKeysWhileDragging];
}

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)isLocal
{
	return [[self actionHandler] draggingSourceOperationMaskForLocal: isLocal];
}

- (void) draggedImage: (NSImage *)anImage beganAt: (NSPoint)aPoint
{
	// FIXME: [[self eventHandler] draggedImage: anImage beganAt: aPoint];
}

- (void) draggedImage: (NSImage *)draggedImage movedTo: (NSPoint)screenPoint
{
	// FIXME: [[self eventHandler] draggedImage: draggedImage movedTo: screenPoint];
}

- (void) draggedImage: (NSImage *)anImage endedAt: (NSPoint)aPoint operation: (NSDragOperation)operation
{
	// FIXME: [[self eventHandler] draggedImage: anImage endedAt: aPoint operation: operation];
}

/* We implement this method only because [NSApp currentEvent] in 
   -tableView:writeRowsWithIndexes:toPasteboard: isn't the expected mouse down/dragged 
   event that triggered the drag when the mouse is moved/dragged very quickly. */
- (BOOL) canDragRowsWithIndexes: (NSIndexSet *)indexes atPoint: (NSPoint)point
{
	NSEvent *event = [NSApp currentEvent];

	// FIXME: Looks -convertPoint:toView: isn't exactly symetric to 
	// -convertPoint:fromView: in -_startDragOperationWithEvent:
#ifndef GNUSTEP	
	NSPoint pointInWindow = [self convertPoint: point toView: nil];

	/* We check the current event is precisely the mouse down (cocoa) or dragged 
	   (gnustep) event that triggers the present drag request */
	NSAssert3(NSEqualPoints([event locationInWindow], pointInWindow), @"For "
		@"%@, current event point %@ must be equal to point %@ passed by "
		@"-canDragRowsWithIndexes:point:", self, 
		NSStringFromPoint([event locationInWindow]), 
		NSStringFromPoint(pointInWindow));
#endif
	
	// NOTE: The present method is called by NSTableView so we must not send 
	// -setLastDragEvent: in case the table view is set up directly. For example, 
	// if you omit the -isKindOfClass: check it results in an unknown selector 
	// assertion if you drag a row in NSOpenPanel.
	if ([[self dataSource] isKindOfClass: [ETTableLayout class]])
	{
		[[self dataSource] setLastDragEvent: event];
	}

	return YES;
}

@end

/* Private Helper Methods (not in use) */

@implementation ETTableLayout (ETableLayoutDisplayViewGeneration)

/** Build a table view enclosed in a scroll view from scratch. */
- (NSScrollView *) scrollingTableView
{
	NSTableView *tv = nil;
	NSScrollView *prebuiltTableView = nil;
	NSRect rect = NSMakeRect(0, 0, 180, 100);
	
	prebuiltTableView = [[NSScrollView alloc] initWithFrame: rect];
	[prebuiltTableView setAutoresizingMask: NSViewHeightSizable];
	
	NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier: @"name"];
	
	[column setWidth: 180];
	[column setEditable: NO];
	
	rect = [[prebuiltTableView documentView] bounds];
	tv = [[NSTableView alloc] initWithFrame: rect];
	[tv setAutoresizingMask: NSViewHeightSizable];
	[tv addTableColumn: column];
	[prebuiltTableView setDocumentView: tv];
	DESTROY(column);
	RELEASE(tv);
	AUTORELEASE(prebuiltTableView);
	
	[tv setCornerView: nil];
	[tv setHeaderView: nil];
	
	return prebuiltTableView;
}

@end
