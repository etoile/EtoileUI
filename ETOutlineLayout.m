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

@interface ETContainer (PackageVisibility)
- (NSArray *) layoutItemCache;
@end

@implementation ETOutlineLayout

- (id) init
{
	self = [super init];
    
	if (self != nil)
	{
		BOOL nibLoaded = [NSBundle loadNibNamed: @"OutlinePrototype" owner: self];
		
		if (nibLoaded == NO)
		{
			NSLog(@"Failed to load nib OutlinePrototype");
			RELEASE(self);
			return nil;
		}
    }
    
	return self;
}

// NOTE: Dealloc and Awaking from nib handled by ETTableLayout superview.

- (int) outlineView: (NSOutlineView *)outlineView numberOfChildrenOfItem: (id)item
{
	NSArray *childLayoutItems = nil;
	ETContainer *container =  [self container];
	
	if (item == nil)
	{
		childLayoutItems = [container layoutItemCache];
		
		return [childLayoutItems count];
	}
	else if ([item isKindOfClass: [ETLayoutItemGroup class]])
	{
		/* 'item' path and source have been set in -[ETViewLayout layoutItemsFromTreeSource] */
		//childItem = [[itemContainer source] itemAtPath: childItemPath inContainer: [self container]];
		return [[container source] numberOfItemsAtPath: [item path] inContainer: container];
	}
	
	//NSLog(@"Returns %d as number of items in %@", [childLayoutItems count], outlineView);
	
	return 0;
}

- (id) outlineView: (NSOutlineView *)outlineView child: (int)rowIndex ofItem: (id)item
{
	NSArray *childLayoutItems = nil;
	ETContainer *container = [self container];
	ETLayoutItem *childItem = nil; /* Leaf by default */
	
	if (item == nil) /* Root */
	{
		childLayoutItems = [container layoutItemCache];
		childItem = [childLayoutItems objectAtIndex: rowIndex];
	}
	else if ([item isKindOfClass: [ETLayoutItemGroup class]]) /* Node */
	{
		NSString *childPath = nil;

		/* -view must always return a container for ETLayoutItemGroup */
		childPath = [[item path] stringByAppendingPathComponent: 
			[NSString stringWithFormat: @"%d", rowIndex]];
			
		/* 'item' path and source have been set in -[ETViewLayout layoutItemsFromTreeSource] */
		//childItem = [[itemContainer source] itemAtPath: childItemPath inContainer: [self container]];
		childItem = [[container source] itemAtPath: childPath inContainer: container];
		//[[childItem container] setSource: [[self container] source]];
		if ([childItem isKindOfClass: [ETLayoutItemGroup class]])
		{
			[childItem setPath: childPath];
		}
	}

	//NSLog(@"Returns % child item in outline view %@", childItem, outlineView);
	
	return childItem;
}

- (BOOL) outlineView: (NSOutlineView *)outlineView isItemExpandable: (id)item
{
	if ([item isKindOfClass: [ETLayoutItemGroup class]])
	{
		//NSLog(@"Returns item is expandable in outline view %@", outlineView);
		return YES;
	}
	
	return NO;
}

- (id) outlineView: (NSOutlineView *)outlineView 
	objectValueForTableColumn: (NSTableColumn *)column byItem: (id)item
{
	if (item == nil)
	{
		//NSLog(@"WARNING: Get nil item in -outlineView:objectValueForTableColumn:byItem: of %@", self);
		return nil;
	}

	//NSLog(@"Returns %@ as object value in outline view %@", 
	//	[item valueForProperty: [column identifier]], outlineView);
	
	return [item valueForProperty: [column identifier]];
}

- (ETLayoutItem *) clickedItem
{
	NSOutlineView *outlineView = [(NSScrollView *)_displayViewPrototype documentView];
	ETLayoutItem *item = [outlineView itemAtRow: [outlineView clickedRow]];
	
	NSLog(@"-clickedItem in %@", self);
	
	return item;
}

@end
