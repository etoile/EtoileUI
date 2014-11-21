/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2009
    License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/ETUTI.h>
#import <EtoileFoundation/NSIndexPath+Etoile.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "TestCommon.h"
#import "ETController.h"
#import "ETDecoratorItem.h"
#import "ETFlowLayout.h"
#import "ETGeometry.h"
#import "ETIconLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutExecutor.h"
#import "EtoileUIProperties.h"
#import "ETScrollableAreaItem.h"
#import "ETTableLayout.h"
#import "ETTemplateItemLayout.h"
#import "ETOutlineLayout.h"
#import "ETUIItem.h"
#import "ETLayoutItemFactory.h"
#import "ETWindowItem.h"
#import "ETCompatibility.h"

#define UKPropertiesEqual(a, b, property) \
	printf("Test copy '%s'\n", [property UTF8String]); UKObjectsEqual(a, b); 
// NOTE: We abuse UKObjectsSame() by using it to test boolean property equality
#define UKPropertiesSame(a, b, property) \
	printf("Test copy '%s'\n", [property UTF8String]); UKObjectsSame(a, b);

@interface ETOutlineLayout (Private)
- (NSOutlineView *) outlineView;
@end

@interface ETTemplateItemLayout (TestItemCopy)
- (NSSet *) renderedItems;
@end

@implementation ETTemplateItemLayout (TestItemCopy)
- (NSSet *) renderedItems
{
	return _renderedItems; /* Protected ivar tested in -testIconLayoutCopy */
}
@end

@interface ETLayoutItem (TestItemCopy)
- (BOOL) isNotVisible;
@end

@implementation ETLayoutItem (TestItemCopy)
- (BOOL) isNotVisible
{
	return [self isVisible] == NO;
}
@end

@interface TestItemCopy: TestCommon <UKTest>
{
	ETLayoutItem *item;
	ETLayoutItemGroup *itemGroup;
}

@end

@implementation TestItemCopy

- (id) init
{
	SUPERINIT;
	item = [[ETLayoutItem alloc] initWithObjectGraphContext: [itemFactory objectGraphContext]];
	itemGroup = [[ETLayoutItemGroup alloc] initWithObjectGraphContext: [itemFactory objectGraphContext]];
	return self;
}

DEALLOC(DESTROY(itemFactory); DESTROY(item); DESTROY(itemGroup))

- (NSArray *) nonCheckablePropertiesForAnyObject
{
	ETModelDescriptionRepository *repo = [ETModelDescriptionRepository mainRepository];
	NSArray *rootObjectProperties = [(NSObject *)AUTORELEASE([[NSObject alloc] init]) propertyNames];
	NSArray *coreObjectProperties =
		[[repo entityDescriptionForClass: [COObject class]] propertyDescriptionNames];
	NSArray *excludedProperties =
		[rootObjectProperties arrayByAddingObjectsFromArray: coreObjectProperties];
	
	return [excludedProperties arrayByRemovingObjectsInArray:
		A(kETNameProperty, kETDisplayNameProperty, kETIdentifierProperty, kETIconProperty)];
}

- (NSArray *) checkablePropertiesForItem: (ETUIItem *)anItem
{
	NSArray *excludedProperties = [self nonCheckablePropertiesForAnyObject];
	return [[anItem propertyNames] arrayByRemovingObjectsInArray: excludedProperties];
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

		UKPropertiesEqual(value, copiedValue, property);
	}
}

- (NSArray *) basicNilItemProperties
{
	return  A(@"hostItem", @"controllerItem", kETBaseItemProperty, kETRootItemProperty, kETIdentifierProperty,
		@"representedAttribute", @"representedRelationship", kETValueProperty, kETValueKeyProperty,
		kETStyleProperty, @"persistentTarget", @"persistentTargetOwner",
		@"title", @"formatter", @"attachedTool");
}

- (NSArray *) defaultNilItemProperties
{
	return [A(kETNameProperty, kETIconProperty,  kETImageProperty,
		kETRepresentedObjectProperty, @"representedObjectKey", kETSubjectProperty,
		kETSubtypeProperty, kETActionProperty, kETTargetProperty, @"UIBuilderAction")
			arrayByAddingObjectsFromArray: [self basicNilItemProperties]];
}

- (NSArray *) nonEqualItemProperties
{
	// NOTE: For now, we copy 'icon' and 'image' properties due to COCopier semantics.
	return A(kETDisplayNameProperty, kETIconProperty, kETImageProperty, kETDecoratorItemProperty,
		kETDecoratedItemProperty, @"firstDecoratedItem", @"lastDecoratorItem", 
		@"enclosingItem", @"supervisorView", kETViewProperty, kETNextResponderProperty, 
		kETParentItemProperty, kETRootItemProperty, kETStyleGroupProperty, kETLayoutProperty,
		kETCoverStyleProperty, kETActionHandlerProperty, kETTargetProperty);
}

- (NSArray *) identicalItemProperties
{
	return A(@"shouldSyncSupervisorView");
}

- (NSArray *) nonIdenticalItemProperties
{
	return A(@"shouldSyncSupervisorView");
}

- (void) testBasicItemCopy
{
	NSArray *properties = [self checkablePropertiesForItem: item];
	NSArray *nilProperties = [self defaultNilItemProperties];
	NSArray *nonIdenticalProperties = [self nonIdenticalItemProperties];
	NSArray *nonEqualOrIdenticalProperties = [[self nonEqualItemProperties] 
		arrayByAddingObjectsFromArray: nonIdenticalProperties];
	NSArray *equalProperties = [properties arrayByRemovingObjectsInArray: 
		[nonEqualOrIdenticalProperties arrayByAddingObjectsFromArray: nilProperties]];

	ETLayoutItem *newItem = [item copy];

	FOREACH(equalProperties, property, NSString *)
	{
		/* We could use -valueForKey: as well, see -testItemCopy */
		id value = [item valueForProperty: property];
		id copiedValue = [newItem valueForProperty: property];

		UKPropertiesEqual(value, copiedValue, property);
	}

	UKNil([newItem decoratorItem]);
	UKNil([newItem decoratedItem]);
	UKNil([newItem supervisorView]);
	UKNil([newItem parentItem]);
	UKNil([newItem layout]);
	UKNil([newItem view]);

	RELEASE(newItem);
}

- (void) testItemCopy
{
	[item setName: @"Whatever"];
	[item setIdentifier: @"Whoever"];
	[item setImage: [NSImage imageNamed: @"NSApplicationIcon"]];
	[item setIcon: [[NSWorkspace sharedWorkspace] iconForFile: @"/"]];
	[item setRepresentedObject: [NSSet set]];
	[item setSubtype: [ETUTI typeWithClass: [NSSet class]]];
	// NOTE: -UIBuilderTarget and -UIBuilderAction still returns nil and NULL
	[item setView: AUTORELEASE([[NSButton alloc] init])];
	[item setTarget: item];
	[item setAction: @selector(wibble:)];
	//[item setDecoratorItem: [ETDecoratorItem itemWithDummySupervisorView]];
	//[[item decoratorItem] setDecoratorItem: [ETWindowItem item]];

	NSArray *properties = [self checkablePropertiesForItem: item];
	NSArray *nilProperties = [self basicNilItemProperties];
	NSArray *nonIdenticalProperties = [self nonIdenticalItemProperties];
	NSArray *nonEqualOrIdenticalProperties = [[self nonEqualItemProperties] 
		arrayByAddingObjectsFromArray: nonIdenticalProperties];
	NSArray *equalProperties = [properties arrayByRemovingObjectsInArray: 
		[nonEqualOrIdenticalProperties arrayByAddingObjectsFromArray: nilProperties]];

	ETLayoutItem *newItem = [item copy];
	// FIXME: Implement decorator serialization
	[item setDecoratorItem: [ETDecoratorItem itemWithDummySupervisorView]];
	[newItem setDecoratorItem: [ETDecoratorItem itemWithDummySupervisorView]];
	
	FOREACH(equalProperties, property, NSString *)
	{
		/* We don't want to check the properties on the represented object but 
		   on the item itself, so we must use -valueForKey: which has no custom 
		   lookup policy on the represented object unlike -valueForProperty:. */
		id value = [item valueForKey: property];
		id copiedValue = [newItem valueForKey: property];

		UKPropertiesEqual(value, copiedValue, property);
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

	RELEASE(newItem);
}

- (NSArray *) defaultNilItemGroupProperties
{
	return [[self defaultNilItemProperties] arrayByAddingObjectsFromArray:
		A(kETDelegateProperty, kETSourceProperty, kETDoubleClickedItemProperty, @"doubleAction")];
}

- (NSArray *) nonEqualItemGroupProperties
{
	return [[self nonEqualItemProperties] arrayByAddingObjectsFromArray:
		A(@"items", kETControllerProperty, kETDelegateProperty, kETTargetProperty)];
}

- (void) testBasicItemGroupCopy
{
	[itemGroup addItem: item];

	ETLayoutItemGroup *newItemGroup = [itemGroup copy];
	ETLayoutItem *newItem = [newItemGroup firstItem];

	NSArray *properties = [self checkablePropertiesForItem: itemGroup];
	NSArray *nilProperties = [self defaultNilItemGroupProperties];
	NSArray *nonIdenticalProperties = [self nonIdenticalItemProperties];
	NSArray *nonEqualOrIdenticalProperties = [[self nonEqualItemGroupProperties] 
		arrayByAddingObjectsFromArray: nonIdenticalProperties];
	NSArray *equalProperties = [properties arrayByRemovingObjectsInArray: 
		[nonEqualOrIdenticalProperties arrayByAddingObjectsFromArray: nilProperties]];

	FOREACH(equalProperties, property, NSString *)
	{
		/* We don't want to check the properties on the represented object but 
		   on the item itself, so we must use -valueForKey: which has no custom 
		   lookup policy on the represented object unlike -valueForProperty:. */
		id value = [itemGroup valueForKey: property];
		id copiedValue = [newItemGroup valueForKey: property];

		UKPropertiesEqual(value, copiedValue, property);
	}

	UKIntsEqual(1, [[newItemGroup items] count]);
	UKObjectsSame(newItemGroup, [newItem parentItem]);
	UKObjectsNotEqual([item UUID], [newItem UUID]);
	UKObjectsEqual(newItemGroup, [[newItemGroup layout] layoutContext]);

	RELEASE(newItemGroup);
}

- (void) testItemGroupCopyAndAddItem
{
	ETLayoutItemGroup *newItemGroup = AUTORELEASE([itemGroup copy]);

	[newItemGroup addItem: item];

	UKObjectsEqual(A(item), [newItemGroup items]);
	UKObjectsEqual(A(item), [newItemGroup arrangedItems]);
}

- (void) testEmptyItemGroupCopy
{
	ETController *controller = AUTORELEASE([[ETController alloc]
		initWithObjectGraphContext: [itemFactory objectGraphContext]]);

	[itemGroup setName: @"Whatever"];
	[itemGroup setImage: [NSImage imageNamed: @"NSApplicationIcon"]];
	//[itemGroup setIcon: [[NSWorkspace sharedWorkspace] iconForFile: @"/"]];
	[itemGroup setRepresentedObject: [NSSet set]];
	[itemGroup setSubtype: [ETUTI typeWithClass: [NSSet class]]];
	[itemGroup setView: AUTORELEASE([[NSButton alloc] init])];
	[itemGroup setTarget: controller];
	[itemGroup setAction: @selector(wibble:)];
	//[itemGroup setDecoratorItem: [ETDecoratorItem itemWithDummySupervisorView]];

	[itemGroup setSource: itemGroup];
	[itemGroup setController: controller];
	[itemGroup setDelegate: controller];
	[itemGroup setDoubleAction: @selector(boum:)];
	
	[itemGroup setLayout: [ETTableLayout layoutWithObjectGraphContext: [itemGroup objectGraphContext]]];

	ETLayoutItemGroup *newItemGroup = [itemGroup copy];
	// FIXME: Implement decorator serialization
	[itemGroup setDecoratorItem: [ETDecoratorItem itemWithDummySupervisorView]];
	[newItemGroup setDecoratorItem: [ETDecoratorItem itemWithDummySupervisorView]];

	NSArray *properties = [self checkablePropertiesForItem: itemGroup];
	NSArray *nilProperties = [[self basicNilItemProperties] 
		arrayByAddingObjectsFromArray: A(kETDoubleClickedItemProperty,  @"doubleAction")];
	NSArray *nonIdenticalProperties = [self nonIdenticalItemProperties];
	NSArray *nonEqualOrIdenticalProperties = [[self nonEqualItemGroupProperties] 
		arrayByAddingObjectsFromArray: nonIdenticalProperties];
	NSArray *equalProperties = [properties arrayByRemovingObjectsInArray: 
		[nonEqualOrIdenticalProperties arrayByAddingObjectsFromArray: nilProperties]];

	equalProperties = [equalProperties arrayByRemovingObjectsInArray: A(kETSourceProperty)];
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

		UKPropertiesEqual(value, copiedValue, property);
	}

	UKObjectsEqual(newItemGroup, [newItemGroup source]);
	UKObjectsEqual(newItemGroup, [[newItemGroup layout] layoutContext]);
	UKObjectsNotEqual([[itemGroup layout] layoutView], [[newItemGroup layout] layoutView]);
	UKObjectsEqual([[newItemGroup supervisorView] contentView], [[newItemGroup layout] layoutView]);
	UKObjectsEqual([newItemGroup supervisorView], [[[newItemGroup layout] layoutView] superview]);

	RELEASE(newItemGroup);
}

- (void) testBasicItemGroupCopyWithOutlineLayout
{
	ETLayoutItemGroup *itemGroup1 = [itemFactory itemGroup];

	[itemGroup addItem: item];
	[itemGroup addItem: itemGroup1];

	[itemGroup setLayout: [ETOutlineLayout layoutWithObjectGraphContext: [itemGroup objectGraphContext]]];

	ETLayoutItemGroup *newItemGroup = [itemGroup copy];

	UKIntsEqual(2, [newItemGroup numberOfItems]);
	UKObjectsEqual(newItemGroup, [[newItemGroup itemAtIndex: 1] parentItem]);
	UKObjectsEqual(newItemGroup, [[newItemGroup itemAtIndex: 0] parentItem]);
	UKObjectsEqual([NSIndexPath indexPathWithIndex: 0], [[newItemGroup itemAtIndex: 0] indexPath]);
	UKObjectsEqual([NSIndexPath indexPathWithIndex: 1], [[newItemGroup itemAtIndex: 1] indexPath]);

	[[ETLayoutExecutor sharedInstance] execute];

	UKIntsEqual(2, [[(ETOutlineLayout *)[newItemGroup layout] outlineView] numberOfRows]);

	RELEASE(newItemGroup);
}

#define IPATH(x) [NSIndexPath indexPathWithString: x]

- (void) testItemTreeCopy
{
	ETLayoutItemGroup *itemGroup1 = [itemFactory itemGroup];
	ETLayoutItemGroup *itemGroup10 = [itemFactory itemGroup];
	ETLayoutItem *item100 = [itemFactory item];
	ETLayoutItem *item101 = [itemFactory item];
	ETLayoutItemGroup *itemGroup2 = [itemFactory itemGroup];
	ETLayoutItemGroup *itemGroup20 = [itemFactory itemGroup];
	ETLayoutItem *item3 = [itemFactory button];

	[itemGroup addItem: item];
	[itemGroup addItem: itemGroup1];
	[itemGroup1 addItem: itemGroup10];
	[itemGroup10 addItem: item100];
	[itemGroup10 addItem: item101];
	[itemGroup addItem: itemGroup2];
	[itemGroup2 addItem: itemGroup20];
	/* Create a superview hierarchy from item3 to itemGroup */
	[itemGroup addItem: item3];

	/* Layout view insertion doesn't call -handleAttachViewOfItem:, the 
	   superview is nil until a layout update occurs. */
	[itemGroup2 setLayout: [ETOutlineLayout layoutWithObjectGraphContext: [itemGroup2 objectGraphContext]]];
	
	/* We must update the layouts to mark the items as visible, otherwise 
	   -setVisibleItems:forItems: in -deepCopy does not recreate the view hierarchy. */
	[itemGroup updateLayoutRecursively: YES];

	ETLayoutItemGroup *newItemGroup = [itemGroup copy];

	UKIntsEqual(4, [newItemGroup numberOfItems]);
	UKIntsEqual(1, [(id)[newItemGroup itemAtIndex: 1] numberOfItems]);
	UKIntsEqual(2, [(id)[newItemGroup itemAtIndexPath: IPATH(@"1.0")] numberOfItems]);
	UKIntsEqual(1, [(id)[newItemGroup itemAtIndex: 2] numberOfItems]);
	UKIntsEqual(0, [(id)[newItemGroup itemAtIndexPath: IPATH(@"2.0")] numberOfItems]);

	ETOutlineLayout *layoutCopy = (ETOutlineLayout *)[[newItemGroup itemAtIndex: 2] layout];

	[[ETLayoutExecutor sharedInstance] execute];

	UKIntsEqual(1, [[layoutCopy outlineView] numberOfRows]);

	UKNotNil([newItemGroup supervisorView]);
	UKNil([[newItemGroup itemAtIndex: 1] supervisorView]);
	UKNil([[newItemGroup itemAtIndexPath: IPATH(@"1.0")] supervisorView]);
	UKNil([[newItemGroup itemAtIndexPath: IPATH(@"1.0.0")] supervisorView]);
	UKNil([[newItemGroup itemAtIndexPath: IPATH(@"1.0.1")] supervisorView]);
	UKNotNil([[newItemGroup itemAtIndex: 2] supervisorView]);
	UKNil([[newItemGroup itemAtIndexPath: IPATH(@"2.0")] supervisorView]);
	UKNotNil([[newItemGroup itemAtIndex: 3] supervisorView]);

	NSMutableArray *allNewItems = [NSMutableArray arrayWithArray: [newItemGroup items]];
	[[allNewItems filter] isNotVisible];
	// FIXME: UKObjectsEqual(A(itemGroup20), allNewItems);

	ETLayoutItem *newOutlineItem = [newItemGroup itemAtIndex: 2] ;
	ETLayoutItem *newButtonItem = [newItemGroup itemAtIndex: 3];

	UKObjectsEqual([newItemGroup supervisorView], [[newOutlineItem supervisorView] superview]);
	UKObjectsEqual([newItemGroup supervisorView], [[newButtonItem supervisorView] superview]);

	RELEASE(newItemGroup);
}

// NOTE: Test ETTemplateItemLayout copying at the same time.
- (void) testIconLayoutCopy
{
	ETLayoutItemGroup *itemGroup1 = [itemFactory itemGroup];
	ETIconLayout *layout = [ETIconLayout layoutWithObjectGraphContext: [itemGroup objectGraphContext]];

	[itemGroup addItem: item];
	[itemGroup addItem: itemGroup1];
	[itemGroup setLayout: layout];
	[itemGroup updateLayoutIfNeeded];

	ETLayoutItemGroup *newItemGroup = [itemGroup copy];
	ETIconLayout *layoutCopy = (id)[newItemGroup layout];

	UKObjectKindOf([layoutCopy positionalLayout], ETFlowLayout);
	UKNotNil([layoutCopy templateItem]);
	UKObjectsEqual([layout templateKeys], [layoutCopy templateKeys]);
	UKObjectsEqual(S([newItemGroup firstItem], [newItemGroup lastItem]), [layoutCopy renderedItems]);

	UKIntsEqual(2, [newItemGroup numberOfItems]);
	/*UKNotNil([[newItemGroup firstItem] view]);
	UKNotNil([[newItemGroup firstItem] view]);
	UKObjectsEqual([[newItemGroup firstItem] supervisorView], [[[newItemGroup firstItem] view] superview]);
	UKObjectsEqual([newItemGroup supervisorView], [[[newItemGroup firstItem] supervisorView] superview]);*/
	/* This test requires the items to be resized otherwise -setVisibleItems: 
	   receives an empty array in -renderXXX. */
	//UKObjectsEqual([newItemGroup supervisorView], [[[newItemGroup firstItem] supervisorView] superview]);

	RELEASE(newItemGroup);
}

#if 0
// NOTE: Test ETCompositeLayout and ETPaneLayout copying at the same time.
- (void) testMasterDetailPaneLayoutCopy
{
	ETLayoutItemGroup *itemGroup1 = [itemFactory itemGroup];
	ETLayoutItem *item1 = [itemFactory item];
	ETPaneLayout *layout =
		[ETPaneLayout masterDetailLayoutWithObjectGraphContext: [itemFactory objectGraphContext]];

	/* We set icons to prevent warnings by -visitedItemProxyForItem: */
	[[A(item, item1, itemGroup1) mappedCollection] setIcon: [NSImage imageNamed: @"NSApplicationIcon"]];

	[item setName: @"Ubiquity"];
	[item1 setName: @"Hilarity"];
	[itemGroup addItem: item];
	[itemGroup addItem: item1];
	[itemGroup addItem: itemGroup1];
	[itemGroup setLayout: layout];
	[itemGroup updateLayoutIfNeeded];

	ETLayoutItemGroup *newItemGroup = [itemGroup copy];
	ETPaneLayout *layoutCopy = (id)[newItemGroup layout];

	UKNotNil([layoutCopy barItem]);
	UKNotNil([layoutCopy contentItem]);
	UKObjectsNotEqual([layout barItem], [layoutCopy barItem]);
	UKObjectsNotEqual([layout contentItem], [layoutCopy contentItem]);

	/* Fairly similar to -[TestPaneLayout testInit] except the layout is in use 
	   with the root item children injected into the layout context. */
	UKTrue([[[layoutCopy rootItem] items] isEmpty]);
	UKObjectsEqual(S([layoutCopy barItem], [layoutCopy contentItem]), SA([[layoutCopy layoutContext] items]));
	UKObjectsEqual([layoutCopy firstPresentationItem], [layoutCopy barItem]);

	/* Fairly similar to -[TestPaneLayout testSetUpLayout/testUpdateLayout] */
	UKIntsEqual(3, [[layoutCopy barItem] numberOfItems]);
	// FIXME: ETLayoutItem.representedObject doesn't support object substitution
    // based on the COCopier mapping.
    //UKObjectsEqual([[layoutCopy contentItem] firstItem], [[[layoutCopy barItem] firstItem] representedObject]);
	UKStringsEqual(@"Hilarity", [[[layoutCopy barItem] itemAtIndex: 1] name]);
	UKIntsEqual(1, [[layoutCopy contentItem] numberOfItems]);
	UKStringsEqual(@"Ubiquity", [[[layoutCopy contentItem] firstItem] name]);
	UKObjectsEqual([layoutCopy contentItem], [[[layoutCopy contentItem] firstItem] parentItem]);

	RELEASE(newItemGroup);
}
#endif

@end

