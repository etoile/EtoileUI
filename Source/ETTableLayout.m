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
#import "ETController.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "EtoileUIProperties.h"
#import "ETEvent.h"
#import "ETPickboard.h"
#import "ETPickDropActionHandler.h"
#import "ETPickDropCoordinator.h"
#import "NSCell+EtoileUI.h"
#import "ETCompatibility.h"

@interface NSTableColumn (Etoile) <ETColumnFragment>
@end

/* Private Interface */

@interface ETTableLayout (Private)
- (void) _updateDisplayedPropertiesFromSource;
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

	/* Will initialize several ivars in the layout copy */
	[newLayout setLayoutView: [newLayout layoutView]];
	newLayout->_contentFont = [_contentFont copyWithZone: aZone];
	newLayout->_sortable = _sortable;

	/* The target points on a random object since the original object (the 
	   receiver) was not archived by - [NSViewView copyWithZone:]. */
	[[newLayout tableView] setTarget: newLayout];

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

- (Class) widgetViewClass
{
	return [ETTableView class];
}

- (void) setLayoutView: (NSView *)protoView
{
	NSParameterAssert(nil != protoView);
	[super setLayoutView: protoView];

	NSTableView *tv = [self tableView];

	[self upgradeWidgetView: tv toClass: [self widgetViewClass]];

	/* ivar cannot be initialized by overriding -initWithLayoutView: because 
	   superclass initializer called -loadNibNamed: before returning, moreover
	   the ivar must be reset for each new layout view. */
	ASSIGN(_propertyColumns, [NSMutableDictionary dictionary]);
	_sortable = YES;

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

/** Returns the table view enclosed in the scroll view returned by -layoutView.

You shouldn't use this method unless you need to customize the table view in a way 
not supported by ETTableLayout API. */
- (NSTableView *) tableView
{
	id scrollView = [self layoutView];
	
	NSAssert2([scrollView isKindOfClass: [NSScrollView class]], @"Layout view "
		@" %@ of %@ must be an NSScrollView instance", scrollView, self);

	return [scrollView documentView];
}

/** Returns the underlying table columns used by the table view. 

You shouldn't use this method unless you need to customize the columns in a way 
not supported by ETTableLayout API. */
- (NSArray *) allTableColumns
{
	return [_propertyColumns allValues];
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

The property names are used as the column identifiers.

Will raise an NSInvalidArgumentException when the properties array is nil. */
- (void) setDisplayedProperties: (NSArray *)properties
{
	ETDebugLog(@"Set displayed properties %@ of layout %@", properties, self);

	NILARG_EXCEPTION_TEST(properties);

	/* We don't want to remove and add the columns every time the layout is 
	   updated through -renderWithItems:isNewContent:, othewise we loose 
	   various attributes such as the column selection.
	   e.g. this would happen every time the controller rearranges its content. */
	if ([properties isEqual: [self displayedProperties]])
		return;

	NSTableView *tv = [self tableView];

	/* Remove all existing columns
	   NOTE: We cannot enumerate [tv tableColumns] directly because we remove columns */
	FOREACH([NSArray arrayWithArray: [tv tableColumns]], column, NSTableColumn *)
	{
		if ([self canRemoveTableColumn: column])
		{
			[tv removeTableColumn: column];
		}
	}

	BOOL isFirstColumn = YES;

	/* Add all columns to be displayed */	
	FOREACH(properties, property, NSString *)
	{
		NSTableColumn *column = [_propertyColumns objectForKey: property];

		if (column == nil)
		{
			column = [self tableColumnWithIdentifierAndCreateIfAbsent: property];
			
		}

		BOOL shouldInsertColumn = [self prepareTableColumn: column 
		                                           isFirst: isFirstColumn];

		if (shouldInsertColumn)
		{
			[tv addTableColumn: column];
		}

		isFirstColumn = NO;
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

// NOTE: Gorm doesn't create editable data cell by default unlike IB and 
// doesn't provide a cell inspector.
// For both GNUstep and Cocoa, new NSCell and NSTextFieldCell instances returns 
// NO to -isEditable though.

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
	ETAssert(nil != column);
	/* A table view cell can be edited only if both [column isEditable] and 
	   [[column dataCell] isEditable] returns YES.
	   -[NSTableColumn isEditable] takes priority over the cell editability. */
	[[column dataCell] setEditable: flag];
	[column setEditable: flag];	
}

/** Returns the formatter of the column associated with the given property.

By default, columns have no formatters and nil returned. */
- (NSFormatter *) formatterForProperty: (NSString *)property
{
	return [[[_propertyColumns objectForKey: property] dataCell] formatter];
}

/** Sets the formatter of the column associated with the given property.

The object value returned by -valueForProperty: on each item must be compatible 
with the formatter, otherwise the outcome of the formatting is unknown. */
- (void) setFormatter: (NSFormatter *)aFormatter forProperty: (NSString *)property
{
	NSTableColumn *column = [self tableColumnWithIdentifierAndCreateIfAbsent: property];
	ETAssert(nil != column);
	/* We must reset the value, since on Mac OS X a new NSTextFieldCell is 
	   initialized with 'Field' as its object value. The formatter might not 
	   NSString as its input value. */
	[[column dataCell] setObjectValue: nil];
	[[column dataCell] setFormatter: aFormatter];
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

/** Sets whether the columns can be sorted by clicking on their headers. */
- (void) setSortable: (BOOL)isSortable
{
	_sortable = isSortable;
}

/** Returns whether the columns can be sorted by clicking on their headers.

By default, returns YES. */
- (BOOL) isSortable
{
	return _sortable;
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

#define SA(x) [NSSet setWithArray: x]

/** This method is only exposed to be used internally by EtoileUI.

Returns the column associated with the given property, the column might be 
visible or not depending on -displayedProperties. If the column doesn't exist 
yet, it is created. */
- (NSTableColumn *) tableColumnWithIdentifierAndCreateIfAbsent: (NSString *)property
{
	// TODO: Would be nicer with -containsCollection: or similar.
	ETAssert([SA([[self tableView] tableColumns]) isSubsetOfSet: SA([_propertyColumns allValues])]);

	NSTableColumn *column = [_propertyColumns objectForKey: property];

	if (column == nil)
	{
		column = [self createTableColumnWithIdentifier: property];
		[_propertyColumns setObject: column forKey: property];
	}

	return column;
}

- (NSSortDescriptor *) createSortDescriptorWithKey: (NSString *)property
{
	NSParameterAssert(nil != property);

	 if ([property isEqual: @""])
	 	return nil;

	NSString *keyPath = [NSString stringWithFormat: @"%@.%@", kETSubjectProperty, property];
	// TODO: -compare: is really a suboptimal choice in various cases.
	// For example, NSString provides -localizedCompare: unlike NSNumber, NSDate etc.
	return AUTORELEASE([[NSSortDescriptor alloc] 
		initWithKey: keyPath ascending: YES selector: @selector(compare:)]);
}

/** This method is only exposed to be used internally by EtoileUI.

Instantiates and returns a new table column initialized to integrate with 
ETTableLayout machinery. */
- (NSTableColumn *) createTableColumnWithIdentifier: (NSString *)property
{
	NSParameterAssert(nil != property);

	NSTableHeaderCell *headerCell = [[NSTableHeaderCell alloc] initTextCell: property]; // FIXME: Use display name
	NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier: property];

	[column setHeaderCell: headerCell];
	RELEASE(headerCell);

	NSParameterAssert([[column dataCell] isKindOfClass: [NSTextFieldCell class]]);
	if ([self contentFont] != nil)
	{
		[[column dataCell] setFont: [self contentFont]];
	}

	[column setEditable: NO];
	[column setSortDescriptorPrototype: [self createSortDescriptorWithKey: property]];

	return AUTORELEASE(column);
}

/** This method is only exposed to be used internally by EtoileUI.

Returns whether the given column can be removed from the widget.

By default, returns YES since all NSTableView columns can be removed. */
- (BOOL) canRemoveTableColumn: (NSTableColumn *)aTableColumn
{
	return YES;
}

/** This method is only exposed to be used internally by EtoileUI.

Gives the possibility to customize every table column archived with the widget 
or just instantiated by -createTableColumnWithIdentifier: and returns whether 
the column should be inserted in the widget or not (in case the column was not 
removed or this method handles the insertion).<br />
By default, only sets a sort descriptor prototype when there is none, and 
returns YES.

This method will be invoked every time the displayed properties change and 
a new column not in use previously needs to be prepared. */
- (BOOL) prepareTableColumn: (NSTableColumn *)aTableColumn isFirst: (BOOL)isFirstColumn
{
	if ([aTableColumn sortDescriptorPrototype] == nil)
	{
		[aTableColumn setSortDescriptorPrototype: 
			[self createSortDescriptorWithKey: [aTableColumn identifier]]];
	}
	return YES;
}

/** Returns the column associated with the given property.

See [(ETColumnFragment)] protocol to customize the returned column. */
- (id <ETColumnFragment>) columnForProperty: (NSString *)property
{
	return [self tableColumnWithIdentifierAndCreateIfAbsent: property];
}

/* Layouting */

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent
{
	if ([_layoutContext supervisorView] == nil)
	{
		ETLog(@"WARNING: Layout context %@ must have a supervisor view otherwise "
			@"view-based layout %@ cannot be set", _layoutContext, self);
		return;
	}

	[self resizeLayoutItems: items 
	          toScaleFactor: [_layoutContext itemScaleFactor]];

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
	
	if (ETUndeterminedIndex != row)
		return [[_layoutContext arrangedItems] objectAtIndex: row];
	
	return nil;
}

- (NSRect) displayRectOfItem: (ETLayoutItem *)item
{
	int row = [[_layoutContext arrangedItems] indexOfObject: item];
	return [[self tableView] rectOfRow: row];
}

/** Invalidates the row associated with the given item. */
- (void) setNeedsDisplayForItem: (ETLayoutItem *)anItem
{
	[[self tableView] setNeedsDisplayInRect: [self displayRectOfItem: anItem]];
}

- (void) selectionDidChangeInLayoutContext: (id <ETItemSelection>)aSelection
{
	[[self tableView] selectRowIndexes: [aSelection selectionIndexes]
	              byExtendingSelection: NO];
}

- (NSArray *) selectedItems
{
	NSIndexSet *indexes = [[self tableView] selectedRowIndexes];
	NSEnumerator *indexEnumerator = [indexes objectEnumerator];
	NSArray *items = [_layoutContext arrangedItems];
	NSMutableArray *selectedItems = 
		[NSMutableArray arrayWithCapacity: [indexes count]];
	
	FOREACHE(nil, index, NSNumber *, indexEnumerator)
	{
		[selectedItems addObject: [items objectAtIndex: [index intValue]]];
	}
	
	return selectedItems;
}

- (void) tableViewSelectionDidChange: (NSNotification *)notif
{
	[self didChangeSelectionInLayoutView];
}

/* NSTableView only considers if the column is editable by default to allow 
   or deny the editing on GNUstep. On Cocoa the data cell editability is 
   checked when the column is editable.
   We implement this delegate method to make the behavior the same everywhere.
   Take note this method is only invoked when the column is editable.*/
- (BOOL) tableView: (NSTableView *)tv
	shouldEditTableColumn: (NSTableColumn *)column row: (int)rowIndex
{
	NSParameterAssert([column isEditable]);

	// TODO: If we pose our own NSTableColumn subclass as an NSTableColumn 
	// replacement class, we could provide multiple custom data cells per 
	// column. That would useful to enable/disable the cell editing based on 
	// whether the object owning the property specifies it as read-only or not.
	// Another approach, probably better is to implement the new 10.5 delegate 
	// method -tableview:dataCellForTableColumn:row: and then calls 
	// -preparedCellAtColumn:row:
	NSCell *dataCell = [column dataCellForRow: rowIndex];

	ETAssert([dataCell font] != nil); /* Field editor won't be inserted otherwise */
	return [dataCell isEditable];
}

/* Cocoa seems to contradict the documentation of -[NSTableView setDoubleAction:] 
   by always disabling all editing if a double action is set. 
   To work around this issue, we override -[ETWidgetLayout doubleClick:] to 
   trigger the editing when the clicked cell can be edited.
   This method is the table view double action. */
- (void) doubleClick: (id)sender
{
	NSTableView *tv = [self tableView];

	if ([tv clickedRow] == -1) /* e.g. a double click on a column header */
		return;

	NSTableColumn *tableColumn = [[tv tableColumns] objectAtIndex: [tv clickedColumn]];
	BOOL canEdit = ([tableColumn isEditable] && 
		[self tableView: tv shouldEditTableColumn: tableColumn row: [tv clickedRow]]);

	if (canEdit)
	{
		[tv editColumn: [tv clickedColumn] 
		           row: [tv clickedRow] 
		     withEvent: [NSApp currentEvent] 
		        select: YES];
		return;	
	}

	/* Otherwise send the double action */
	[super doubleClick: sender];
}

- (int) numberOfRowsInTableView: (NSTableView *)tv
{
	NSArray *layoutItems = [_layoutContext arrangedItems];
	
	ETDebugLog(@"Returns %d as number of items in table view %@", [layoutItems count], tv);
	
	return [layoutItems count];
}

/** This method is only exposed to be used internally by EtoileUI.

Retrieves the value provided by the item and returns an object value that is 
compatible with the cell used at the given row/column intersection.  */
- (id) objectValueForTableColumn: (NSTableColumn *)column 
                             row: (int)rowIndex 
                            item: (ETLayoutItem *)item
{
	NSParameterAssert(ETUndeterminedIndex != rowIndex);

	id value = [item valueForProperty: [column identifier]];
	BOOL blankColumnIdentifier = ([column identifier] == nil || [[column identifier] isEqual: @""]);
	NSTableView *tv = [self tableView];
	
	if (value == nil && ([tv numberOfColumns] == 1 || blankColumnIdentifier))
	{
		value = [item value];
	}

	//ETLog(@"Returns %@ at %i in %@", value, rowIndex, [tv primitiveDescription]);

	/* 'value' could be any objects at this point. 
	    When -[NSCell formatter] returns nil, -[NSCell setObjectValue:] converts 
	    values to a string representation with -attributedStringValue, 
	    -stringValue or -description when the value is not compatible with the cell.
		But we use -objectValueForObject: because on Mac OS X:
	    -[NSCell setObjectValue:] tends to copy the object
	    -[NSImageCell setObjectValue:] only accepts images */
	return [[column dataCellForRow: rowIndex] objectValueForObject: value];
}

- (id) tableView: (NSTableView *)tv 
	objectValueForTableColumn: (NSTableColumn *)column row: (int)rowIndex
{
	NSArray *items = [_layoutContext arrangedItems];
	
	if (rowIndex >= [items count])
	{
		ETLog(@"WARNING: Row index %d uncoherent with number of items %d in %@", 
			rowIndex, [items count], self);
		return nil;
	}
	
	return [self objectValueForTableColumn: column
	                                   row: rowIndex
	                                  item: [items objectAtIndex: rowIndex]];
}

- (void) tableView: (NSTableView *)tv 
	setObjectValue: (id)value forTableColumn: (NSTableColumn *)column row: (int)rowIndex
{
	NSArray *layoutItems = [_layoutContext arrangedItems];
	ETLayoutItem *item = nil;
	
	if (rowIndex >= [layoutItems count])
	{
		ETLog(@"WARNING: Row index %d uncoherent with number of items %d in %@", 
			rowIndex, [layoutItems count], self);
		return;
	}
	
	item = [layoutItems objectAtIndex: rowIndex];
	
	//ETLog(@"Sets %@ as object value in table view %@", value, [tv primitiveDescription]);

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

/** Returns YES. See [NSObject(ETLayoutPickAndDropIntegration)] protocol.

Note: For now, private method. */
- (BOOL) hasBuiltInDragAndDropSupport
{
	return YES;
}

- (BOOL) tableView: (NSTableView *)tv writeRowsWithIndexes: (NSIndexSet *)rowIndexes 
	toPasteboard: (NSPasteboard*)pboard 
{
	// NOTE: See -canDragRowsWithIndexes:atPoint: to understand -backendDragEvent
	NSEvent *backendEvent = [self backendDragEvent]; 
	NSEventType eventType = [backendEvent type];

	NSParameterAssert([[backendEvent window] isEqual: [tv window]]);
	NSParameterAssert(eventType == NSLeftMouseDown || eventType == NSLeftMouseDragged);
	
	/* Convert drag location from window coordinates to the receiver coordinates */
	NSPoint localPoint = [tv convertPoint: [backendEvent locationInWindow] fromView: nil];
	ETLayoutItem *draggedItem = [self itemAtLocation: localPoint];
	ETEvent *dragEvent = ETEVENT(backendEvent, nil, ETDragPickingMask);
	NSPoint point = NSZeroPoint;

	DESTROY(_dragImage);
	ASSIGN(_dragImage, [tv dragImageForRowsWithIndexes: rowIndexes 
	                                      tableColumns: [tv visibleTableColumns] 
	                                             event: backendEvent
	                                            offset: &point]);

	return [[draggedItem actionHandler] handleDragItem: draggedItem 
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
		dropTarget = [[_layoutContext arrangedItems] objectAtIndex: row];
	}

	ETLog(@"Validate drop on %@ with dragging source %@ in %@ drag mask %d drop op %d", 
		[dropTarget primitiveDescription], [[info draggingSource] primitiveDescription], 
		_layoutContext, [info draggingSourceOperationMask], op);
	
	id draggedObject = [[ETPickboard localPickboard] firstObject];
	NSInteger dropIndex = (NSTableViewDropAbove == op ? row : ETUndeterminedIndex);
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
			dropRow = [[_layoutContext arrangedItems] indexOfObject: validDropTarget];

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
	ETLayoutItemGroup *dropTarget = _layoutContext;
	
	if (op == NSTableViewDropOn)
	{
		dropTarget = [[dropTarget arrangedItems] objectAtIndex: row];
	}

	[[dropTarget actionHandler] handleDropObject: droppedObject 
	                                     atIndex: row
	                                      onItem: dropTarget
	                                 coordinator: [ETPickDropCoordinator sharedInstance]];

	return YES;
}

- (NSArray *) customSortDescriptorsForSortDescriptors: (NSArray *)currentSortDescriptors
{
	if ([self isSortable] == NO)
		return	[super customSortDescriptorsForSortDescriptors: currentSortDescriptors];

	NSParameterAssert(nil != currentSortDescriptors);

	NSArray *tableSortDescriptors = [[self tableView] sortDescriptors];
	NSArray *currentSortKeys = (id)[[currentSortDescriptors mappedCollection] key];
	NSMutableArray *sortDescriptors = AUTORELEASE([currentSortDescriptors mutableCopy]);

	FOREACH(tableSortDescriptors, descriptor, NSSortDescriptor *)
	{
		NSString *tableColumnSortKey = [descriptor key];

		if ([currentSortKeys containsObject: tableColumnSortKey] == NO)
		{
			[sortDescriptors addObject: descriptor];
		}
	}

	return sortDescriptors;
}

/** This method is only exposed to be used internally by EtoileUI.

Sorts the widget rows with the current sort descriptors and updates the display.<br />
When a recursive sorting is requested, the layout item tree is sorted recursively.

When the receiver is not sortable, returns immediately. 

The current sort descriptors are collected as explained in the class description. */
- (void) trySortRecursively: (BOOL)recursively oldSortDescriptors: (NSArray *)oldDescriptors
{
	if ([self isSortable] == NO)
		return;

	ETController *controller = [[_layoutContext baseItem] controller];
	NSArray *sortDescriptors = [controller sortDescriptors];

	if (nil == sortDescriptors)
	{
		sortDescriptors = [NSArray array];
	}

	ETLog(@"Controller sort %@", sortDescriptors);	
	ETLog(@"Did change sort from %@ to %@", oldDescriptors, [[self tableView] sortDescriptors]);
	
	/* We cannot check -[ETLayoutItemGroup isFiltered] because the predicate is 
	   provided externally (e.g. by an ETController instance). */
	BOOL isFiltered = (nil != controller && nil != [controller filterPredicate]);

	/* Will call back -customSortDescriptorsWithSortDescriptors: which returns 
	   the new real sort descriptors. */
	[_layoutContext sortWithSortDescriptors: sortDescriptors recursively: recursively];
	if (isFiltered)
	{
		[_layoutContext filterWithPredicate: [controller filterPredicate] recursively: recursively];
	}
	[[self tableView] reloadData];
}

/* In response to a column header click, the table view updates it sort 
descriptor array with -[NSTableView setSortDescriptors:] which in turn invokes 
this delegate method. When -setSortDescriptors: returns, the table view calls 
-tableView:didClickTableColumn:. */
- (void) tableView: (NSTableView *)tv sortDescriptorsDidChange: (NSArray *)oldDescriptors
{
	[self trySortRecursively: NO oldSortDescriptors: oldDescriptors];
}

- (ETLayoutItem *) doubleClickedItem
{
	NSTableView *tv = [self tableView];
	NSArray *layoutItems = [_layoutContext arrangedItems];

	ETAssert([tv clickedRow] != -1);

	return [layoutItems objectAtIndex: [tv clickedRow]];
}

/* Framework Private & Subclassing */

/** This method is only exposed to be used internally by EtoileUI.

Returns the widget event that tries to start a drag session. */
- (NSEvent *) backendDragEvent
{
	return _backendDragEvent;
}

/** This method is only exposed to be used internally by EtoileUI.

Sets the widget event that tries to start a drag session.

This method must be invoked by the widget (e.g. ETTableView) on every attempt to 
start a drag. */
- (void) setBackendDragEvent: (NSEvent *)event
{
	ETDebugLog(@"Set backend drag event to %@", event);
	_backendDragEvent = event;
}

/** This method is only exposed to be used internally by EtoileUI.

Returns the cached drag image. */
- (NSImage *) dragImage
{
	return _dragImage;
}

@end


/* NSTableViewDataSource doesn't provide a way to know whether a drag has been 
   cancelled (validated or moved). ETTableLayout must be aware of dragging 
   cancellation in order to pop the object just pushed on the pickboard in 
   -tableView:writeRowsWithIndexes:toPasteboard: and -handleDragItemXXX 
   That's why we override dragging source related methods (see ETActionHandler). */
@implementation ETTableView 

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
	if ([[NSTableView class] instancesRespondToSelector: @selector(draggedImage:beganAt:)])
	{
		[super draggedImage: anImage beganAt: aPoint];
	}
	[[ETPickDropCoordinator sharedInstance] draggedImage: anImage beganAt: aPoint];
}

- (void) draggedImage: (NSImage *)anImage movedTo: (NSPoint)aPoint
{
	if ([[NSTableView class] instancesRespondToSelector: @selector(draggedImage:movedTo:)])
	{
		[super draggedImage: anImage movedTo: aPoint];
	}
	[[ETPickDropCoordinator sharedInstance] draggedImage: anImage movedTo: aPoint];
}

- (void) draggedImage: (NSImage *)anImage endedAt: (NSPoint)aPoint operation: (NSDragOperation)operation
{
	if ([[NSTableView class] instancesRespondToSelector: @selector(draggedImage:endedAt:operation:)])
	{
		[super draggedImage: anImage endedAt: aPoint operation: operation];
	}
	[[ETPickDropCoordinator sharedInstance] draggedImage: anImage endedAt: aPoint operation: operation];
}

/* We implement this method only because [NSApp currentEvent] in 
   -tableView:writeRowsWithIndexes:toPasteboard: isn't the expected mouse down/dragged 
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

@end


@implementation NSTableView (EtoileUI)

/** Returns the column objects which are partially or fully visible in the 
receiver. */
- (NSArray *) visibleTableColumns
{
	NSIndexSet *columnIndexes = [self columnIndexesInRect: [self visibleRect]];
	NSEnumerator *indexEnumerator = [columnIndexes objectEnumerator];
	NSMutableArray *columns = [NSMutableArray array];

	// TODO: Would be interesting to express the loop as below...
	// return [[[self tableColumns] slicedCollection] objectAtIndex: [[columnIndexes each] intValue]];
	FOREACHE(nil, index, NSNumber *, indexEnumerator)
	{
		/* We don't use -addObject: to carry the ordering over. */
		[columns insertObject: [[self tableColumns] objectAtIndex: [index intValue]] 
		              atIndex: 0];
	}

	return columns;
	
}

@end
