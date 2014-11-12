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
	if ([target isKindOfClass: [COObject class]])
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
		COObject *target = [[self objectGraphContext] loadedObjectForUUID: uuid];

		[self setTarget: target];
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

- (ETLayoutItem *) sourceItem
{
	return ([[self ifResponds] source] != nil ? self : [[self parentItem] sourceItem]);
}

- (BOOL) isSourceItem
{
	// TODO: Remove the last part once the base item cannot represent a controller item
	return ([self baseItem] == self && [self source] != nil);
}

- (BOOL) shouldSerializeForeignRepresentedObject: (id)anObject
{
	ETLayoutItem *sourceItem = [self sourceItem];

	return (sourceItem == nil || sourceItem == self);
}

- (NSString *) serializedRepresentedObject
{
	id object = [self representedObject];
	id ref = nil;
	
	if ([object isKindOfClass: [COObject class]])
	{
		ref = [self serializedReferenceForObject: object];
	}
	else if ([self shouldSerializeForeignRepresentedObject: object])
	{
		ref = [self serializedRepresentationForObject: object];
	}

	return [self serializedValueForWeakTypedReference: ref];
}

- (ETPropertyDescription *) propertyDescriptionForRepresentedObject
{
	return [[self entityDescription] propertyDescriptionForName: kETRepresentedObjectProperty];
}

- (void) setSerializedRepresentedObject: (NSString *)value
{
	id ref = [self weakTypedReferenceForSerializedValue: value];
	id object = nil;

	if ([self isCoreObjectReference: ref])
	{
		object = [self objectForSerializedReference: ref
											 ofType: kCOTypeReference
		                        propertyDescription: [self propertyDescriptionForRepresentedObject]];
	}
	else
	{
		// TODO: -initWithSerializationRepresentation:
		object = ref;
	}

	/* Setter required to set up the KVO observation */
	[self setRepresentedObject: object];
}

- (void) awakeFromDeserialization
{
	[super awakeFromDeserialization];

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
	[super didLoadObjectGraph];

	/* Restore target and action on the receiver item or its view */

	[self restoreTargetFromId: [_variableStorage objectForKey: @"targetId"]];
	[_variableStorage removeObjectForKey: @"targetId"];

	if ([self isVisible] && [[[self parentItem] layout] isOpaque] == NO)
	{
		[[self parentItem] handleAttachViewOfItem: self];
	}

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

- (NSString *) serializedDoubleAction
{
	return NSStringFromSelector(_doubleAction);
}

- (void) setSerializedDoubleAction: (NSString *)aSelString
{
	_doubleAction = NSSelectorFromString(aSelString);
}

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
	   -[ETLayout setUp], to support switching to a new layout (if the store 
	   item contains another UUID reference for the layout relationship) */
	[self setLayout: nil];
}

- (void) restoreLayoutFromDeserialization
{
	[self setVisibleItems: [NSArray array]];
	[_layout setUp: YES];
	// NOTE: Could be removed if we don't persist the layout size
	[_layout syncLayerItemGeometryWithSize: [_layout layoutSize]];
	[self didChangeLayout: nil];

    /* For autoresizing among other things.
	   We cannot just call -updateLayoutRecursively:, it would mean sending
	   -copy to an item group would prevent items, added between the copy
	   message and the layout execution, to be autoresized. */
    [self setNeedsLayoutUpdate];
}

- (void) didLoadObjectGraph
{
	[super didLoadObjectGraph];
	[self restoreLayoutFromDeserialization];
}

@end


@implementation ETValueTransformersToPersistentDictionary

- (NSString *) valueTransformerName
{
	return @"ETItemValueTransformerToString";
}

@end
