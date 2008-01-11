/*  <title>ETOutlineLayout</title>

	ETOutlineLayout.m
	
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

#import <EtoileUI/ETOutlineLayout.h>
#import <EtoileUI/ETLayout.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItem+Events.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETLayoutLine.h>
#import <EtoileUI/ETPickboard.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/ETCompatibility.h>

@interface ETTableLayout (PackageVisibility)
- (void) tableViewSelectionDidChange: (NSNotification *)notif;
@end


@implementation ETOutlineLayout

- (id) initWithLayoutView: (NSView *)layoutView
{
	self = [super initWithLayoutView: layoutView];
    
	if (self != nil)
	{
		_treatsGroupsAsStacks = YES;
    }
    
	return self;
}

- (NSString *) nibName
{
	return @"OutlinePrototype";
}

- (NSOutlineView *) outlineView
{
	return (NSOutlineView *)[super tableView];
}

// NOTE: Dealloc and Awaking from nib handled by ETTableLayout superview.

/* Update column visibility */
- (void) setDisplayedProperties: (NSArray *)properties
{
	NSMutableArray *displayedProperties = [properties mutableCopy];
	NSOutlineView *tv = [self outlineView];
	/* We cannot enumerate [tv tableColumns] directly because we remove columns */
	NSEnumerator *e = [[NSArray arrayWithArray: [tv tableColumns]] objectEnumerator];
	NSTableColumn *column = nil;
	NSString *property = nil;
	
	/* Remove all existing columns except the outline column */
	while ((column = [e nextObject]) != nil)
	{
		if ([column isEqual: [tv outlineTableColumn]] == NO)
			[tv removeTableColumn: column];
	}
	
	/* Add all columns to be displayed and update the outline column */
	e = [displayedProperties objectEnumerator];
	property = nil;
	BOOL isFirstColumn = YES;
	
	while ((property = [e nextObject]) != nil)
	{
		NSTableColumn *column = [_propertyColumns objectForKey: property];
		
		if (column == nil)
			column = [self _createTableColumnWithIdentifier: property]; // FIXME: ETTableLayout private method
			
		if (isFirstColumn)
		{
			// FIXME: Modifying the outline table column directly leads to the 
			// loss of the hierarchical indicator, that's why we sync outline
			// column with first column attribute-by-attribute
			//[tv setOutlineTableColumn: column];
			NSTableColumn *tc = [tv outlineTableColumn];
			
			[tc setIdentifier: [column identifier]];
			[tc setDataCell: [column dataCell]];
			[tc setHeaderCell: [column headerCell]];
			[tc setWidth: [column width]];
			[tc setMinWidth: [column minWidth]];
			[tc setMaxWidth: [column maxWidth]];
			#ifdef GNUSTEP
			[tc setResizable: [column isResizable]];
			#else
			[tc setResizingMask: [column resizingMask]];
			#endif
			[tc setEditable: [column isEditable]];
			isFirstColumn = NO;
		}
		else
		{
			[tv addTableColumn: column];
		}
	}
}

/** Returns YES when every groups are displayed as stacks which can be expanded
	and collapsed by clicking on their related outline arrows. 
	When only stacks can be expanded and collapsed (in other words when 
	only stack-related rows have an outline arrow), returns NO. 
	By default, returns YES. */
- (BOOL) treatsGroupsAsStacks
{
	return _treatsGroupsAsStacks;
}

/** Sets whether the receiver handles every groups as stacks which can be 
	expanded and collapsed by getting automatically a related outline arrow. */
- (void) setTreatsGroupsAsStacks: (BOOL)flag
{
	_treatsGroupsAsStacks = flag;
}

- (ETLayoutItem *) itemAtLocation: (NSPoint)location
{
	int row = [[self outlineView] rowAtPoint: location];
	id item = nil;
	
	if (row != NSNotFound)
		item = [[self outlineView] itemAtRow: row];
	
	return item;
}

- (NSRect) displayRectOfItem: (ETLayoutItem *)item
{
	int row = [[self outlineView] rowForItem: item];
	
	return [[self outlineView] rectOfRow: row];
}

- (NSArray *) selectedItems
{
	NSIndexSet *indexes = [[self outlineView] selectedRowIndexes];
	NSEnumerator *e = [indexes objectEnumerator];
	NSNumber *index = nil;
	NSMutableArray *selectedItems = 
		[NSMutableArray arrayWithCapacity: [indexes count]];
	
	while ((index = [e nextObject]) != nil)
	{
		id item = [[self outlineView] itemAtRow: [index intValue]];
		
		[selectedItems addObject: item];
	}
	
	return selectedItems;
}

- (void) outlineViewSelectionDidChange: (NSNotification *)notif
{
	id delegate = [[self container] delegate];
	
	[self tableViewSelectionDidChange: notif];

	if ([delegate respondsToSelector: @selector(outlineViewSelectionDidChange:)])
	{
		[delegate outlineViewSelectionDidChange: notif];
	}
}

- (int) outlineView: (NSOutlineView *)outlineView numberOfChildrenOfItem: (id)item
{
	int nbOfItems = 0;
	
	if (item == nil)
	{
		nbOfItems = [[[self layoutContext] items] count];
	}
	else if ([item isGroup]) 
	{
		nbOfItems = [[item items] count];
		
		/* First time */
		if (nbOfItems == 0)
		{
			[item reload];
			nbOfItems = [[item items] count];
		}
	}
	
	//ETLog(@"Returns %d as number of items in %@", nbOfItems, outlineView);
	
	return nbOfItems;
}

- (id) outlineView: (NSOutlineView *)outlineView child: (int)rowIndex ofItem: (id)item
{
	ETLayoutItem *childItem = nil; /* Leaf by default */
	
	if (item == nil) /* Root */
	{
		childItem = [[[self layoutContext] items] objectAtIndex: rowIndex];
	}
	else if ([item isGroup]) /* Node */
	{
		childItem = [(ETLayoutItemGroup *)item itemAtIndex: rowIndex];
	}

	//ETLog(@"Returns % child item in outline view %@", childItem, outlineView);
	
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
	
	id value = [item valueForProperty: [column identifier]];
	BOOL blankColumnIdentifier = ([column identifier] == nil || [[column identifier] isEqual: @""]);
	
	if (value == nil && ([[self outlineView] numberOfColumns] == 1 || blankColumnIdentifier))
		value = [item value];

#ifndef GNUSTEP
	/* Try to convert invalid value into a dummy object value when needed 
	   (NSImageCell on Mac OS X) */
	NSCell *dataCell = [column dataCellForRow: [outlineView rowForItem: item]];
	
	if ([dataCell isKindOfClass: [NSImageCell class]]
	 && [value isKindOfClass: [NSImage class]] == NO)
	{
		/* Setting an invalid value on an image cell isn't supported. To be
		   sure, this never occurs we create a dummy image when value is nil. 
		   It usually happens when no property exists in item for [colum identifier]. */
		value = AUTORELEASE([[NSImage alloc] init]);
	}
#endif

	/* Report nil value for debugging */
	if (value == nil || [value isEqual: [NSNull null]]
	 && [[item properties] containsObject: [column identifier]] == NO)
	{
		// FIXME: Turn into an ETDebugLog
		ETLog(@"Item %@ has no property %@ requested by layout %@", item, 
			[column identifier], self);
	}

	//ETLog(@"Returns %@ as object value in outline view %@", value, outlineView);
	
	// NOTE: 'value' could be any objects at this point and NSCell only accepts
	// some common object values like string and number or image for 
	// NSImageCell. Unless a custom formatter has been set on the column or a 
	// custom cell has been provided, non common object values must be 
	// converted to a string or number representation, -objectValue precisely 
	// takes care of converting it to a string value. See -objectValue in 
	// NSObject+Model for more details.
	return [value objectValue];
}

- (void) outlineView: (NSOutlineView *)outlineView 
	setObjectValue: (id)value forTableColumn: (NSTableColumn *)column byItem: (id)item
{
	if (item == nil)
	{
		//ETLog(@"WARNING: Get nil item in -outlineView:objectValueForTableColumn:byItem: of %@", self);
		return;
	}
	
	BOOL result = [item setValue: value forProperty: [column identifier]];
	BOOL blankColumnIdentifier = [column identifier] == nil || [[column identifier] isEqual: @""];
	
	if (result == NO && ([[self outlineView] numberOfColumns] == 1 || blankColumnIdentifier))
		[item setValue: value];

	//ETLog(@"Sets %@ as object value in outline view %@", value, outlineView);
}

- (int) dropIndexAtLocation: (NSPoint)localDropPosition forItem: (id)item on: (id)dropTargetItem
{
	int childDropIndex = _lastChildDropIndex;
	
	/* Drop index is -1 when the drop occurs on a row (highlighted) or 
	   underneath the last row (in the blank area) */
	if (childDropIndex == NSOutlineViewDropOnItemIndex)
		childDropIndex = NSNotFound;
	
	return childDropIndex;
}

- (BOOL) outlineView: (NSOutlineView *)outlineView acceptDrop: (id < NSDraggingInfo >)info item: (id)item childIndex: (int)index
{
    //ETLog(@"Accept drop in %@", [self container]);
	id droppedItem = [[ETPickboard localPickboard] popObject];
	id dropTargetItem = item;
	
	if (dropTargetItem == nil) /* Root item */
		dropTargetItem = [self layoutContext];

	id baseItem = [[self layoutContext] baseItem];
	
	_lastChildDropIndex = index;
	[baseItem handleDrop: info forItem: droppedItem on: dropTargetItem];
	return YES;
}

- (NSDragOperation) outlineView: (NSOutlineView *)outlineView validateDrop: (id < NSDraggingInfo >)info proposedItem: (id)item proposedChildIndex: (int)index
{
    //ETLog(@"Validate drop with dragging source %@ in %@", [info draggingSource], [self container]);

	// TODO: Replace by [layoutContext handleValidateDropForObject:] and improve
	if (item == nil || [item isGroup])
	{
		return NSDragOperationEvery;
	}
	else
	{
		return NSDragOperationNone;
	}
}

- (BOOL) outlineView: (NSOutlineView *)outlineView writeItems: (NSArray *)items toPasteboard: (NSPasteboard *)pboard
{
#if 0
	// NOTE: On Mac OS X, -currentEvent returns a later event rather than the 
	// mouse down that began the drag when the user moves the mouse too quickly.
	NSEvent *dragEvent = [NSApp currentEvent];
#else
	NSEvent *dragEvent = [self lastDragEvent];
#endif

	NSAssert3([[dragEvent window] isEqual: [outlineView window]], @"NSApp "
		@"current event %@ in %@ -outlineView:writeItems:toPasteboard: doesn't "
		@"belong to the outline view %@", dragEvent, self, outlineView);
	
	NSAssert3([[dragEvent window] isEqual: [outlineView window]], @"NSApp "
		@"current event %@ in %@ -outlineView:writeRowsWithItems:toPasteboard: "
		@"doesn't belong to the outline view %@", dragEvent, self, outlineView);

	/* Convert drag location from window coordinates to the receiver coordinates */
	NSPoint localPoint = [outlineView convertPoint: [dragEvent locationInWindow] fromView: nil];
	id draggedItem = [self itemAtLocation: localPoint];
	id baseItem = [[self layoutContext] baseItem];
	
	NSAssert3([items containsObject: draggedItem], @"Dragged items %@ must "
		@"contain clicked item %@ in %@", items, draggedItem, self);
		
	[baseItem handleDrag: dragEvent forItem: draggedItem layout: self];	
	
	return YES;
}

- (ETLayoutItem *) doubleClickedItem
{
	ETLayoutItem *item = 
		[[self outlineView] itemAtRow: [[self outlineView] clickedRow]];
	
	//ETLog(@"-doubleClickedItem in %@", self);
	
	return item;
}

@end

@interface NSOutlineView (ETTableLayoutDraggingSource)
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)isLocal;
- (void) draggedImage: (NSImage *)anImage beganAt: (NSPoint)aPoint;
- (void) draggedImage: (NSImage *)draggedImage movedTo: (NSPoint)screenPoint;
- (void) draggedImage: (NSImage *)anImage endedAt: (NSPoint)aPoint operation: (NSDragOperation)operation;
@end

@implementation NSOutlineView (ETTableLayoutDraggingSource)

/* The next methods are implemented in NSTableView(ETTableLayoutDraggingSource),
   no need to override them. They are kept here to document the hack below. */

#if 0
- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL)isLocal
{
	return [[self eventHandler] draggingSourceOperationMaskForLocal: isLocal];
}

- (void) draggedImage: (NSImage *)anImage beganAt: (NSPoint)aPoint
{
	[[self eventHandler] draggedImage: anImage beganAt: aPoint];
}
#endif

/* However the following two methods are implemented by NSOutlineView by default
   unlike NSTableView. It means NSTableView(ETTableLayoutDraggingSource)
   implementation is lost and we need to patch NSOutlineView. 
   NOTE: It may break NSOutlineView on Mac OS X but everything seems to work
   well so they could just exist as empty methods in NSOutlineView.The problem
   shouldn't exist on GNUstep
   TODO: We should check it is really the case by setting a break point on these
   methods and steps in the assembly to know whether if they truly do nothing.
   Well, according to my tests, they seems to be in charge of refreshing 
   expanded item on a drop (when child items are inserted).
   In the end, the best solution would be to swizzle the methods, it would avoid
   posing NSOutlineView. */

- (void) draggedImage: (NSImage *)draggedImage movedTo: (NSPoint)screenPoint
{
	[[self eventHandler] draggedImage: draggedImage movedTo: screenPoint];
}

- (void) draggedImage: (NSImage *)anImage endedAt: (NSPoint)aPoint operation: (NSDragOperation)operation
{
	[[self eventHandler] draggedImage: anImage endedAt: aPoint operation: operation];
}

@end;
