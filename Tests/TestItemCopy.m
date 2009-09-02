/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2009
    License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/ETUTI.h>
#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "ETController.h"
#import "ETDecoratorItem.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "EtoileUIProperties.h"
#import "ETScrollableAreaItem.h"
#import "ETTableLayout.h"
#import "ETUIItem.h"
#import "ETUIItemFactory.h"
#import "ETWindowItem.h"
#import "ETCompatibility.h"

@interface ETDecoratorItem (TestItemGeometry)
+ (ETDecoratorItem *) itemWithDummySupervisorView;
@end

@interface TestItemCopy: NSObject <UKTest>
{
	ETUIItemFactory *itemFactory;
	ETLayoutItem *item;
	ETLayoutItemGroup *itemGroup;
}

@end

@implementation TestItemCopy

- (id) init
{
	SUPERINIT
	ASSIGN(itemFactory, [ETUIItemFactory factory]);
	item = [[ETLayoutItem alloc] init];
	itemGroup = [[ETLayoutItemGroup alloc] init];
	return self;
}

DEALLOC(DESTROY(itemFactory); DESTROY(item); DESTROY(itemGroup))

- (NSArray *) nonCheckablePropertiesForAnyObject
{
	NSArray *rootObjectProperties = [(NSObject *)AUTORELEASE([[NSObject alloc] init]) properties];
	return [rootObjectProperties arrayByRemovingObjectsInArray:
		A(kETNameProperty, kETDisplayNameProperty, kETIconProperty)];
}

- (NSArray *) checkablePropertiesForItem: (ETUIItem *)anItem
{
	NSArray *excludedProperties = [self nonCheckablePropertiesForAnyObject];
	return [[anItem properties] arrayByRemovingObjectsInArray: excludedProperties];
}

- (void) checkViewCopy: (ETView *)newView ofView: (ETView *)aView
{
	NSArray *equalProperties = A(@"x", @"y", @"width", @"height", @"tag", 
		@"hidden", @"autoresizingMask", @"autoresizesSubviews", @"flipped", 
		@"frame", @"frameRotation", @"bounds", @"boundsRotation", 
		@"isRotatedFromBase", @"isRotatedOrScaledFromBase", 
		@"postsFrameChangedNotifications", @"postsBoundsChangedNotifications", 
		@"visibleRect", @"opaque", @"needsPanelToBecomeKey"); 

	FOREACH(equalProperties, property, NSString *)
	{
		/* We could use -valueForKey: as well */
		id value = [aView valueForProperty: property];
		id copiedValue = [newView valueForProperty: property];

		ETLog(@"'%@'", property);
		UKObjectsEqual(value, copiedValue);
	}
}

- (NSArray *) defaultNilItemProperties
{
	return A(kETNameProperty, kETIconProperty, kETImageProperty,
		kETRepresentedObjectProperty, kETRepresentedPathBaseProperty, 
		kETSubtypeProperty, kETActionProperty, kETTargetProperty);
}

- (NSArray *) nonEqualItemProperties
{
	return A(kETDisplayNameProperty, kETDecoratorItemProperty, 
		kETDecoratedItemProperty, @"firstDecoratedItem", @"lastDecoratorItem", 
		@"enclosingItem", @"supervisorView", kETViewProperty, 
		kETParentItemProperty, kETStyleGroupProperty, kETLayoutProperty);
}

- (void) testBasicItemCopy
{
	NSArray *properties = [self checkablePropertiesForItem: item];
	NSArray *nilProperties = [self defaultNilItemProperties];
	NSArray *equalProperties = [properties arrayByRemovingObjectsInArray: 
		[[self nonEqualItemProperties] arrayByAddingObjectsFromArray: nilProperties]];

	ETLayoutItem *newItem = [item copy];

	FOREACH(equalProperties, property, NSString *)
	{
		/* We could use -valueForKey: as well, see -testItemCopy */
		id value = [item valueForProperty: property];
		id copiedValue = [newItem valueForProperty: property];

		ETLog(@"'%@'", property);
		UKObjectsEqual(value, copiedValue);
	}

	UKNil([newItem decoratorItem]);
	UKNil([newItem decoratedItem]);
	UKNil([newItem supervisorView]);
	UKNil([newItem parentItem]);
	UKNil([newItem layout]);
	UKNil([newItem view]);
}

- (void) testItemCopy
{
	[item setName: @"Whatever"];
	[item setImage: [NSImage imageNamed: @"NSApplicationIcon"]];
	[item setIcon: [[NSWorkspace sharedWorkspace] iconForFile: @"/"]];
	[item setRepresentedObject: [NSSet set]];
	[item setSubtype: [ETUTI typeWithClass: [NSSet class]]];
	[item setTarget: self];
	[item setAction: @selector(wibble:)];
	[item setView: AUTORELEASE([[NSButton alloc] init])];
	[item setDecoratorItem: [ETDecoratorItem itemWithDummySupervisorView]];
	//[[item decoratorItem] setDecoratorItem: [ETWindowItem item]];

	NSArray *properties = [self checkablePropertiesForItem: item];
	NSArray *nilProperties = A(kETRepresentedPathBaseProperty);
	NSArray *equalProperties = [properties arrayByRemovingObjectsInArray: 
		[[self nonEqualItemProperties] arrayByAddingObjectsFromArray: nilProperties]];

	ETLayoutItem *newItem = [item copy];

	FOREACH(equalProperties, property, NSString *)
	{
		/* We don't want to check the properties on the represented object but 
		   on the item itself, so we must use -valueForKey: which has no custom 
		   lookup policy on the represented object unlike -valueForProperty:. */
		id value = [item valueForKey: property];
		id copiedValue = [newItem valueForKey: property];

		ETLog(@"'%@'", property);
		UKObjectsEqual(value, copiedValue);
	}

	UKNil([newItem decoratedItem]);
	UKNotNil([newItem decoratorItem]);
	UKNotNil([[newItem decoratorItem] decoratedItem]);
	/*UKNotNil([[newItem decoratorItem] decoratorItem]);
	UKNotNil([[[newItem decoratorItem] decoratorItem] decoratedItem]);*/
	UKObjectsEqual([[newItem supervisorView] class], [[item supervisorView] class]);
	UKNil([newItem parentItem]);
	// TODO: Set a layout and UKNotNil([newItem layout]);
	UKObjectsEqual([[newItem view] class], [[item view] class]);

	[self checkViewCopy: [newItem supervisorView] ofView: [item supervisorView]];
}

- (NSArray *) defaultNilItemGroupProperties
{
	return [[self defaultNilItemProperties] arrayByAddingObjectsFromArray:
		A(kETDelegateProperty, kETSourceProperty, kETDoubleClickedItemProperty)];
}

- (NSArray *) nonEqualItemGroupProperties
{
	return [self nonEqualItemProperties];
}

- (void) testEmptyBasicItemGroupCopy
{
	ETLayoutItemGroup *newItemGroup = [itemGroup copy];

	NSArray *properties = [self checkablePropertiesForItem: itemGroup];
	NSArray *nilProperties = [self defaultNilItemGroupProperties];
	NSArray *equalProperties = [properties arrayByRemovingObjectsInArray: 
		[[self nonEqualItemGroupProperties] arrayByAddingObjectsFromArray: nilProperties]];

	FOREACH(equalProperties, property, NSString *)
	{
		/* We don't want to check the properties on the represented object but 
		   on the item itself, so we must use -valueForKey: which has no custom 
		   lookup policy on the represented object unlike -valueForProperty:. */
		id value = [itemGroup valueForKey: property];
		id copiedValue = [newItemGroup valueForKey: property];

		ETLog(@"'%@'", property);
		UKObjectsEqual(value, copiedValue);
	}

	UKObjectsEqual(newItemGroup, [[newItemGroup layout] layoutContext]);
}

- (void) testEmptyItemGroupCopy
{
	[itemGroup setName: @"Whatever"];
	[itemGroup setImage: [NSImage imageNamed: @"NSApplicationIcon"]];
	[itemGroup setIcon: [[NSWorkspace sharedWorkspace] iconForFile: @"/"]];
	[itemGroup setRepresentedObject: [NSSet set]];
	[itemGroup setSubtype: [ETUTI typeWithClass: [NSSet class]]];
	[itemGroup setTarget: self];
	[itemGroup setAction: @selector(wibble:)];
	[itemGroup setView: AUTORELEASE([[NSButton alloc] init])];
	[itemGroup setDecoratorItem: [ETDecoratorItem itemWithDummySupervisorView]];

	[itemGroup setRepresentedPathBase: @"/my/model/path"];
	[itemGroup setSource: self];
	[itemGroup setController: AUTORELEASE([[ETController alloc] init])];
	[itemGroup setDelegate: self];
	[itemGroup setDoubleAction: @selector(boum:)];
	
	[itemGroup setLayout: [ETTableLayout layout]];

	ETLayoutItemGroup *newItemGroup = [itemGroup copy];

	NSArray *properties = [self checkablePropertiesForItem: itemGroup];
	NSArray *nilProperties = A(kETDoubleClickedItemProperty);
	NSArray *equalProperties = [properties arrayByRemovingObjectsInArray: 
		[[self nonEqualItemGroupProperties] arrayByAddingObjectsFromArray: nilProperties]];

	// FIXME: -hasVerticallScroller automatically creates a cached scrollable
	// area item and is called -[ETWidgetLayout syncLayoutViewWithItem:].
	// -hasVerticalScroller should just return NO in this case.
	equalProperties = [equalProperties arrayByRemovingObjectsInArray: A(@"cachedScrollViewDecoratorItem")];

	FOREACH(equalProperties, property, NSString *)
	{
		/* We don't want to check the properties on the represented object but 
		   on the item itself, so we must use -valueForKey: which has no custom 
		   lookup policy on the represented object unlike -valueForProperty:. */
		id value = [itemGroup valueForKey: property];
		id copiedValue = [newItemGroup valueForKey: property];

		ETLog(@"'%@'", property);
		UKObjectsEqual(value, copiedValue);
	}

	UKObjectsEqual(newItemGroup, [[newItemGroup layout] layoutContext]);
	UKObjectsNotEqual([[itemGroup layout] layoutView], [[newItemGroup layout] layoutView]);
	UKObjectsEqual([[newItemGroup supervisorView] contentView], [[newItemGroup layout] layoutView]);
	UKObjectsEqual([newItemGroup supervisorView], [[[newItemGroup layout] layoutView] superview]);
}

- (void) testBasicItemGroupCopy
{
	[itemGroup addItem: item];

	ETLayoutItemGroup *newItemGroup = [itemGroup copy];
}

- (void) testItemTreeCopy
{

}

@end

