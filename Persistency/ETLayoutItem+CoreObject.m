/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
	License: Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"
#import <CoreObject/COEditingContext.h>
#import <CoreObject/COPersistentRoot.h>
#import <CoreObject/COObject.h>
#import <CoreObject/COSerialization.h>
#import <CoreObject/COPrimitiveCollection.h>
#import "ETLayoutItem+CoreObject.h"
#import "ETCollectionToPersistentCollection.h"
#import "ETLayoutItem+Private.h"
#import "ETLayoutItemGroup+Private.h"
#import "EtoileUIProperties.h"
#import "ETOutlineLayout.h"
#import "ETUIItemIntegration.h"
#import "ETView.h"
#import "NSObject+EtoileUI.h"
#import "NSView+EtoileUI.h"

BOOL isSerializablePrimitiveValue(id value)
{
	return ([value isKindOfClass: [NSString class]]
		|| [value isKindOfClass: [NSNumber class]]
		|| [value isKindOfClass: [NSData class]]);
}

@interface COObject (COSerializationPrivate)
- (id) serializedValueForPropertyDescription: (ETPropertyDescription *)aPropertyDesc;
- (void) setSerializedValue: (id)aValue forPropertyDescription: (ETPropertyDescription *)aPropertyDesc;
@end

@implementation ETLayoutItem (CoreObject) 

- (ETLayoutItemGroup *) compoundDocument
{
	if ([self isGroup] && [(ETLayoutItemGroup *)self isCompoundDocument])
	{
		return (ETLayoutItemGroup *)self;
	}
	else if ([self parentItem] != nil)
	{
		return [[self parentItem] parentItem];	
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
		return [[self parentItem] parentItem];
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


#pragma mark Initial Values Persistency
#pragma mark -

/** We need no special cases to return -action and -doubleAction, since they
are memorized as strings in the initial values.

For view, persistentTarget and persistentTargetOwner, serialization accessors 
and loading notifications will access or update the initial values directly. */
- (BOOL) shouldSerializeInitialValueForProperty: (NSString *)aProperty
{
	// TODO: We could support -source and -representedObject, rather than
	// not supporting them with ETTemplateItemLayout.
	if ([aProperty isEqualToString: kETViewProperty]
	 || [aProperty isEqualToString: @"persistentTarget"]
	 || [aProperty isEqualToString: @"persistentTargetOwner"])
	{
		return NO;
	}

	return [_defaultValues containsKey: aProperty];
}

- (id) serializedValueForPropertyDescription: (ETPropertyDescription *)aPropertyDesc
{
	if ([self shouldSerializeInitialValueForProperty: [aPropertyDesc name]])
	{
		return [self initialValueForProperty: [aPropertyDesc name]];
	}
	else
	{
		return [super serializedValueForPropertyDescription: aPropertyDesc];
	}
}

- (void) setSerializedValue: (id)aValue
     forPropertyDescription: (ETPropertyDescription *)aPropertyDesc
{
	if ([self shouldSerializeInitialValueForProperty: [aPropertyDesc name]])
	{
		[self setInitialValue: aValue
				  forProperty: [aPropertyDesc name]];
	}
	else
	{
		[super setSerializedValue: aValue
	       forPropertyDescription: aPropertyDesc];
	}
}

#pragma mark Geometry Persistency Support
#pragma mark -

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

	return (value == nil ? [NSValue valueWithRect: _contentBounds] : value);
}

- (void) setSerializedContentBounds: (NSValue *)aValue
{
	if ([self isRoot])
	{
		[self setValue: aValue forVariableStorageKey: @"initialContentBounds"];
	}
	_contentBounds = [aValue rectValue];
}

#pragma mark Target/Action Persistency Support
#pragma mark -

/* The action selector is stored as a string in the variable storage */
- (NSString *) serializedAction
{
	return [self valueForVariableStorageKey: kETActionProperty];
}

- (void) setSerializedAction: (NSString *)aSelString
{
	[self setValue: aSelString forVariableStorageKey: kETActionProperty];
}

- (COObject *) serializedPersistentTarget
{
	id target = [self valueForVariableStorageKey: kETTargetProperty];

	if ([[self view] isWidget])
	{
		target = [[self view] target];
	}

	/* When the target is a view, the serialization occurs in -serializedPersistentTargetOwner */
	if ([target isView])
		return nil;

	ETAssert(target == nil || [target isKindOfClass: [COObject class]]);
	return target;
}

/** In -awakeFromDeserialization, we reset the target on ETLayoutItem.target and
ETLayoutItem.view.target. */
- (void) setSerializedPersistentTarget: (COObject *)aTarget
{
	[self setValue: aTarget forVariableStorageKey: @"persistentTarget"];
}

- (ETLayoutItem *) serializedPersistentTargetOwner
{
	id target = [self valueForVariableStorageKey: kETTargetProperty];

	if ([[self view] isWidget])
	{
		target = [[self view] target];
	}

	/* When the target is a COObject, the serialization occurs in -serializedPersistentTarget */
	if ([target isKindOfClass: [COObject class]])
		return nil;

	ETAssert(target == nil || ([target isView] && [target owningItem] != nil));
	return [target owningItem];
}

- (void) setSerializedPersistentTargetOwner: (ETLayoutItem *)aTarget
{
	[self setValue: aTarget forVariableStorageKey: @"persistentTargetOwner"];
}

- (void) restoreTargetFromDeserialization
{
	id target = [self valueForVariableStorageKey: @"persistentTarget"];

	if (target == nil)
	{
		ETLayoutItem *targetOwner = [self valueForVariableStorageKey: @"persistentTargetOwner"];

		target = [targetOwner view];
	}

	/** For ETLayoutItem.target, -will/didChangeValueForProperty: is not needed,
	    it is a unidirectional relationship not present in the relationship cache. */
	[self setValue: target forVariableStorageKey: kETTargetProperty];

	if ([[self view] isWidget])
	{
		[[self view] setTarget: target];
	}
	
	[self setValue: nil forVariableStorageKey: @"persistentTarget"];
	[self setValue: nil forVariableStorageKey: @"persistentTargetOwner"];
}

#pragma mark View Persistency Support
#pragma mark -

- (NSData *) serializedView
{
	NSView *view = nil;

	if ([_defaultValues containsKey: kETViewProperty])
	{
		view = [self initialValueForProperty: kETViewProperty];

	}
	else
	{
		view = [self view];
	}

	return (view != nil ? [NSKeyedArchiver archivedDataWithRootObject: view] : nil);
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
	_deserializationState[kETViewProperty] = newView;
}

/** We use -setView: to recreate supervisorView which is transient and set up
the state and object value observers.
 
Will involve a unnecessary -syncView:withRepresentedObject: call. */
- (void) restoreViewFromDeserialization
{
	NSView *serializedView = _deserializationState[kETViewProperty];

	if (serializedView == nil)
		return;

	if ([_defaultValues containsKey: kETViewProperty])
	{
		[self setInitialValue: serializedView
		          forProperty: kETViewProperty];
	}
	else
	{
		[self setView: serializedView];
	}
	[_deserializationState removeObjectForKey: kETViewProperty];
}

#pragma mark Represented Object Persistency Support
#pragma mark -

- (BOOL) isSerializableRelationshipCollection: (id <ETCollection>)aCollection
{
	return [[[aCollection objectEnumerator] nextObject] isKindOfClass: [COObject class]];
}

- (BOOL) isSerializableAttributeCollection: (id <ETCollection>)aCollection
{
	return isSerializablePrimitiveValue([[aCollection objectEnumerator] nextObject]);
}

static NSString *representedRelationshipKey = @"representedRelationship";
static NSString *representedAttributeKey = @"representedAttribute";
static NSString *representedOrderedRelationshipKey = @"representedOrderedRelationship";
static NSString *representedOrderedAttributeKey = @"representedOrderedAttribute";
static NSString *representedUnorderedRelationshipKey = @"representedUnorderedRelationship";
static NSString *representedUnorderedAttributeKey = @"representedUnorderedAttribute";

- (NSString *) representedObjectKey
{
	if ([_representedObject isKindOfClass: [COObject class]])
	{
		return representedRelationshipKey;
	}
	else if ([_representedObject isKindOfClass: [NSArray class]])
	{
		if ([_representedObject isEmpty] || [self isSerializableRelationshipCollection: _representedObject])
		{
			return representedOrderedRelationshipKey;
		}
		else if ([self isSerializableAttributeCollection: _representedObject])
		{
			return representedOrderedAttributeKey;
		}
	}
	else if ([_representedObject isKindOfClass: [NSSet class]])
	{
		if ([_representedObject isEmpty] || [self isSerializableRelationshipCollection: _representedObject])
		{
			return representedUnorderedRelationshipKey;
		}
		else if ([self isSerializableAttributeCollection: _representedObject])
		{
			return representedUnorderedAttributeKey;
		}
	}
	else if (isSerializablePrimitiveValue(_representedObject))
	{
		return representedAttributeKey;
	}
	return nil;
}

- (NSString *) serializedRepresentedObjectKey
{
	return [self representedObjectKey];
}

- (void) setSerializedRepresentedObjectKey: (NSString *)aKey
{
	if (aKey == nil)
		return;

	_deserializationState[@"representedObjectKey"] = aKey;
}

#pragma mark Represented Attribute Persistency Support
#pragma mark -

- (NSObject *) representedAttribute
{
	return (isSerializablePrimitiveValue(_representedObject) ? _representedObject : nil);
}

- (void) setRepresentedAttribute: (NSObject *)aValue
{
	ETAssert(aValue == nil || isSerializablePrimitiveValue(aValue));

	if ([[self representedObjectKey] isEqualToString: representedAttributeKey] == NO)
		return;
	
	[self setRepresentedObject: aValue];
}

- (NSObject *) serializedRepresentedAttribute
{
	return [self representedAttribute];
}

- (void) setSerializedRepresentedAttribute: (NSObject *)aValue
{
	if (aValue == nil)
		return;

	ETAssert(isSerializablePrimitiveValue(aValue));
	_deserializationState[representedAttributeKey] = aValue;
}

- (NSArray *) representedOrderedAttribute
{
	BOOL isArray = [_representedObject isKindOfClass: [NSArray class]];

	if (isArray && [self isSerializableAttributeCollection: _representedObject])
	{
		return [COMutableArray arrayWithArray:_representedObject];
	}
	return [COMutableArray array];
}

- (void) setRepresentedOrderedAttribute: (NSArray *)aValue
{
	ETAssert([aValue isKindOfClass: [NSArray class]]);
	ETAssert([aValue isEmpty] || [self isSerializableAttributeCollection: aValue]);

	if ([[self representedObjectKey] isEqualToString: representedOrderedAttributeKey] == NO)
		return;

	[self setRepresentedObject: aValue];
}

- (NSArray *) serializedRepresentedOrderedAttribute
{
	return [self representedOrderedAttribute];
}

- (void) setSerializedRepresentedOrderedAttribute: (NSArray *)aValue
{
	ETAssert([aValue isKindOfClass: [NSArray class]]);
	ETAssert([aValue isEmpty] || [self isSerializableAttributeCollection: aValue]);
	_deserializationState[representedOrderedAttributeKey] = aValue;
}

- (NSSet *) representedUnorderedAttribute
{
	BOOL isSet = [_representedObject isKindOfClass: [NSSet class]];
	
	if (isSet && [self isSerializableRelationshipCollection: _representedObject])
	{
		return [COMutableSet setWithSet: _representedObject];
	}
	return [COMutableSet set];
}

- (void) setRepresentedUnorderedAttribute: (NSSet *)aValue
{
	ETAssert([aValue isKindOfClass: [NSSet class]]);
	ETAssert([aValue isEmpty] || [self isSerializableAttributeCollection: aValue]);

	if ([[self representedObjectKey] isEqualToString: representedUnorderedAttributeKey] == NO)
		return;

	[self setRepresentedObject: aValue];
}

- (NSSet *) serializedRepresentedUnorderedAttribute
{
	return [self representedUnorderedAttribute];
}

- (void) setSerializedRepresentedUnorderedAttribute: (NSSet *)aValue
{
	ETAssert([aValue isKindOfClass: [NSSet class]]);
	ETAssert([aValue isEmpty] || [self isSerializableAttributeCollection: aValue]);
	_deserializationState[representedUnorderedAttributeKey] = aValue;
}

#pragma mark Represented Relationship Persistency Support
#pragma mark -

- (COObject *) representedRelationship
{
	return ([_representedObject isKindOfClass: [COObject class]] ? _representedObject : nil);
}

- (void) setRepresentedRelationship: (COObject *)aValue
{
	ETAssert(aValue == nil || [aValue isKindOfClass: [COObject class]]);

	if ([[self representedObjectKey] isEqualToString: representedRelationshipKey] == NO)
		return;
	
	[self setRepresentedObject: aValue];
}

- (COObject *) serializedRepresentedRelationship
{
	return [self representedRelationship];
}

- (void) setSerializedRepresentedRelationship: (COObject *)aValue
{
	if (aValue == nil)
		return;

	ETAssert([aValue isKindOfClass: [COObject class]]);
	_deserializationState[representedRelationshipKey] = aValue;
}

- (NSArray *) representedOrderedRelationship
{
	BOOL isArray = [_representedObject isKindOfClass: [NSArray class]];

	if (isArray && [self isSerializableRelationshipCollection: _representedObject])
	{
		return [COMutableArray arrayWithArray: _representedObject];
	}
  return [COMutableArray array];
}

- (void) setRepresentedOrderedRelationship: (NSArray *)aValue
{
	ETAssert([aValue isKindOfClass: [NSArray class]]);
	ETAssert([aValue isEmpty] || [self isSerializableRelationshipCollection: aValue]);
	
	if ([[self representedObjectKey] isEqualToString: representedOrderedRelationshipKey] == NO)
		return;

	[self setRepresentedObject: aValue];
}

- (NSArray *) serializedRepresentedOrderedRelationship
{
	return [self representedOrderedRelationship];
}

- (void) setSerializedRepresentedOrderedRelationship: (NSArray *)aValue
{
	ETAssert([aValue isKindOfClass: [NSArray class]]);
	ETAssert([aValue isEmpty] || [self isSerializableRelationshipCollection: aValue]);
	_deserializationState[representedOrderedRelationshipKey] = aValue;
}

- (NSSet *) representedUnorderedRelationship
{
	BOOL isSet = [_representedObject isKindOfClass: [NSSet class]];

	if (isSet && [self isSerializableRelationshipCollection: _representedObject])
	{
		return [COMutableSet setWithSet: _representedObject];
	}
	return [COMutableSet set];
}

- (void) setRepresentedUnorderedRelationship: (NSSet *)aValue
{
	ETAssert([aValue isKindOfClass: [NSSet class]]);
	ETAssert([aValue isEmpty] || [self isSerializableRelationshipCollection: aValue]);

	if ([[self representedObjectKey] isEqualToString: representedUnorderedRelationshipKey] == NO)
		return;
	
	[self setRepresentedObject: aValue];
}

- (NSSet *) serializedRepresentedUnorderedRelationship
{
	return [self representedUnorderedRelationship];
}

- (void) setSerializedRepresentedUnorderedRelationship: (NSSet *)aValue
{
	ETAssert([aValue isKindOfClass: [NSSet class]]);
	ETAssert([aValue isEmpty] || [self isSerializableRelationshipCollection: aValue]);
	_deserializationState[representedUnorderedRelationshipKey] = aValue;
}

- (void) restoreRepresentedObjectFromDeserialization
{
	NSString *key = _deserializationState[@"representedObjectKey"];
	id object = _deserializationState[key];

	/* Setter required to set up the KVO observation */
	[self setRepresentedObject: object];
	
	[_deserializationState removeObjectsForKeys: @[@"representedObjectKey",
		representedAttributeKey, representedRelationshipKey,
		representedOrderedAttributeKey, representedOrderedRelationshipKey,
		representedUnorderedAttributeKey, representedUnorderedRelationshipKey]];
}

#pragma mark Loading Notifications
#pragma mark -


- (void) awakeFromDeserialization
{
	[super awakeFromDeserialization];

	// TODO: May be reset the bounding box if not persisted
	//_boundingBox = ETNullRect;
	[self prepareTransientState];
	/* We ensure the supervisor view geometry (flipped, frame and autoresizing) 
	   is synchronized with the receiver, since item geometry can change with 
	   deserialization.

	   We don't implement -willLoadObjectGraph to discard the supervisor view
	   and recreate it kater in -restoreViewFromDeserialization or
	   -restoreLayoutFromDeserialization, since -[ETLayoutItemGroup willLoadObjectGraph] 
	   can call -[ETLayoutItemGroup setExposedItems:] by tearing down the layout, 
	   and wrongly recreate some item supervisor views in this way. */
	[self syncSupervisorViewGeometry: ETSyncSupervisorViewFromItem];

	[self restoreViewFromDeserialization];
	[self restoreRepresentedObjectFromDeserialization];
}

- (void)didLoadObjectGraph
{
	[super didLoadObjectGraph];

	[self restoreTargetFromDeserialization];

	[self setNeedsDisplay: YES];
}

#pragma mark Serialization State Management
#pragma mark -

/** We cannot allocate the deserialization state in the initializer, since this 
step is skipped when loading an item not present in memory. */
- (void) setStoreItem: (COItem *)storeItem
{
	if (_deserializationState == nil)
	{
		_deserializationState = [NSMutableDictionary new];
	}
	ETAssert([_deserializationState isEmpty]);

	[super setStoreItem: storeItem];
}

@end

@implementation ETLayoutItemGroup (CoreObject)

#pragma mark Compound Document Additions

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

#pragma mark Source Persistency Support
#pragma mark -

- (NSArray *) serializedItems
{
	return ([self sourceItem] == nil ? _items : [COMutableArray array]);
}

- (void) setSerializedItems: (NSArray *)items
{
	[self willChangeValueForProperty: @"items"];
	_items = [items mutableCopy];
	/* Update the relationship cache */
	[self didChangeValueForProperty: @"items"];
}

- (COObject *) serializedSource
{
	id source = [self valueForVariableStorageKey: kETSourceProperty];

	return ([source isKindOfClass: [COObject class]] ? source : nil);
}

- (void) setSerializedSource: (COObject *)aSource
{
	if (aSource == nil)
		return;

	_deserializationState[kETSourceProperty] = aSource;
}

#pragma mark Action Persistency Support
#pragma mark -

- (NSString *) serializedDoubleAction
{
	return NSStringFromSelector(_doubleAction);
}

- (void) setSerializedDoubleAction: (NSString *)aSelString
{
	_doubleAction = NSSelectorFromString(aSelString);
}

#pragma mark Loading Notifications
#pragma mark -

- (void) awakeFromDeserialization
{
	[super awakeFromDeserialization];

	_hasNewContent = ([_items isEmpty] == NO);
	_hasNewArrangement = YES;
	_hasNewLayout = YES;
	_sorted = NO;
	_filtered = NO;
}

- (void) willLoadObjectGraph
{
	[super willLoadObjectGraph];

	/* Unapply external state changes related to the layout, usually during 
	   -[ETLayout setUp:], to support switching to a new layout (if the store 
	   item contains another UUID reference for the layout relationship) */
	[self setLayout: nil];
}

- (void) restoreLayoutFromDeserialization
{
	[self setExposedItems: [NSArray array]];
	[_layout setUp: YES];
	[self didChangeLayout: nil];

    /* For autoresizing and reloading layout view content in ETWidgetLayout.

	   We cannot just call -updateLayoutRecursively:, there are two reasons:

	   - the layout transient state might not be entirely recreated, when both
		 the layout and its context gets reloaded at the same time
		 (-didLoadObjectGraph could have been sent to the context and not yet to
		 the layout).
	   - it would mean sending -copy to an item group would prevent items,
	     added between the copy message and the layout execution, to be
	     autoresized. */
    [self setNeedsLayoutUpdate];
}

- (void) restoreSourceFromDeserialization
{
	[self setSource: _deserializationState[kETSourceProperty]];
	[_deserializationState removeObjectForKey: kETSourceProperty];
}

- (void) restoreViewHierarchyFromDeserialization
{
	[self setUpSupervisorViewsForNewItemsIfNeeded: @[]];
}

- (void) didLoadObjectGraph
{
	[super didLoadObjectGraph];
	[self restoreViewHierarchyFromDeserialization];
	[self restoreLayoutFromDeserialization];
	[self restoreSourceFromDeserialization];
}

@end


@implementation ETValueTransformersToPersistentDictionary

- (NSString *) valueTransformerName
{
	return @"ETItemValueTransformerToString";
}

@end
