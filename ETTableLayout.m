/*  <title>ETTableLayout</title>

	ETTableLayout.m
	
	<abstract>Description forthcoming.</abstract>
 
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

#import <EtoileUI/ETTableLayout.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItem+Events.h>
#import <EtoileUI/ETEvent.h>
#import <EtoileUI/ETLayoutLine.h>
#import <EtoileUI/ETPickboard.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/ETCompatibility.h>

#define ETLog NSLog

/* Private Interface */

@interface ETTableLayout (Private)
- (void) _updateDisplayedPropertiesFromSource;
- (NSTableColumn *) _createTableColumnWithIdentifier: (NSString *)property;
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
		
	[super dealloc];
}

- (void) awakeFromNib
{
	NSLog(@"Awaking from nib for %@", self);
	
	/* Because this outlet will be removed from its superview, it must be 
	   retained like any other to-one relationship ivars. 
	   If this proto view is later replaced by calling 
	   -setLayoutView:, this retain will be balanced by the release
	   in ASSIGN. */ 
	RETAIN(_displayViewPrototype);

	/* Adjust _displayViewPrototype outlet */
	[self setLayoutView: _displayViewPrototype];
}

- (void) setLayoutView: (NSView *)protoView
{
	[super setLayoutView: protoView];

	NSTableView *tv = [(NSScrollView *)[self layoutView] documentView];
	NSEnumerator *e = [[tv tableColumns] objectEnumerator];
	NSTableColumn *column = nil;
	
	/* ivar cannot be initialized by overriding -initWithLayoutView: because 
	   superclass initializer called -loadNibNamed: before returning, moreover
	   the ivar must reset for each new layout view. */
	ASSIGN(_propertyColumns, [NSMutableDictionary dictionary]);

	/* Retain initial columns to be able to restore exactly identical columns later */	
	while ((column = [e nextObject]) != nil)
	{
		NSString *colId = [column identifier];
		
		// NOTE: May be should insert a positional number because the current
		// blank string limits us to a single column without identifier
		if (colId == nil)
			colId = @"";
		
		[_propertyColumns setObject: column forKey: colId];
	}
	/* Set up a list view using a single column without identifier */
	//[self setDisplayedProperties: [self displayedProperties]];	
	[tv registerForDraggedTypes: [NSArray arrayWithObject: @"ETLayoutItemPboardType"]];
	
	if ([tv dataSource] == nil)
		[tv setDataSource: self];
	if ([tv delegate] == nil)
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
	// FIXME: return copy or not? I don't think so.
	return [_propertyColumns allValues];
}

- (void) setAllTableColumns: (NSArray *)columns
{
	ASSIGN(_propertyColumns, columns);
}

/* Item Property Display */

- (NSArray *) displayedProperties
{
	return [[[self tableView] tableColumns] valueForKey: @"identifier"];
}

/* Update column visibility */
- (void) setDisplayedProperties: (NSArray *)properties
{
	NSMutableArray *displayedProperties = [properties mutableCopy];
	NSTableView *tv = [self tableView];
	/* We cannot enumerate [tv tableColumns] directly because we remove columns */
	NSEnumerator *e = [[NSArray arrayWithArray: [tv tableColumns]] objectEnumerator];
	NSTableColumn *column = nil;
	NSString *property = nil;
	
	/* Remove all existing columns */
	while ((column = [e nextObject]) != nil)
		[tv removeTableColumn: column];
	
	/* Add all columns to be displayed */
	e = [displayedProperties objectEnumerator];
	property = nil;
	column = nil;
	
	while ((property = [e nextObject]) != nil)
	{
		column = [_propertyColumns objectForKey: property];
		
		if (column == nil)
			column = [self _createTableColumnWithIdentifier: property];
		
		[tv addTableColumn: column];
	}
}

- (void) _updateDisplayedPropertiesFromSource
{
	if ([[[self container] source] respondsToSelector: @selector(displayedItemPropertiesInContainer:)])
	{
		NSArray *properties = [[[self container] source] 
			displayedItemPropertiesInContainer: [self container]];		
			
		[self setDisplayedProperties: properties];
	}
}

- (NSString *) displayNameForProperty: (NSString *)property
{
	return [[[_propertyColumns objectForKey: property] headerCell] stringValue];
}

/** Override */
- (void) setDisplayName: (NSString *)displayName forProperty: (NSString *)property
{
	NSTableColumn *column = [_propertyColumns objectForKey: property];
	
	if (column == nil)
	{
		column = [self _createTableColumnWithIdentifier: property];
		[_propertyColumns setObject: column forKey: property];
	}

	[[column headerCell] setStringValue: displayName];
}

- (id) styleForProperty: (NSString *)property
{
	return [[_propertyColumns objectForKey: property] dataCell];

//	return [[[self tableView] tableColumnWithIdentifier: property] dataCell];
}

- (void) setStyle: (id)style forProperty: (NSString *)property
{
	NSTableColumn *column = [_propertyColumns objectForKey: property];
	
	if (column == nil)
	{
		column = [self _createTableColumnWithIdentifier: property];
		[_propertyColumns setObject: column forKey: property];
	}

	[column setDataCell: style];

//	[[[self tableView] tableColumnWithIdentifier: property] setDataCell: style];
}

- (NSTableColumn *) _createTableColumnWithIdentifier: (NSString *)property
{
	NSTableHeaderCell *headerCell = [[NSTableHeaderCell alloc] initTextCell: property]; // FIXME: Use display name
	NSCell *dataCell = [[NSCell alloc] initTextCell: @""];
	NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier: property];

	[column setHeaderCell: headerCell];
	RELEASE(headerCell);
	[dataCell setEditable: YES]; // FIXME: why column setEditable: isn't enough
	[column setDataCell: dataCell];
	RELEASE(dataCell);
	[column setEditable: YES];
	
	return AUTORELEASE(column);
}

/* Layouting */

- (void) renderWithLayoutItems: (NSArray *)items
{
	if ([self container] == nil)
	{
		ETLog(@"WARNING: Layout context %@ must have a container otherwise "
			@"view-based layout %@ cannot be set", [self layoutContext], self);
		return;
	}
	
	[self setUpLayoutView];
	
	[self resizeLayoutItems: items toScaleFactor: [[self layoutContext] itemScaleFactor]];
	
	if ([[self container] source] != nil)
		[self _updateDisplayedPropertiesFromSource];
				
	[[self tableView] reloadData];
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
		return [[[self layoutContext] items] objectAtIndex: row];
	
	return item;
}

- (NSRect) displayRectOfItem: (ETLayoutItem *)item
{
	int row = [[[self layoutContext] items] indexOfObject: item];
	
	return [[self tableView] rectOfRow: row];
}

- (NSArray *) selectedItems
{
	NSIndexSet *indexes = [[self tableView] selectedRowIndexes];
	NSEnumerator *e = [indexes objectEnumerator];
	NSNumber *index = nil;
	NSMutableArray *selectedItems = 
		[NSMutableArray arrayWithCapacity: [indexes count]];
	
	while ((index = [e nextObject]) != nil)
	{
		id item = [[[self layoutContext] items] objectAtIndex: [index intValue]];
		
		[selectedItems addObject: item];
	}
	
	return selectedItems;
}

/* Keep in mind this method is also used by ETOutlineLayout which overrides
   -selectedItems. */
- (void) tableViewSelectionDidChange: (NSNotification *)notif
{
	id delegate = [[self container] delegate];
	NSTableView *tv = [self tableView];
	NSArray *layoutSelectedItems = [self selectedItems];
	NSArray *selection = [layoutSelectedItems valueForKey: @"indexPath"];
	
	/* Update selection state in the layout item tree */
	[[self container] setSelectionIndexPaths: selection];

	if ([delegate respondsToSelector: @selector(tableViewSelectionDidChange:)])
	{
		[delegate tableViewSelectionDidChange: notif];
	}
	/*if ([delegate respondsToSelector: @selector(containerSelectionDidChange:)])
	{
		NSNotification *containerNotif =
			[NSNotification notificationWithName: [notif name] 
			                              object: [self container] 
										userInfo: [notif userInfo]];
		
		[delegate containerSelectionDidChange: containerNotif];
	}*/
}

// TODO: Implement forwarding of all delegate methods to ETContainer delegate by
// overriding -respondsToSelector: and forwardInvocation:
// Put this forward code into ETLayout
- (void) tableView: (NSTableView *)tv willDisplayCell: (id)cell
    forTableColumn: (NSTableColumn *)col row: (int)row
{
	ETLayoutItem *item = [[[self container] items] objectAtIndex: row];
	NSString *colIdentifier = [col identifier];
	id delegate = [[self container] delegate];

	if ([delegate respondsToSelector: @selector(layoutItem:setValue:forProperty:)])
	{
		// NOTE: May we do this only on reload
		[delegate layoutItem: item setValue: [item valueForProperty: colIdentifier] forProperty: colIdentifier];
	}
	if ([delegate respondsToSelector: @selector(tableView:willDisplayCell:forTableColumn:row:)])
	{
		[delegate tableView: tv willDisplayCell: cell forTableColumn: col row: row];
	}
}

- (int) numberOfRowsInTableView: (NSTableView *)tv
{
	NSArray *layoutItems = [[self layoutContext] items];
	
	NSLog(@"Returns %d as number of items in table view %@", [layoutItems count], tv);
	
	return [layoutItems count];
}

- (id) tableView: (NSTableView *)tv objectValueForTableColumn: (NSTableColumn *)column row: (int)rowIndex
{
	NSArray *layoutItems = [[self layoutContext] items];
	ETLayoutItem *item = nil;
	
	if (rowIndex >= [layoutItems count])
	{
		ETLog(@"WARNING: Row index %d uncoherent with number of items %d in %@", rowIndex, [layoutItems count], self);
		return nil;
	}
	
	item = [layoutItems objectAtIndex: rowIndex];
	
	ETLog(@"Returns %@ as object value in table view %@", [item valueForProperty: [column identifier]], tv);
	
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
	NSArray *layoutItems = [[self layoutContext] items];
	ETLayoutItem *item = nil;
	
	if (rowIndex >= [layoutItems count])
	{
		ETLog(@"WARNING: Row index %d uncoherent with number of items %d in %@", rowIndex, [layoutItems count], self);
		return;
	}
	
	item = [layoutItems objectAtIndex: rowIndex];
	
	//ETLog(@"Sets %@ as object value in table view %@", value, tv);
	
	BOOL result = [item setValue: value forProperty: [column identifier]];
	BOOL blankColumnIdentifier = [column identifier] == nil || [[column identifier] isEqual: @""];
	
	if (result == NO && ([tv numberOfColumns] == 1 || blankColumnIdentifier))
		[item setValue: value];
}

/*- (void) handleDrag: (NSEvent *)event forItem: (id)item
{

}*/

- (void) beginDrag: (ETEvent *)event forItem: (id)item 
	image: (NSImage *)customDragImage layout: (id)layout
{
	ETLog(@"Overriden -beginDrag:forItem:image: in %@", self);
	/* Overriden to do nothing and let the table view creates and manages the 
	   drag object. This method is called by -handleDrag:forItem:. */
}

- (int) dropIndexAtLocation: (NSPoint)localDropPosition forItem: (id)item on: (id)dropTargetItem
{
	int childDropIndex = _lastChildDropIndex;

	/* Drop index is -1 when the drop occurs on a row (highlighted) or 
	   underneath the last row (in the blank area) */
	if (childDropIndex == -1)
	{
		childDropIndex = NSNotFound;
	}
	else if ([dropTargetItem isEqual: [self layoutContext]] == NO)
	{
		childDropIndex = [dropTargetItem numberOfItems] - 1;
	}
	
	return childDropIndex;
}

- (BOOL) tableView: (NSTableView *)tv writeRowsWithIndexes: (NSIndexSet *)rowIndexes 
	toPasteboard: (NSPasteboard*)pboard 
{
#if 0
	// NOTE: On Mac OS X, -currentEvent returns a later event rather than the 
	// mouse down that began the drag when the user moves the mouse too quickly.
	id dragEvent = ETEVENT([NSApp currentEvent], nil, ETDragPickingMask);
#else
	id dragEvent = ETEVENT([self lastDragEvent], nil, ETDragPickingMask);
#endif

	NSAssert3([[dragEvent window] isEqual: [tv window]], @"NSApp current "
		@"event %@ in %@ -tableView:writeRowsWithIndexes:toPasteboard: doesn't "
		@"belong to the table view %@", dragEvent, self, tv);
	NSAssert3([dragEvent type] == NSLeftMouseDown, @"NSApp current "
		@"event %@ in %@ -tableView:writeRowsWithIndexes:toPasteboard: must be "
		@"of type NSLeftMouseDown", dragEvent, self, tv);
	
	/* Convert drag location from window coordinates to the receiver coordinates */
	NSPoint localPoint = [tv convertPoint: [dragEvent locationInWindow] fromView: nil];
	id draggedItem = [self itemAtLocation: localPoint];
	id baseItem = [[self layoutContext] baseItem];
		
	[baseItem handleDrag: dragEvent forItem: draggedItem layout: self];
	
	return YES;
}

- (NSDragOperation) tableView:(NSTableView*)tv 
                 validateDrop: (id <NSDraggingInfo>)info 
				  proposedRow: (int)row 
	    proposedDropOperation: (NSTableViewDropOperation)op 
{
    ETLog(@"Validate drop with dragging source %@ in %@", [info draggingSource], [self container]);
	id dropTargetItem = [self layoutContext];
	
	if (op == NSTableViewDropOn)
		dropTargetItem = [[dropTargetItem items] objectAtIndex: row];
		
	// TODO: Replace by [layoutContext handleValidateDropForObject:] and improve
	if (dropTargetItem == nil || [dropTargetItem isGroup])
	{
		return NSDragOperationEvery;
	}
	else
	{
		return NSDragOperationNone;
	}
}

- (BOOL) tableView: (NSTableView *)aTableView 
        acceptDrop: (id <NSDraggingInfo>)info 
               row: (int)row 
	 dropOperation: (NSTableViewDropOperation)op
{
    ETLog(@"Accept drop in %@", [self container]);
	id droppedItem = [[ETPickboard localPickboard] popObject];
	id dropTargetItem = [self layoutContext];
	
	if (op == NSTableViewDropOn)
		dropTargetItem = [[dropTargetItem items] objectAtIndex: row];

	id baseItem = [[self layoutContext] baseItem];
		
	_lastChildDropIndex = row;
	[baseItem handleDrop: info forItem: droppedItem on: dropTargetItem];
	return YES;
}


- (ETLayoutItem *) doubleClickedItem
{
	NSTableView *tv = [self tableView];
	NSArray *layoutItems = [[self layoutContext] items];
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
	_lastDragEvent = event;
}

@end

/* NSTableView overriden methods for dragging 

   NSTableViewDataSource doesn't provide a way to know whether a drag has been 
   cancelled (validated or moved). ETTableLayout must be aware of dragging 
   cancellation in order to pop the object just pushed on the pickboard in 
   -tableView:writeRowsWithIndexes:toPasteboard: and -handleDrag:forItem: 
   That's why we override dragging source related methods to simply call the
   default behavior implemented in ETEventHandler (see ETLayoutItem+Events). */

@interface NSTableView (ETTableLayoutDraggingSource)
- (id) eventHandler;
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)isLocal;
- (void) draggedImage: (NSImage *)anImage beganAt: (NSPoint)aPoint;
- (void) draggedImage: (NSImage *)draggedImage movedTo: (NSPoint)screenPoint;
- (void) draggedImage: (NSImage *)anImage endedAt: (NSPoint)aPoint operation: (NSDragOperation)operation;
@end

@implementation NSTableView (ETTableLayoutDraggingSource)

- (id) eventHandler
{
	// NOTE: Returning the delegate would equivalent.
	return [[self dataSource] layoutContext];
}

- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)isLocal
{
	return [[self eventHandler] draggingSourceOperationMaskForLocal: isLocal];
}

- (void) draggedImage: (NSImage *)anImage beganAt: (NSPoint)aPoint
{
	[[self eventHandler] draggedImage: anImage beganAt: aPoint];
}

- (void) draggedImage: (NSImage *)draggedImage movedTo: (NSPoint)screenPoint
{
	[[self eventHandler] draggedImage: draggedImage movedTo: screenPoint];
}

- (void) draggedImage: (NSImage *)anImage endedAt: (NSPoint)aPoint operation: (NSDragOperation)operation
{
	[[self eventHandler] draggedImage: anImage endedAt: aPoint operation: operation];
}

/* We implement this method only because [NSApp currentEvent] in 
   -tableView:writeRowsWithIndexes:toPasteboard: isn't the expected mouse down 
   event that triggered the drag when the mouse is moved/dragged very quickly. */
- (BOOL) canDragRowsWithIndexes: (NSIndexSet *)indexes atPoint: (NSPoint)point
{
	NSEvent *event = [NSApp currentEvent];
	NSPoint pointInWindow = [self convertPoint: point toView: nil];
	
	/* We check the current event is precisely the mouse down event that 
	   triggers the present drag request */
	NSAssert3(NSEqualPoints([event locationInWindow], pointInWindow), @"For "
		@"%@, current event point %@ must be equal to point %@ passed by "
		@"-canDragRowsWithIndexes:point:", self, 
		NSStringFromPoint([event locationInWindow]), 
		NSStringFromPoint(pointInWindow));
	
	[[self dataSource] setLastDragEvent: event];
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
