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
#import <EtoileUI/ETViewLayoutLine.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/GNUstep.h>

#define ETLog NSLog

@interface ETContainer (PackageVisibility)
- (NSArray *) layoutItemCache;
@end

/* Private Extensions */

// NOTE: This hack is now merely here for the record. Think to remove it later.
@interface NSDictionary (EtoileHorribleHack)
- (id) objectForUncopiedKey: (id)key;
- (void) setObject: (id)object forUncopiedKey: (id)key;
@end

/* Terribly unefficient but well will do the trick right now :-) */
@implementation NSMutableDictionary (EtoileHorribleHack)
- (id) objectForUncopiedKey: (id)key
{
	//NSLog(@"Returning object for hash %d of key %@", [key hash], key);
	return [self objectForKey: [NSNumber numberWithInt: [key hash]]];
}

- (void) setObject: (id)object forUncopiedKey: (id)key
{
	//NSLog(@"Setting object for hash %d of key %@", [key hash], key);
	[self setObject: object forKey: [NSNumber numberWithInt: [key hash]]];
}
@end

/* Private Interface */

@interface ETTableLayout (ETableLayoutDisplayViewGeneration)
- (NSScrollView *) scrollingTableView;
@end

#define DEFAULT_ROW_HEIGHT 16


@implementation ETTableLayout

- (id) init
{
	self = [super init];
    
	if (self != nil)
	{
		BOOL nibLoaded = [NSBundle loadNibNamed: @"TablePrototype" owner: self];
		
		if (nibLoaded == NO)
		{
			NSLog(@"Failed to load nib TablePrototype");
			RELEASE(self);
			return nil;
		}
    }
    
	return self;
}

- (void) dealloc
{
	DESTROY(_allTableColumns);
	
	[super dealloc];
}

- (void) awakeFromNib
{
	NSLog(@"Awaking from nib for %@", self);
	
	/* Because this outlet will be removed from its superview, it must be 
	   retained like any other to-one relationship ivars. 
	   If this proto view is later replaced by calling 
	   -setDisplayViewPrototype:, this retain will be balanced by the release
	   in ASSIGN. */ 
	RETAIN(_displayViewPrototype);

	/* Adjust _displayViewPrototype outlet */
	[self setDisplayViewPrototype: _displayViewPrototype];
}

- (void) setDisplayViewPrototype: (NSView *)protoView
{
	[super setDisplayViewPrototype: protoView];

	NSTableView *tv = [[self displayViewPrototype] documentView];

	[self setAllTableColumns: [tv tableColumns]];	
	[tv registerForDraggedTypes: [NSArray arrayWithObject: @"ETLayoutItemPboardType"]];
	
	if ([tv dataSource] == nil)
		[tv setDataSource: self];
	if ([tv delegate] == nil)
		[tv setDelegate: self];
}

- (NSArray *) allTableColumns
{
	// FIXME: return copy or not? I don't think so.
	return _allTableColumns;
}

- (void) setAllTableColumns: (NSArray *)columns
{
	ASSIGN(_allTableColumns, columns);
}

- (void) renderWithLayoutItems: (NSArray *)items
{
	NSScrollView *scrollView = nil;
	NSTableView *tv = nil;
	
	/* No display view proto available, a table view needs needs to be created 
	   in code */
	if ([self displayViewPrototype] == nil)
	{
		scrollView = [self scrollingTableView];
	}
	else
	{
		NSView *proto = [self displayViewPrototype];
		
		if ([proto isKindOfClass: [NSScrollView class]])
		{
			scrollView = (NSScrollView *)[self displayViewPrototype];
		}
		else
		{
			NSLog(@"WARNING: %@ display view prototype %@ isn't an NSScrollView instance", self, proto);
		}
	}
	
	NSLog(@"%@ scroll view has %@ as document view", self, [scrollView documentView]);
	tv = [scrollView documentView];
	
	if ([scrollView superview] == nil)
	{
		[[self container] setDisplayView: scrollView];
	}
	else if ([[scrollView superview] isEqual: [self container]] == NO)
	{
		NSLog(@"WARNING: Table view of table layout should never have another "
			  @"superview than container parameter or nil.");
	}
	
	[self resizeLayoutItems: items toScaleFactor: [[self container] itemScaleFactor]];
	
	/* Update column visibility */
	if ([[[self container] source] respondsToSelector: @selector(displayedItemPropertiesInContainer:)])
	{
		NSMutableArray *displayedProperties = [[[[self container] source] 
			displayedItemPropertiesInContainer: [self container]] mutableCopy];
		NSEnumerator *e = [[self allTableColumns] objectEnumerator];
		NSTableColumn *column = nil;
		NSString *property = nil;
		
		/* Hide or show already existing columns */
		while ((column = [e nextObject]) != nil)
		{
			if ([displayedProperties containsObject: [column identifier]]
			 && [column tableView] == nil)
			{
				[tv addTableColumn: column];
			}
			else if ([displayedProperties containsObject: [column identifier]] == NO
			      && [[column tableView] isEqual: tv])
			{
				[tv removeTableColumn: column];
			}
			[displayedProperties removeObject: [column identifier]];
		}
		
		/* Automatically create and insert new columns */
		e = [displayedProperties objectEnumerator];
		column = nil;
		
		while ((property = [e nextObject]) != nil)
		{
			NSCell *dataCell = [[NSCell alloc] initTextCell: @""];
			NSTableHeaderCell *headerCell = [[NSTableHeaderCell alloc] initTextCell: property]; // FIXME: Use display name

			column = [[NSTableColumn alloc] initWithIdentifier: property];
			
			[column setHeaderCell: headerCell];
			RELEASE(headerCell);
			[column setDataCell: dataCell];
			RELEASE(dataCell);
			[column setEditable: NO];
			[tv addTableColumn: column];
			RELEASE(column);
		}
	}
		
	[tv reloadData];
}

- (void) resizeLayoutItems: (NSArray *)items toScaleFactor: (float)factor
{
	NSTableView *tv = [(NSScrollView *)_displayViewPrototype documentView];
	// NOTE: Always recompute row height from the original one to avoid really
	// value shifting quickly because of rounding.
	float rowHeight = DEFAULT_ROW_HEIGHT * factor;
	
	/* Enforce a minimal row height to avoid redisplay crashes especially */
	if (rowHeight < 1.0)
		rowHeight = 1.0;
	[tv setRowHeight: rowHeight];
}

- (void) tableViewSelectionDidChange: (NSNotification *)notif
{
	id delegate = [[self container] delegate];
	NSTableView *tv = [[self displayViewPrototype] documentView];
	
	// NOTE: Not really sure that's the best way to do it
	[[self container] setSelectionIndexes: [tv selectedRowIndexes]];

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
	ETLayoutItem *item = [[[self container] layoutItemCache] objectAtIndex: row];
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
	NSArray *layoutItems = [[self container] layoutItemCache];
	
	//NSLog(@"Returns %d as number of items in table view %@", [layoutItems count], tv);
	
	return [layoutItems count];
}

- (id) tableView: (NSTableView *)tv objectValueForTableColumn: (NSTableColumn *)column row: (int)rowIndex
{
	NSArray *layoutItems = [[self container] layoutItemCache];
	ETLayoutItem *item = [layoutItems objectAtIndex: rowIndex];
	
	//NSLog(@"Returns %@ as object value in table view %@", [item valueForProperty: [column identifier]], tv);
	
	return [item valueForProperty: [column identifier]];
}

- (BOOL) tableView: (NSTableView *)tv writeRowsWithIndexes: (NSIndexSet *)rowIndexes 
	toPasteboard: (NSPasteboard*)pboard 
{	
	return [[self container] container: [self container] 
	               writeItemsAtIndexes: rowIndexes 
				          toPasteboard: pboard];
}

- (NSDragOperation) tableView:(NSTableView*)tv 
                 validateDrop: (id <NSDraggingInfo>)info 
				  proposedRow: (int)row 
	    proposedDropOperation: (NSTableViewDropOperation)op 
{
    //ETLog(@"Validate drop with dragging source %@ in %@", [info draggingSource], [self container]);
		
	return [[self container] container: [self container] 
	                      validateDrop: info 
						       atIndex: row];
}

- (BOOL) tableView: (NSTableView *)aTableView 
        acceptDrop: (id <NSDraggingInfo>)info 
               row: (int)row 
	 dropOperation: (NSTableViewDropOperation)operation
{
    //ETLog(@"Accept drop in %@", [self container]);

	return [[self container] container: [self container] 
	                        acceptDrop: info 
							   atIndex: row];
}


- (ETLayoutItem *) clickedItem
{
	NSTableView *tv = [(NSScrollView *)_displayViewPrototype documentView];
	NSArray *layoutItems = [[self container] layoutItemCache];
	ETLayoutItem *item = [layoutItems objectAtIndex: [tv clickedRow]];
	
	return item;
}

@end

/* Private Helper Methods */

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
