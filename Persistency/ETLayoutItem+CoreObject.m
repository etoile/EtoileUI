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
#import "ETLayoutItem+CoreObject.h"
#import "ETCollectionToPersistentCollection.h"
#import "EtoileUIProperties.h"
#import "ETOutlineLayout.h"
#import "ETUIItemIntegration.h"
#import "ETView.h"
#import "NSObject+EtoileUI.h"
#import "NSView+EtoileUI.h"


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
	return [self valueForVariableStorageKey: @"persistentUIName"];
}

- (void) setPersistentUIName: (NSString *)aName
{
	[self setValue: aName forVariableStorageKey: @"persistentUIName"];
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

- (NSData *) serializedIcon
{
	NSImage *icon = [self valueForVariableStorageKey: kETIconProperty];
	return (icon != nil ? [NSKeyedArchiver archivedDataWithRootObject: icon] : nil);
}

- (void) setSerializedIcon: (NSData *)anIconData
{
	NSImage *icon = (anIconData != nil ? [NSKeyedUnarchiver unarchiveObjectWithData: anIconData] : nil);
	[self setValue: icon forVariableStorageKey: kETIconProperty];
}

- (NSData *) serializedImage
{
	NSImage *img = [self valueForVariableStorageKey: kETImageProperty];
	return (img != nil ? [NSKeyedArchiver archivedDataWithRootObject: img] : nil);
}

- (void) setSerializedImage: (NSData *)anImageData
{
	NSImage *img = (anImageData != nil ? [NSKeyedUnarchiver unarchiveObjectWithData: anImageData] : nil);
	[self setValue: img forVariableStorageKey: kETImageProperty];
}

- (NSValue *) serializedPosition
{
	id value = nil;
	
	if ([self isRoot])
	{
		value = [self valueForVariableStorageKey: @"initialPosition"];
	}
	
	return (value == nil ? [self valueForKey: kETPositionProperty] : value);
}

- (void) setSerializedPosition: (NSValue *)aValue
{
	if ([self isRoot])
	{
		[self setValue: aValue forVariableStorageKey: @"initialPosition"];
	}
	[self setPosition: [aValue pointValue]];
}

- (NSValue *) serializedContentBounds
{
	id value = nil;

	if ([self isRoot])
	{
		value = [self valueForVariableStorageKey: @"initialContentBounds"];
	}

	return (value == nil ? [self valueForKey: kETContentBoundsProperty] : value);
}

- (void) setSerializedContentBounds: (NSValue *)aValue
{
	if ([self isRoot])
	{
		[self setValue: aValue forVariableStorageKey: @"initialContentBounds"];
	}
	[self setContentBounds: [aValue rectValue]];
}

/* The action selector is stored as a string in the variable storage */
- (NSString *) serializedAction
{
	return [self valueForVariableStorageKey: kETActionProperty];
}

- (void) setSerializedAction: (NSString *)aSelString
{
	[self setValue: aSelString forVariableStorageKey: kETActionProperty];
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
	   target in -awakeFromDeserialization once the entire object graph has been deserialized */
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
		ETLayoutItem *targetItem = (ETLayoutItem *)[[self objectGraphContext] loadedObjectForUUID: uuid];

		[self setTarget: [targetItem view]];
	}
	else
	{
		ETUUID *uuid = [ETUUID UUIDWithString: targetId];
		ETLayoutItem *targetItem = (ETLayoutItem *)[[self objectGraphContext] loadedObjectForUUID: uuid];

		[self setTarget: targetItem];
	}
}

- (NSData *) serializedView
{
	return ([self view] != nil ? [NSKeyedArchiver archivedDataWithRootObject: [self view]] : nil);
}

- (void) setSerializedView: (NSData *)newViewData
{
	NSView *newView =
		(newViewData != nil ? [NSKeyedUnarchiver unarchiveObjectWithData: newViewData] : nil);

	if (newView == nil)
		return;

	NSParameterAssert([newView superview] == nil);
	/* The item geometry might not be deserialized at this point, hence we set 
	   the view in -awakeFromDeserialization once the entire object graph has been deserialized */
	[_variableStorage setObject: newView forKey: @"serializedView"];
}

/* Required otherwise the bounds returned by -boundingBox might be serialized 
since -serializedValueForProperty: doesn't use the direct ivar access. */
- (id) serializedBoundingBox
{
	return [NSValue valueWithRect: _boundingBox];
}

- (void) setSerializedBoundingBox: (id)aBoundingBox
{
	_boundingBox = [aBoundingBox rectValue];
}

- (COObject *) serializedRepresentedObject
{
	BOOL isPersistent = ([_representedObject isKindOfClass: [COObject class]]
		&& [(COObject *)_representedObject isPersistent]);
	return (isPersistent ? _representedObject : nil);
}

/* Required to set up the KVO observation. */
- (void) setSerializedRepresentedObject: (COObject *)aRepObject
{
	NSParameterAssert(aRepObject == nil || [aRepObject isKindOfClass: [COObject class]]);
	[self setRepresentedObject: aRepObject];
}

- (void) awakeFromDeserialization
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
}

- (void)didLoadObjectGraph
{
	/* Restore target and action on the receiver item or its view */

	[self restoreTargetFromId: [_variableStorage objectForKey: @"targetId"]];
	[_variableStorage removeObjectForKey: @"targetId"];

	if ([self isRoot])
	{
		[[self layout] didLoadObjectGraph];
		[self setNeedsDisplay: YES];
	}
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

- (NSString *) serializedDoubleAction
{
	return NSStringFromSelector(_doubleAction);
}

- (void) setSerializedDoubleAction: (NSString *)aSelString
{
	_doubleAction = NSSelectorFromString(aSelString);
}

- (COObject *) serializedSource
{
	id source = [self valueForVariableStorageKey: kETSourceProperty];
	BOOL isPersistent = ([source isKindOfClass: [COObject class]]
		&& [(COObject *)source isPersistent]);

	NSAssert1(source == nil || isPersistent, @"ETLayoutItemGroup.source must "
		"be a persistent COObject and not a transient one: %@", source);

	return (isPersistent ? source : nil);
}

- (void) setSerializedSource: (COObject *)aSource
{
	NSParameterAssert(aSource == nil || [aSource isKindOfClass: [COObject class]]);
	[self setValue: aSource forVariableStorageKey: @"delegate"];
}

- (COObject *) serializedDelegate
{
	id delegate = [self valueForVariableStorageKey: @"delegate"];
	BOOL isPersistent = ([delegate isKindOfClass: [COObject class]]
		&& [(COObject *)delegate isPersistent]);

	NSAssert1(delegate == nil || isPersistent, @"ETLayoutItemGroup.delegate must "
		"be a persistent COObject and not a transient one: %@", delegate);

	return (isPersistent ? delegate : nil);
}

- (void) setSerializedDelegate: (COObject *)aDelegate
{
	NSParameterAssert(aDelegate == nil || [aDelegate isKindOfClass: [COObject class]]);
	[self setValue: aDelegate forVariableStorageKey: @"delegate"];
}

- (void) awakeFromDeserialization
{
	[super awakeFromDeserialization];

	// FIXME: Remove once we use the relationship cache
	for (ETLayoutItem *item in _items)
	{
		item->_parentItem = self;
	}
	_layout->_layoutContext = self;
}

- (void) didLoadObjectGraph
{
	[super didLoadObjectGraph];

	// FIXME: Remove once we use the relationship cache
	[[self controller] setContent: self];
}

@end


@implementation ETValueTransformersToPersistentDictionary

- (NSString *) valueTransformerName
{
	return @"ETItemValueTransformerToString";
}

@end

#endif
