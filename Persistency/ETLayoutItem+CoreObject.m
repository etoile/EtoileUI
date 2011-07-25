/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"

#ifdef OBJECTMERGING

#import <ObjectMerging/COEditingContext.h>
#import <ObjectMerging/COObject.h>
#import "ETLayoutItem+CoreObject.h"


@implementation ETLayoutItem (CoreObject) 

- (ETLayoutItemGroup *) compoundDocument
{
	if ([self isGroup] && [(ETLayoutItemGroup *)self isCompoundDocument])
	{
		return (ETLayoutItemGroup *)self;
	}
	else if (_parentItem != nil)
	{
		return [_parentItem parentItem];	
	}
	else
	{
		return nil;
	}
}

- (void) becomePersistentInContext: (COEditingContext *)aContext rootObject: (COObject *)aRootObject
{
	if ([self isPersistent])
		return;

	[super becomePersistentInContext: aContext rootObject: aRootObject];

	// TODO: Leverage the model description rather than hardcoding the aspects
	// TODO: Implement some strategy to recover in the case these aspects 
	// are already used as embedded objects in another root object. 
	ETAssert([[self coverStyle] isShared] || [[self coverStyle] isPersistent] == NO || [[self coverStyle] isRoot]);
	[[self coverStyle] becomePersistentInContext: aContext rootObject: aRootObject];
	ETAssert([[self styleGroup] isPersistent] == NO || [[self styleGroup] isRoot]);
	[[self styleGroup] becomePersistentInContext: aContext rootObject: aRootObject];
	ETAssert([[self actionHandler] isShared] || [[self actionHandler] isPersistent] == NO || [[self actionHandler] isRoot]);
	[[self actionHandler] becomePersistentInContext: aContext rootObject: aRootObject];
}

- (void) awakeFromFetch
{
	// TODO: May be reset the bounding box if not persisted
	//_boundingBox = ETNullRect;
}

@end

@implementation ETLayoutItemGroup (CoreObject)

- (BOOL) isCompoundDocument
{
	// TODO: We probably should have -isRootObject check -isPersistent
	return ([self isRoot]);
}

- (NSSet *) descendantCompoundDocuments
{
	// TODO: This code is probably quite slow
	NSMutableSet *collectedItems = [NSMutableSet set];

	FOREACHI([self items], item)
	{
		[collectedItems addObject: item];

		if ([item isCompoundDocument])
		{
			[collectedItems addObject: item];
		}
		else
		{
			[collectedItems unionSet: [item descendantCompoundDocuments]];
		}
	}

	return collectedItems;
}

- (void) becomePersistentInContext: (COEditingContext *)aContext rootObject: (COObject *)aRootObject
{
	if ([self isPersistent])
		return;

	[super becomePersistentInContext: aContext rootObject: aRootObject];

	// TODO: Leverage the model description rather than hardcoding the aspects
	// TODO: Implement some strategy to recover in the case these items or aspects
	// are already used as embedded objects in another root object.
	for (ETLayoutItem *item in _layoutItems)
	{
		ETAssert([item isPersistent] == NO || [item isRoot]);
		[item becomePersistentInContext: aContext rootObject: aRootObject];
	}
	ETAssert([[self controller] isPersistent] == NO || [[self controller] isRoot]);
	[[self controller] becomePersistentInContext: aContext rootObject: aRootObject];
	// TODO: Move layout to ETLayoutItem once well supported
	ETAssert([[self layout] isPersistent] == NO || [[self layout] isRoot]);
	[[self layout] becomePersistentInContext: aContext rootObject: aRootObject];
}

- (void) setItems: (NSArray *)items
{
	DESTROY(_layoutItems);
	_layoutItems = [items mutableCopy];
}

@end

@implementation ETLayoutItemFactory (CoreObject)

- (ETLayoutItemGroup *) compoundDocument
{
	return [self compoundDocumentWithEditingContext: nil];
}

- (ETLayoutItemGroup *) compoundDocumentWithEditingContext: (COEditingContext *)aCtxt
{
	COEditingContext *ctxt = (aCtxt != nil ? aCtxt : [COEditingContext currentContext]);
	return [ctxt insertObjectWithClass: [ETLayoutItemGroup class]];
}

@end

#endif
