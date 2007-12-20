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
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETViewLayoutLine.h>
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

	ETLog(@"Returns %@ as object value in outline view %@", value, outlineView);
	
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

- (ETLayoutItem *) doubleClickedItem
{
	ETLayoutItem *item = 
		[[self outlineView] itemAtRow: [[self outlineView] clickedRow]];
	
	//ETLog(@"-doubleClickedItem in %@", self);
	
	return item;
}

@end
