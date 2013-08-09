/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"

#ifdef COREOBJECT

#import <CoreObject/COEditingContext.h>
#import <CoreObject/COPersistentRoot.h>
#import <CoreObject/COObject.h>
#import <CoreObject/CODictionary.h>
#import "ETLayoutItem+CoreObject.h"
#import "EtoileUIProperties.h"
#import "ETOutlineLayout.h"
#import "ETView.h"
#import "NSObject+EtoileUI.h"
#import "NSView+Etoile.h"


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

#pragma mark UI Persistency
#pragma mark -

- (NSString *) persistentUIName
{
	return [self primitiveValueForKey: @"persistentUIName"];
}

- (void) setPersistentUIName: (NSString *)aName
{
	[self setPrimitiveValue: aName forKey: @"persistentUIName"];
}

- (ETLayoutItem *) persistentUIItem
{
	if ([self persistentUIName] != nil)
	{
		return self;
	}
	else
	{
		return [_parentItem parentItem];
	}
}

- (BOOL) isEditingUI
{
	return _isEditingUI;
}

- (void) setEditingUI: (BOOL)editing
{
	_isEditingUI = editing;
}

#pragma mark Persistency Support
#pragma mark -

- (NSValue *) serializedPosition
{
	id value = nil;
	
	if ([self isRoot])
	{
		value = [self primitiveValueForKey: @"initialPosition"];
	}
	
	return (value == nil ? [self valueForKey: kETPositionProperty] : value);
}

- (void) setSerializedPosition: (NSValue *)aValue
{
	if ([self isRoot])
	{
		[self setPrimitiveValue: aValue forKey: @"initialPosition"];
	}
	[self setPosition: [aValue pointValue]];
}

- (NSValue *) serializedContentBounds
{
	id value = nil;

	if ([self isRoot])
	{
		value = [self primitiveValueForKey: @"initialContentBounds"];
	}

	return (value == nil ? [self valueForKey: kETContentBoundsProperty] : value);
}

- (void) setSerializedContentBounds: (NSValue *)aValue
{
	if ([self isRoot])
	{
		[self setPrimitiveValue: aValue forKey: @"initialContentBounds"];
	}
	[self setContentBounds: [aValue rectValue]];
}

- (NSString *) targetIdForTarget: (id)target
{
	if ([target isLayoutItem])
	{
		return [[target UUID] stringValue];
	}
	else if ([target isView])
	{
		return [@"_" stringByAppendingString: [[[target owningItem] UUID] stringValue]];
	}
	return nil;
}

- (NSString *) serializedTargetId
{
	return [self targetIdForTarget: [self target]];
}

- (void) setSerializedTargetId: (NSString *)anId
{
	if (anId == nil)
		return;

	/* The target might not be deserialized at this point, hence we look up the 
	   target in -awakeFromFetch once the entire object graph has been deserialized */
	[_variableStorage setObject: anId forKey: @"targetId"];
}

- (void) restoreTargetFromId: (NSString *)targetId
{
	if ([targetId isString] == NO)
		return;

	BOOL isViewTarget = [targetId hasPrefix: @"_"];

	if (isViewTarget)
	{
		ETUUID *uuid = [ETUUID UUIDWithString: [targetId substringFromIndex: 1]];
		ETLayoutItem *targetItem = (ETLayoutItem *)[[self persistentRoot] objectWithUUID: uuid];

		[self setTarget: [targetItem view]];
	}
	else
	{
		ETUUID *uuid = [ETUUID UUIDWithString: targetId];
		ETLayoutItem *targetItem = (ETLayoutItem *)[[self persistentRoot] objectWithUUID: uuid];

		[self setTarget: targetItem];
	}
}

- (NSView *) serializedView
{
	return [self view];
}

- (void) setSerializedView: (NSView *)newView
{
	if (newView == nil)
		return;

	NSParameterAssert([newView superview] == nil);
	/* The item geometry might not be deserialized at this point, hence we set 
	   the view in -awakeFromFetch once the entire object graph has been deserialized */
	[_variableStorage setObject: newView forKey: @"serializedView"];
}

/* Required otherwise the bounds returned by -boundingBox might be serialized 
since -serializedValueForProperty: doesn't use the direct ivar access. */
- (id) serializedBoundingBox
{
	return [NSValue valueWithRect: _boundingBox];
}

/* Required to set up the KVO observation. */
- (void) setSerializedRepresentedObject: (id)aRepObject
{
	[self setRepresentedObject: aRepObject];
}

- (void) awakeFromFetch
{
	// TODO: May be reset the bounding box if not persisted
	//_boundingBox = ETNullRect;
	
	/* We use -setView: to recreate supervisorView which is transient and set
	   up the state and object value observers.
	 
	   Will involve a unnecessary -syncView:withRepresentedObject: call. */
	NSView *serializedView = [_variableStorage objectForKey: @"serializedView"];

	if (serializedView != nil)
	{
		[self setView: serializedView];
	}
	[_variableStorage removeObjectForKey: @"serializedView"];

	/* Restore target and action on the receiver item or its view */

	[self restoreTargetFromId: [_variableStorage objectForKey: @"targetId"]];
	[_variableStorage removeObjectForKey: @"targetId"];
}

- (void)didReload
{
	[[self layout] didReload];
	[self setNeedsDisplay: YES];
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

- (void) setSerializedItems: (NSArray *)items
{
	DESTROY(_items);
	_items = [items mutableCopy];
	for (ETLayoutItem *item in items)
	{
		item->_parentItem = self;
	}
}

@end

// TODO: Remove or update
@implementation ETLayoutItemFactory (CoreObject)

- (ETLayoutItemGroup *) compoundDocument
{
	return [self compoundDocumentWithEditingContext: nil];
}

- (ETLayoutItemGroup *) compoundDocumentWithEditingContext: (COEditingContext *)aCtxt
{
	COEditingContext *ctxt = (aCtxt != nil ? aCtxt : [COEditingContext currentContext]);
	return [[ctxt insertNewPersistentRootWithEntityName: @"ETCompoundDocument"] rootObject];
}

@end

#endif
