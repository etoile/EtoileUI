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
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETViewLayoutLine.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/GNUstep.h>

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
	return (NSOutlineView *)[self tableView];
}

// NOTE: Dealloc and Awaking from nib handled by ETTableLayout superview.

/* Update column visibility */
- (void) setDisplayedProperties: (NSArray *)properties
{
	NSMutableArray *displayedProperties = [properties mutableCopy];
	NSTableView *tv = [self tableView];
	NSEnumerator *e = [[self allTableColumns] objectEnumerator];
	NSTableColumn *column = nil;
	NSString *property = nil;
	
	NSTableColumn *outlineColumn = [[self tableView] outlineTableColumn];
		
	[outlineColumn setIdentifier: [displayedProperties objectAtIndex: 0]];
	[displayedProperties removeObjectAtIndex: 0];
	
	/* Hide or show already existing columns */
	while ((column = [e nextObject]) != nil)
	{
		if ([column isEqual: [[self tableView] outlineTableColumn]])
			continue;
	
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
	ETContainer *container =  [self container];
	int nbOfItems = 0;
	
	if (item == nil)
	{
		nbOfItems = [[container items] count];
	}
	else if ([item isKindOfClass: [ETLayoutItemGroup class]]) 
	{
		nbOfItems = [[item items] count];
		
		/* First time */
		if (nbOfItems == 0)
		{
			[(ETLayoutItemGroup *)item reload];
			nbOfItems = [[item items] count];
		}
	}
	
	//ETLog(@"Returns %d as number of items in %@", nbOfItems, outlineView);
	
	return nbOfItems;
}

- (id) outlineView: (NSOutlineView *)outlineView child: (int)rowIndex ofItem: (id)item
{
	ETContainer *container = [self container];
	ETLayoutItem *childItem = nil; /* Leaf by default */
	
	if (item == nil) /* Root */
	{
		childItem = [[container items] objectAtIndex: rowIndex];
	}
	else if ([item isKindOfClass: [ETLayoutItemGroup class]]) /* Node */
	{
		childItem = [(ETLayoutItemGroup *)item itemAtIndex: rowIndex];
	}

	//ETLog(@"Returns % child item in outline view %@", childItem, outlineView);
	
	return childItem;
}

- (BOOL) outlineView: (NSOutlineView *)outlineView isItemExpandable: (id)item
{
	if ([item isKindOfClass: [ETLayoutItemGroup class]])
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

	//ETLog(@"Returns %@ as object value in outline view %@", 
	//	[item valueForProperty: [column identifier]], outlineView);
	
	return [item valueForProperty: [column identifier]];
}

- (ETLayoutItem *) doubleClickedItem
{
	ETLayoutItem *item = 
		[[self outlineView] itemAtRow: [[self outlineView] clickedRow]];
	
	//ETLog(@"-doubleClickedItem in %@", self);
	
	return item;
}

@end
