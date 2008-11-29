/*  <title>ETContainer+Controller</title>

	ETContainer+Controller.m
	
	<abstract>A generic controller layer interfaced with the layout item tree.</abstract>
 
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


#import <EtoileUI/ETContainer+Controller.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETCompatibility.h>


@implementation ETContainer (Controller)

- (id) content
{
	return self;
}

/** Returns the template item used to create leaf items. This template item
	is used as a prototype to make new layout items by 
	-[ETLayoutItemGroup newItem].
	This method returns nil by default and -[ETLayoutItemGroup newItem] will 
	simply create a new ETLayoutItem instance in such case. */
- (ETLayoutItem *) templateItem
{
	return _templateItem;
}

/** Returns the template item used to create branch items. This template item
	is used as a prototype to make new layout item groups by 
	-[ETLayoutItemGroup newItemGroup].
	This method returns nil by default and -[ETLayoutItemGroup newItemGroup] 
	will simply create a new ETLayoutItemGroup instance in such case. */
- (ETLayoutItemGroup *) templateItemGroup
{
	return _templateItemGroup;
}

/** Sets the template item used to create leaf items. This template item
	is used as a prototype to make new layout items by 
	-[ETLayoutItemGroup newItem].
	You can pass an instance of any ETLayoutItem class or subclass. */
- (void) setTemplateItem: (ETLayoutItem *)template
{
	ASSIGN(_templateItem, template);
}

/** Sets the template item used to create branch items. This template item
	is used as a prototype to make new layout item groups by 
	-[ETLayoutItemGroup newItemGroup].
	You can pass an instance of any ETLayoutItemGroup class or subclass. */
- (void) setTemplateItemGroup: (ETLayoutItemGroup *)template
{
	ASSIGN(_templateItemGroup, template);
}

/** Returns the class used to create model objects for leaf items. */
- (Class) objectClass
{
	return _objectClass;
}

/** Sets the class used to create model objects for leaf items.
	See also -newObject. */
- (void) setObjectClass: (Class)modelClass
{
	ASSIGN(_objectClass, modelClass);
}

/** Returns the group class used to create model objects for branch items.*/
- (Class) groupClass
{
	return _groupClass;
}
/** Sets the class used to create model objects for branch items.
	See also -newGroup. */
- (void) setGroupClass: (Class)modelClass
{
	ASSIGN(_groupClass, modelClass);
}

/** Creates and returns a new object that can be either a layout item clone of 
	-templateItem or a fresh instance of -objectClass. 
	If both a template item and an object class are set, the returned object 
	is a layout item with a new instance of -objectClass set as its 
	represented object. 
	This method is used by -add: and -insert: actions to generate the object 
	to be inserted into the content of the controller. 
	Take note that the autoboxing feature of -[ETLayoutItemGroup addObject:] 
	will take care of wrapping the created object into a layout item if needed. */
- (id) newObject
{
	id object = nil;

	if ([self templateItem] != nil)
	{
		object = [[self layoutItem] newItem]; /* Calls -templateItem */
	}

	if ([self objectClass] != nil)
	{
		id modelObject = AUTORELEASE([[[self objectClass] alloc] init]);

		if (object != nil)
		{
			[object setRepresentedObject: modelObject];
		}
		else
		{
			object = modelObject;
		}
	}

	return object;
}

/** Creates and returns a new object group that can be either a layout item 
	group clone of -templateItemGroup or a fresh instance of -groupClass. 
	If both a template item group and an group class are set, the returned 
	object is a layout item group with a new instance of -groupClass set as its 
	represented object. 
	This method is used by -addGroup: and -insertGroup: actions to generate the 
	object to be inserted into the content of the controller. 
	Take note that the autoboxing feature of -[ETLayoutItemGroup addObject:] 
	will take care of wrapping the created object into a layout item if needed. */
- (id) newGroup
{
	id object = nil;

	if ([self templateItemGroup] != nil)
	{
		object = [[self layoutItem] newItemGroup]; /* Calls -templateItemGroup */
	}

	if ([self groupClass] != nil)
	{
		id modelObject = AUTORELEASE([[[self groupClass] alloc] init]);

		if (object != nil)
		{
			[object setRepresentedObject: modelObject];
		}
		else
		{
			object = modelObject;
		}
	}

	return object;
}

/** Creates a new object by calling -newObject and adds it to the content. */
- (void) add: (id)sender
{
	[[self content] addObject: [self newObject]];
}

/** Creates a new object group by calling -newGroup and adds it to the content. */
- (BOOL) addGroup: (id)sender
{
	[[self content] addObject: [self newGroup]];
	return YES;
}

/** Creates a new object by calling -newGroup and inserts it to the content at 
	-insertionIndex. */
- (void) insert: (id)sender
{
	[[self content] insertObject: [self newObject] 
	                     atIndex: [self insertionIndex]];
}

/** Creates a new object group by calling -newGroup and inserts it to the 
	content at -insertionIndex. */
- (void) insertGroup: (id)sender
{
	[[self content] insertObject: [self newGroup] 
	                     atIndex: [self insertionIndex]];
}

/** Removes all selected objects in the content. Selected objects are retrieved 
	by calling -selectedItemsInLayout on the content. */
- (void) remove: (id)sender
{
	NSArray *selectedItems = [[self content] selectedItemsInLayout];

	//ETLog(@"Will remove selected items %@", selectedItems);
	/* Removed items are temporarily retained by the array returned by 
	   -selectedItemsInLayout, therefore we can be sure we won't trigger the 
	   release of an already deallocated item. The typical case would be 
	   removing an item from a parent that was also selected and already got 
	   removed from the layout item tree. */
	[selectedItems makeObjectsPerformSelector: @selector(removeFromParent)];
}

/** Returns the position in the content, at which -insert: and -insertGroup: 
	will insert the object they create. The returned value is the last 
	selection index in the content. */
- (unsigned int) insertionIndex
{
	unsigned int index = [[[self content] selectionIndexes] lastIndex];

	/* No selection or no items */
	if (index == NSNotFound)
		index = [[self content] numberOfItems];

	return index;
}

/* Not really needed */
// - (void) commitEditing
// {
// 	[[self content] reloadAndUpdateLayout];
// }

@end
