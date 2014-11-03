/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
    License:  Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"
#import <objc/runtime.h>
#import <EtoileFoundation/ETViewpoint.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <CoreObject/COBranch.h>
#import <CoreObject/COEditingContext.h>
#import <CoreObject/COEditingContext+Debugging.h>
#import <CoreObject/COObject.h>
#import <CoreObject/COObjectGraphContext.h>
#import <CoreObject/COObjectGraphContext+Debugging.h>
#import <CoreObject/COPersistentRoot.h>
#import <CoreObject/COSQLiteStore.h>
#import <CoreObject/COSerialization.h>
#import "TestCommon.h"
#import "EtoileUIProperties.h"
#import "ETActionHandler.h"
#import "ETBasicItemStyle.h"
#import "ETController.h"
#import "ETGeometry.h"
#import "ETFreeLayout.h"
#import "ETItemTemplate.h"
#import "ETLayoutExecutor.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETSelectTool.h"
#import "ETStyle.h"
#import "ETShape.h"

@interface COObject (TestPersistency)
- (id)roundTripValueForArchivedProperty: (NSString *)key;
@end

@interface COObjectGraphContext (TestPersistency)
- (NSArray *)itemsForUUIDs: (NSArray *)itemUUIDs;
@end

@implementation COObject (TestPersistency)

- (id)roundTripValueForArchivedProperty: (NSString *)key
{
	NSData *data = [self roundTripValueForProperty: key];
	return (data != nil ? [NSKeyedUnarchiver unarchiveObjectWithData: data] : data);
}

@end

@implementation COObjectGraphContext (TestPersistency)

- (NSArray *)itemsForUUIDs: (NSArray *)itemUUIDs
{
    NSMutableArray *items = [NSMutableArray arrayWithCapacity: [itemUUIDs count]];

    for (ETUUID *UUID in itemUUIDs)
    {
        [items addObject: [self itemForUUID: UUID]];
    }
    return items;
}

@end

@interface TestItemPersistency : TestCommon <UKTest>
{
    ETLayoutItem *item;
    ETLayoutItemGroup *itemGroup;
}

@end

@implementation TestItemPersistency

- (id) init
{
	SUPERINIT;
    ASSIGN(itemFactory, [ETLayoutItemFactory factoryWithObjectGraphContext:
        [COObjectGraphContext objectGraphContext]]);

    ASSIGN(item, [itemFactory item]);
    ASSIGN(itemGroup, [itemFactory itemGroupWithItems: A(item)]);

    //[itemGroup setFrame: NSMakeRect(50, 20, 400, 300)];
    [itemGroup setShouldMutateRepresentedObject: YES];

    ETAssert([item objectGraphContext] != [ETUIObject defaultTransientObjectGraphContext]);
    ETAssert([[item objectGraphContext] rootItemUUID] == nil);
    ETAssert([itemGroup objectGraphContext] != [ETUIObject defaultTransientObjectGraphContext]);
    ETAssert([[itemGroup objectGraphContext] rootItemUUID] == nil);
	return self;
}

- (void)dealloc
{
    DESTROY(item);
    DESTROY(itemGroup);
	[super dealloc];
}

- (NSBezierPath *) resizedPathWithRect: (NSRect)rect
{
	return nil;
}

- (void) testInsertedObjects
{
    NSSet *itemAndAspects = S(item, [item actionHandler], [item styleGroup], [item coverStyle],
        itemGroup, [itemGroup styleGroup], [itemGroup layout], [[itemGroup layout] dropIndicator]);
    COObjectGraphContext *oldContext = [item objectGraphContext];

    UKObjectsEqual(itemAndAspects, SA([oldContext insertedObjects]));
    UKTrue([[oldContext updatedObjects] isEmpty]);
    
    COObjectGraphContext *newContext = [COObjectGraphContext objectGraphContext];
    [newContext insertOrUpdateItems: [oldContext itemsForUUIDs: [oldContext itemUUIDs]]];

    // FIXME: -inserted/updated/changedObjectUUIDs should be renamed to
    // -inserted/updated/changedItemUUIDs and
    // -inserted/updated/changed/loadedObjects changed to skip the object lookup
    // for UUIDs bound to additional items.
    //UKCollectionUUIDsEqual(itemAndAspects, SA([newContext insertedObjects]));
    UKTrue([[newContext updatedObjects] isEmpty]);
}

- (void) testBasicItemSerialization
{
	UKRectsEqual([item contentBounds], [[item roundTripValueForProperty: @"contentBounds"] rectValue]);
	UKPointsEqual([item position], [[item roundTripValueForProperty: @"position"] pointValue]);
}

- (void) testBasicItemPersistency
{
	// NOTE: The item must be a root object (i.e. belong to a persistent root)
	// to be inserted in the in the window group. Cross persistent root
	// references must point to valid root objects (the item object graph
	// context is initially transient and thereby without a root object).
    [[item objectGraphContext] setRootObject: item];
	[[itemFactory windowGroup] addItem: item];

    [self checkWithExistingAndNewRootObject: item
                                    inBlock: ^ (ETLayoutItem *newItem, BOOL isNew, BOOL isCopy)
    {
        UKFalse([[itemFactory windowGroup] isPersistent]);

        UKValidateLoadedObjects(newItem, item, NO);
        
        UKRectsEqual([item contentBounds], [newItem contentBounds]);
        UKPointsEqual([item position], [newItem position]);
        UKPointsEqual([item anchorPoint], [newItem anchorPoint]);

        if (isNew || isCopy)
        {
            UKNil([newItem parentItem]);

            [[itemFactory windowGroup] addItem: newItem];
            UKRectsEqual([item frame], [newItem frame]);
            [[itemFactory windowGroup] removeItem: newItem];
        }
    }];

	[[itemFactory windowGroup] removeItem: item];
}

- (void) testBasicItemGroupSerialization
{
	UKRectsEqual([itemGroup contentBounds], [[itemGroup roundTripValueForProperty: @"contentBounds"] rectValue]);
	UKPointsEqual([itemGroup position], [[itemGroup roundTripValueForProperty: @"position"] pointValue]);
	UKTrue([[itemGroup roundTripValueForProperty: @"shouldMutateRepresentedObject"] boolValue]);
}

- (void) testBasicItemGroupPersistency
{
    ETController *controller = AUTORELEASE([[ETController alloc]
         initWithObjectGraphContext: [itemFactory objectGraphContext]]);

    [itemGroup setController: controller];
    
    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^ (ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETLayoutItem *newItem = [newItemGroup firstItem];
        ETController *newController = [newItemGroup controller];

        UKValidateLoadedObjects(newItemGroup, itemGroup, NO);
        UKValidateLoadedObjects(newItem, item, NO);
        UKValidateLoadedObjects(newController, controller, NO);

        UKRectsEqual([itemGroup contentBounds], [newItemGroup contentBounds]);
        UKPointsEqual([itemGroup position], [newItemGroup position]);
        UKPointsEqual([itemGroup anchorPoint], [newItemGroup anchorPoint]);
        UKRectsEqual([itemGroup frame], [newItemGroup frame]);

        UKObjectsEqual(A(newItem), [newItemGroup items]);
        UKObjectsEqual(A(newItem), [newItemGroup arrangedItems]);

        UKRectsEqual([item contentBounds], [newItem contentBounds]);
        UKPointsEqual([item position], [newItem position]);
        UKPointsEqual([item anchorPoint], [newItem anchorPoint]);
        UKRectsEqual([item frame], [newItem frame]);
    }];
}

- (void) testViewRoundtrip
{
	ETLayoutItem *textFieldItem = [itemFactory textField];
	NSView *newView = [textFieldItem roundTripValueForArchivedProperty: kETViewProperty];

	UKNil([newView superview]);
}

- (void) testWidgetItemPersistency
{
    NSRect rect = NSMakeRect(50, 20, 400, 300);
	ETLayoutItem *sliderItem = [itemFactory horizontalSlider];
	ETLayoutItem *buttonItem = [itemFactory buttonWithTitle: @"Picturesque" 
	                                                 target: [sliderItem view]
	                                                 action: @selector(print:)];
	
    [itemGroup addItems: A(sliderItem, buttonItem)];

	[[sliderItem view] setAction: @selector(close:)];
	[[sliderItem view] setTarget: itemGroup];
    
    [buttonItem setFrame: rect];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^ (ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETLayoutItem *newSliderItem = [newItemGroup itemAtIndex: 1];
        ETLayoutItem *newButtonItem = [newItemGroup lastItem];

        UKValidateLoadedObjects(newButtonItem, buttonItem, NO);
        UKValidateLoadedObjects(newSliderItem, sliderItem, NO);
    
        UKObjectKindOf([newButtonItem view], NSButton);
        UKRectsEqual(rect, [newButtonItem frame]);
        UKRectsEqual(ETMakeRect(NSZeroPoint, rect.size), [[newButtonItem view] frame]);
        UKStringsEqual(@"Picturesque", [[newButtonItem view] title]);
        // FIXME: UKObjectsEqual([newSliderItem view], [[newButtonItem view] target]);
        UKTrue(sel_isEqual(@selector(print:), [[newButtonItem view] action]));

        UKObjectKindOf([newSliderItem view], NSSlider);
        UKRectsNotEqual(rect, [newSliderItem frame]);
        UKRectsEqual([[sliderItem view] frame], [[newSliderItem view] frame]);
        // FIXME: UKObjectsEqual(newItemGroup, [[newSliderItem view] target]);
        UKTrue(sel_isEqual(@selector(close:), [[newSliderItem view] action]));
    }];
}

// TODO: Improve to test geometry issues more exhaustively and be less verbose
- (void) testResizeWidgetItem
{
	NSRect rect = NSMakeRect(50, 20, 400, 300);
	ETLayoutItem *buttonItem = [itemFactory buttonWithTitle: @"Picturesque"
													 target: nil
													 action: @selector(print:)];

    [itemGroup addItem: buttonItem];
	[buttonItem setFrame: rect];
	
    // First commit
    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^ (ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETLayoutItem *newButtonItem = [newItemGroup lastItem];
        
        UKSizesEqual(rect.size, [newButtonItem size]);
    }];

	NSSize lastSize = NSMakeSize(100, 400);
	
	[buttonItem setSize: lastSize];

    // Second commit
    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^ (ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETLayoutItem *newButtonItem = [newItemGroup lastItem];

        UKRectsEqual(ETMakeRect(rect.origin, lastSize), [newButtonItem frame]);
        UKRectsEqual(ETMakeRect(NSZeroPoint, lastSize), [[newButtonItem view] frame]);
    }];
}

- (void) testItemGroupUndoRedo
{
	COPersistentRoot *persistentRoot =
        [editingContext insertNewPersistentRootWithRootObject: itemGroup];
    ETAssert([itemGroup branch] == [persistentRoot currentBranch]);

    // First commit
	ETAssert([persistentRoot commit]);

    // Second commit
	[[itemGroup actionHandler] insertRectangle: nil
                                        onItem: itemGroup];

	ETLayoutItem *rectItem = [itemGroup lastItem];

	[[persistentRoot currentBranch] undo];

	UKIntsEqual(1, [itemGroup numberOfItems]);
	UKObjectsSame([itemGroup lastItem], item);

	[[persistentRoot currentBranch] redo];

	UKIntsEqual(2, [itemGroup numberOfItems]);
	UKObjectsNotSame([itemGroup lastItem], rectItem);
	UKObjectUUIDsEqual([itemGroup lastItem], rectItem);
}

@end
