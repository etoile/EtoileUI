/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"

#ifdef COREOBJECT

#import <CoreObject/COEditingContext.h>
#import <CoreObject/COObject.h>
#import "ETLayoutItem+CoreObject.h"
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

- (void) becomePersistentInContext: (COPersistentRoot *)aContext
{
	if ([self isPersistent])
		return;

	[super becomePersistentInContext: aContext];

	// TODO: Leverage the model description rather than hardcoding the aspects
	// TODO: Implement some strategy to recover in the case these aspects 
	// are already used as embedded objects in another root object. 
	ETAssert([[self coverStyle] isShared] || [[self coverStyle] isPersistent] == NO || [[self coverStyle] isRoot]);
	[[self coverStyle] becomePersistentInContext: aContext];
	ETAssert([[self styleGroup] isPersistent] == NO || [[self styleGroup] isRoot]);
	[[self styleGroup] becomePersistentInContext: aContext];
	ETAssert([[self actionHandler] isShared] || [[self actionHandler] isPersistent] == NO || [[self actionHandler] isRoot]);
	[[self actionHandler] becomePersistentInContext: aContext];
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

- (NSString *) serializedViewTargetId
{
	return [self targetIdForTarget: [[[self view] ifResponds] target]];
}

- (void) setSerializedViewTargetId: (NSString *)anId
{
	if (anId == nil)
		return;

	/* The target might not be deserialized at this point, hence we look up the 
	   target in -awakeFromFetch once the entire object graph has been deserialized */
	[_variableStorage setObject: anId forKey: @"viewTargetId"];
}

- (void) restoreTargetFromId: (NSString *)targetId on: (id)sender
{
	/* sender must repond to -setTarget:, see ETWidget protocol */
	if ([targetId isString] == NO || [sender isWidget] == NO)
		return;

	BOOL isViewTarget = [targetId hasPrefix: @"_"];

	if (isViewTarget)
	{
		ETUUID *uuid = [ETUUID UUIDWithString: [targetId substringFromIndex: 1]];
		ETLayoutItem *targetItem = (ETLayoutItem *)[[self persistentRoot] objectWithUUID: uuid];

		[sender setTarget: [targetItem view]];
	}
	else
	{
		ETUUID *uuid = [ETUUID UUIDWithString: targetId];
		ETLayoutItem *targetItem = (ETLayoutItem *)[[self persistentRoot] objectWithUUID: uuid];

		[sender setTarget: targetItem];
	}
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

	/* Restore target and action on both the receiver item and its view */

	NSString *targetId = [_variableStorage objectForKey: @"targetId"];
	NSString *viewTargetId = [_variableStorage objectForKey: @"viewTargetId"];

	[self restoreTargetFromId: targetId on: self];
	[self restoreTargetFromId: viewTargetId on: [self view]];

	[_variableStorage removeObjectForKey: @"targetId"];
	[_variableStorage removeObjectForKey: @"viewTargetId"];
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

- (void) becomePersistentInContext: (COPersistentRoot *)aContext
{
	if ([self isPersistent])
		return;

	[super becomePersistentInContext: aContext];

	// TODO: Leverage the model description rather than hardcoding the aspects
	// TODO: Implement some strategy to recover in the case these items or aspects
	// are already used as embedded objects in another root object.
	for (ETLayoutItem *item in _layoutItems)
	{
		ETAssert([item isPersistent] == NO || [item isRoot]);
		[item becomePersistentInContext: aContext];
	}
	ETAssert([[self controller] isPersistent] == NO || [[self controller] isRoot]);
	[[self controller] becomePersistentInContext: aContext];
	// TODO: Move layout to ETLayoutItem once well supported
	ETAssert([[self layout] isPersistent] == NO || [[self layout] isRoot]);
	[[self layout] becomePersistentInContext: aContext];
}

- (void) setSerializedItems: (NSArray *)items
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
	return [ctxt insertObjectWithEntityName: @"ETCompoundDocument"];
}

@end

#endif
