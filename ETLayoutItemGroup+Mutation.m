/*  <title>ETLayoutItemGroup+Mutation</title>

	ETLayoutItemGroup+Mutation.m
	
	<abstract>Description forthcoming.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
 
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
 
#import <EtoileUI/ETLayoutItemGroup+Mutation.h>
#import <EtoileUI/ETEvent.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/NSObject+Model.h>
#import <EtoileUI/ETCollection.h>
#import <EtoileUI/ETCompatibility.h>

@interface ETLayoutItemGroup (ETSource)
- (BOOL) isReloading;
@end


@implementation ETLayoutItemGroup (ETMutationHandler)

/* Returns whether children have been removed, added or inserted since the last 
   UI layout. Typically returns YES when the receiver has been reloaded but the 
   layout hasn't yet been updated. Also returns YES when autolayout is disabled 
   and the UI needs to be refreshed by calling -updateLayout. */
- (BOOL) hasNewContent
{
	return _hasNewContent;
}

/* Sets whether children have been removed, added or inserted since the last UI
   layout. -reload calls this method to indicate the receiver layout needs to be
   updated in order that the UI reflects the latest receiver content. */
- (void) setHasNewContent: (BOOL)flag
{
	_hasNewContent = flag;
}

/* Element Mutation Handler */

- (void) handleAdd: (ETEvent *)event item: (ETLayoutItem *)item
{
	//ETLog(@"Add item in %@", self);
	
	if ([_layoutItems containsObject: item])
	{
		ETLog(@"WARNING: Trying to add item %@ to the item group %@ it "
			@"already belongs to", item, self);
		return;
	}
	
	BOOL validatedAdd = YES;

	/* Don't touch the model when it is turned into layout items in the reload 
	   phase. We must be sure we won't trigger model updates that would result 
	   in a new UI update/reload when it's already underway. */
	if ([self isReloading] == NO)
		validatedAdd = [self handleModelAdd: nil item: item];
	
	if (validatedAdd)
	{
		[self handleAttachItem: item];
		[_layoutItems addObject: item];
		[self setHasNewContent: YES];
		if ([self canUpdateLayout])
			[self updateLayout];
	}
}

- (BOOL) handleModelAdd: (ETEvent *)event item: (ETLayoutItem *)item;
{
	id repObject = [self representedObject];
	// FIXME: Implement
	//BOOL isValidElementType = NO;
	BOOL validatedMutate = YES;
		
	if ([PROVIDER_SOURCE respondsToSelector: @selector(container:addItems:atPath:operation:)])
	{
		NSArray *items = [NSArray arrayWithObject: item];

		validatedMutate = [PROVIDER_SOURCE container: PROVIDER_CONTAINER 
			addItems: items atPath: [self indexPath] operation: event];
	}
	else if ([PROVIDER_SOURCE respondsToSelector: @selector(container:insertItems:atPaths:operation:)])
	{
		NSArray *items = [NSArray arrayWithObject: item];
		NSIndexPath *indexPath = [[self indexPath] indexPathByAddingIndex: [self count]];
		NSArray *indexPaths = [NSArray arrayWithObject: indexPath];
				
		validatedMutate = [PROVIDER_SOURCE container: PROVIDER_CONTAINER 
			insertItems: items atPaths: indexPaths operation: event];
	}
	if (validatedMutate && [[self baseItem] shouldMutateRepresentedObject] 
	 && [repObject isMutableCollection])
	{
		ETLog(@"Add %@ in represented object %@", [item representedObject], 
			repObject);
		[repObject addObject: [item representedObject]];
	}
	
	return validatedMutate;
}

- (void) handleInsert: (ETEvent *)event item: (ETLayoutItem *)item atIndex: (int)index
{
	if ([_layoutItems containsObject: item])
	{
		ETLog(@"WARNING: Trying to insert item %@ in the item group %@ it "
			@"already belongs to", item, self);
		return;
	}
	
	BOOL validatedInsert = YES;
	
	if ([self isReloading] == NO)
		validatedInsert = [self handleModelInsert: nil item: item atIndex: index];
	
	if (validatedInsert)
	{
		[self handleAttachItem: item];
		[_layoutItems insertObject: item atIndex: index];
		[self setHasNewContent: YES];
		if ([self canUpdateLayout])
			[self updateLayout];
	}

// NOTE: The code below is kept as an example to implement selection caching 
// at later time if better performance are necessary.
#if 0	
	NSMutableIndexSet *indexes = [self selectionIndexes];
	
	/* In this example, 1 means selected and 0 unselected.
       () represents old item index shifted by insertion
	   
       Item index      0   1   2   3   4
       Item selected   0   1   0   1   0
   
       When you call shiftIndexesStartingAtIndex: 2 by: 1, you get:
       Item index      0   1   2   3   4
       Item selected   0   1   0   0   1  0
       Now by inserting an item at 2:
       Item index      0   1   2  (2) (3) (4)
       Item selected   0   1   0   0   1   0
		   
       That's precisely the selections state we expect once item at index 2
       has been removed. */
	
	[item setParentLayoutItem: nil];
	[_layoutItems insertObject: item atIndex: index];
	[indexes shiftIndexesStartingAtIndex: index by: 1];
	[self setSelectionIndexes: indexes];
#endif
}

- (BOOL) handleModelInsert: (ETEvent *)event item: (ETLayoutItem *)item atIndex: (int)index
{
	id repObject = [self representedObject];
	// FIXME: Implement
	//BOOL isValidElementType = NO;
	BOOL validatedMutate = YES;
		
	if ([PROVIDER_SOURCE respondsToSelector: @selector(container:insertItems:atPaths:operation:)])
	{
		NSArray *items = [NSArray arrayWithObject: item];
		NSIndexPath *indexPath = [[self indexPath] indexPathByAddingIndex: index];
		NSArray *indexPaths = [NSArray arrayWithObject: indexPath];

		validatedMutate = [PROVIDER_SOURCE container: PROVIDER_CONTAINER 
			insertItems: items atPaths: indexPaths operation: event];
	}
	if (validatedMutate && [[self baseItem] shouldMutateRepresentedObject] 
	 && [repObject isMutableCollection])
	{
		ETLog(@"Insert %@ in represented object %@ at index %d", 
			[item representedObject], repObject, index);
		[repObject insertObject: [item representedObject] atIndex: index];
	}
	
	return validatedMutate;
}

- (void) handleRemove: (ETEvent *)event item: (ETLayoutItem *)item
{
	BOOL validatedRemove = YES;

	/* Take note that -reload calls -removeAllItems. 
	   See -handleAdd:item: to know more. */	
	if ([self isReloading] == NO)
		validatedRemove = [self handleModelRemove: nil item: item];
	
	if (validatedRemove)
	{
		[self handleDetachItem: item];
		[_layoutItems removeObject: item];
		[self setHasNewContent: YES];
		if ([self canUpdateLayout])
			[self updateLayout];
	}
		
// NOTE: The code below is kept as an example to implement selection caching 
// at later time if better performance are necessary.
#if 0	
	NSMutableIndexSet *indexes = [self selectionIndexes];
	int removedIndex = [self indexOfItem: item];
	
	if ([indexes containsIndex: removedIndex])
	{
		/* In this example, 1 means selected and 0 unselected.
		
		   Item index      0   1   2   3   4
		   Item selected   0   1   0   1   0
		   
		   When you call shiftIndexesStartingAtIndex: 3 by: -1, you get:
		   Item index      0   1   2   3   4
		   Item selected   0   1   1   0   0
		   Now by removing item 2:
		   Item index      0   1   3   4
		   Item selected   0   1   1   0   0
		   		   
		   That's precisely the selections state we expect once item at index 2
		   has been removed. */
		[indexes shiftIndexesStartingAtIndex: removedIndex + 1 by: -1];
		
		/* Verify basic shitfing errors before really updating the selection */
		if ([[self selectionIndexes] containsIndex: removedIndex + 1])
		{
			NSAssert([indexes containsIndex: removedIndex], 
				@"Item at the index of the removal must remain selected because it was previously");
		}
		if ([[self selectionIndexes] containsIndex: removedIndex - 1])
		{
			NSAssert([indexes containsIndex: removedIndex - 1], 
				@"Item before the index of the removal must remain selected because it was previously");
		}
		if ([[self selectionIndexes] containsIndex: removedIndex + 1] == NO)
		{
			NSAssert([indexes containsIndex: removedIndex] == NO, 
				@"Item at the index of the removal must not be selected because it wasn't previously");
		}
		if ([[self selectionIndexes] containsIndex: removedIndex - 1] == NO)
		{
			NSAssert([indexes containsIndex: removedIndex - 1] == NO, 
				@"Item before the index of the removal must not be selected because it wasn't previously");
		}
		[self setSelectionIndexes: indexes];
	}
#endif

}

- (BOOL) handleModelRemove: (ETEvent *)event item: (ETLayoutItem *)item
{
	id repObject = [self representedObject];
	 // FIXME: Implement
	//BOOL isValidElementType = NO;
	BOOL validatedMutate = YES;
		
	if ([PROVIDER_SOURCE respondsToSelector: @selector(container:removeItemsAtPaths:operation:)])
	{
		NSArray *indexPaths = [NSArray arrayWithObject: [item indexPath]];

		validatedMutate = [PROVIDER_SOURCE container: PROVIDER_CONTAINER 
			removeItemsAtPaths: indexPaths operation: event];
	}
	if (validatedMutate && [[self baseItem] shouldMutateRepresentedObject] 
	 && [repObject isMutableCollection])
	{
		ETLog(@"Remove %@ in represented object %@", [item representedObject], 
			repObject);
		[repObject removeObject: [item representedObject]];
	}
	
	return validatedMutate;
}

/* Set Mutation Handlers */

- (void) handleAdd: (ETEvent *)event items: (NSArray *)items
{
	NSEnumerator *e = [items objectEnumerator];
	ETLayoutItem *item = nil;
	
	while ((item = [e nextObject]) != nil)
	{
		[self handleAdd: event item: item];
	}
}

- (void) handleRemove: (ETEvent *)event items: (NSArray *)items
{
	NSEnumerator *e = [items objectEnumerator];
	ETLayoutItem *item = nil;
	
	while ((item = [e nextObject]) != nil)
	{
		[self handleRemove: event item: item];
	}
}

/* Collection Protocol Backend */

- (void) handleAdd: (ETEvent *)event object: (id)object
{
	id item = [object isLayoutItem] ? object : [self itemWithObject: object isValue: [object isCommonObjectValue]];
	
	if ([object isLayoutItem] == NO)
		ETLog(@"Boxed object %@ in item %@ to be added to %@", object, item, self);

	[self handleAdd: event item: item];
}

- (void) handleInsert: (ETEvent *)event object: (id)object
{

}

- (void) handleRemove: (ETEvent *)event object: (id)object
{
	/* Try to remove object by matching it against child items */
	if ([object isLayoutItem] && [self containsItem: object])
	{
		[self handleRemove: event item: object];
	}
	else
	{
		/* Remove items with boxed object matching the object to remove */	
		NSArray *itemsMatchedByRepObject = nil;
		
		itemsMatchedByRepObject = [[self items] 
			objectsMatchingValue: object forKey: @"representedObject"];
		[self handleRemove: event items: itemsMatchedByRepObject];
		
		itemsMatchedByRepObject = [[self items] 
			objectsMatchingValue: object forKey: @"value"];
		[self handleRemove: event items: itemsMatchedByRepObject];
	}
}

/* Providing */

/* Makes the represented object returns layout items as a source would but only
   turning immediate children into ETLayoutItem or ETLayoutItemGroup instances. 
   An empty array of items is returned when the represented object isn't a 
   collection. This method is only invoked if thereceivertem bound to the 
   represented object is an item group. */
- (NSArray *) itemsFromRepresentedObject
{
	NSMutableArray *childItems = nil;
	id repObject = [self representedObject];
	
	if ([repObject isCollection])
	{
		// TODO: Replace existing code once ETCollection is implemented everywhere
		//id repObject = [self representedObject];
		//NSEnumerator *e = [repObject objectEnumerator];
		//NSMutableArray = [NSMutableArray arrayWithCapacity: [repObject count]];
		NSArray *contentObjects = [repObject contentArray];
		NSEnumerator *e = [contentObjects objectEnumerator];
		id childRepObject = nil;
		
		childItems = [NSMutableArray arrayWithCapacity: [contentObjects count]];
		
		while ((childRepObject = [e nextObject]) != nil)
		{
			[childItems addObject: [self itemWithObject: childRepObject isValue: NO]];
			//[self handleAdd: nil item: [self itemWithObject: childRepObject isValue: NO]];
		}
	}
	else
	{
		childItems = [NSArray array];
	}
	
	return childItems;
}

@end
