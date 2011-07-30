/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
    License:  Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"

#ifdef OBJECTMERGING

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETPropertyViewpoint.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <ObjectMerging/COEditingContext.h>
#import <ObjectMerging/COObject.h>
#import <ObjectMerging/COStore.h>
#import "ETActionHandler.h"
#import "ETController.h"
#import "ETLayoutExecutor.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETStyle.h"
#import "ETShape.h"

#define UKRectsEqual(x, y) UKTrue(NSEqualRects(x, y))
#define UKRectsNotEqual(x, y) UKFalse(NSEqualRects(x, y))
#define UKPointsEqual(x, y) UKTrue(NSEqualPoints(x, y))
#define UKPointsNotEqual(x, y) UKFalse(NSEqualPoints(x, y))
#define UKSizesEqual(x, y) UKTrue(NSEqualSizes(x, y))

@interface TestPersistency : NSObject <UKTest>
{
	COEditingContext *ctxt;
	ETLayoutItemFactory *itemFactory;
}

@end

@implementation TestPersistency

- (id) init
{
	SUPERINIT
	[[ETLayoutExecutor sharedInstance] removeAllItems];
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	return self;
}

DEALLOC(DESTROY(itemFactory);)

- (COEditingContext *) createContext
{
	COStore *store = [[COStore alloc] initWithURL: [NSURL fileURLWithPath: 
		[@"~/TestEtoileUIStore.sqlitedb" stringByExpandingTildeInPath]]];
	COEditingContext *context = [[COEditingContext alloc] initWithStore: store];
	RELEASE(store);
	return context;
}

- (void) recreateContext
{
	DESTROY(ctxt);
	ctxt = [self createContext];
}

- (void) checkValidityForNewPersistentObject: (COObject *)obj isFault: (BOOL)isFault
{
	UKTrue([obj isPersistent]);
	UKNotNil([obj entityDescription]);
	UKTrue([obj isFault] == isFault);
	//UKFalse([obj isRoot]);
	UKFalse([obj isDamaged]);

	UKObjectsSame(ctxt, [obj editingContext]);
	UKTrue([[ctxt loadedObjects] containsObject: obj]);
	UKObjectsSame(obj, [ctxt objectWithUUID: [obj UUID]]);
}

- (NSBezierPath *) resizedPathWithRect: (NSRect)rect
{
	return nil;
}

- (void) testBasicShapeSerialization
{
	NSRect rect = NSMakeRect(50, 20, 400, 300);
	ETShape *shape = [ETShape rectangleShapeWithRect: rect];

	[shape setPathResizeSelector: @selector(resizedPathWithRect:)];
	[shape setFillColor: [NSColor redColor]];
	[shape setStrokeColor: nil];
	[shape setAlphaValue: 0.4];
	[shape setHidden: YES];

	UKRectsEqual(rect, [[shape roundTripValueForProperty: @"bounds"] rectValue]);
	// FIXME: KVC doesn't support selector boxing into NSValue
	//UKTrue(sel_isEqual(@selector(resizedPathWithRect:), 
	//	(SEL)[[shape roundTripValueForProperty: @"pathResizeSelector"] pointerValue]));
	UKObjectsEqual([NSColor redColor], [shape roundTripValueForProperty: @"fillColor"]);
	UKNil([shape roundTripValueForProperty: @"strokeColor"]);
	UKTrue([[shape roundTripValueForProperty: @"hidden"] boolValue]);
}

- (void) testBasicShapePersistency
{
	[self recreateContext];

	NSRect rect = NSMakeRect(50, 20, 400, 300);
	ETShape *shape = [ETShape rectangleShapeWithRect: rect];
	ETUUID *uuid = [shape UUID];

	UKNotNil(uuid);

	[shape becomePersistentInContext: ctxt rootObject: shape];
	[self checkValidityForNewPersistentObject: shape isFault: NO];

	[ctxt commit];
	[self recreateContext];

	ETShape *shape2 = (id)[ctxt objectWithUUID: uuid];

	UKNotNil(shape2);
	UKObjectsNotSame(shape, shape2);
	UKRectsEqual(rect, [shape2 bounds]);

	[self checkValidityForNewPersistentObject: shape2 isFault: NO];
}

- (ETLayoutItem *) basicItemWithRect: (NSRect)rect
{
	ETLayoutItem *item = [itemFactory item];

	[item setFrame: rect];
	[item setCoverStyle: [ETShape rectangleShape]];
	[[item coverStyle] setFillColor: [NSColor redColor]];

	return item;
}

- (void) testBasicItemSerialization
{
	NSRect rect = NSMakeRect(50, 20, 400, 300);
	ETLayoutItem *item = [self basicItemWithRect: rect];

	UKSizesEqual(rect.size, [[item roundTripValueForProperty: @"contentBounds"] rectValue].size);
	UKPointsEqual([item position], [[item roundTripValueForProperty: @"position"] pointValue]);
	//UKObjectsEqual([NSColor redColor], [[item roundTripValueForProperty: @"coverStyle"] fillColor]);
}

- (void) testBasicItemPersistency
{
	[self recreateContext];

	NSRect rect = NSMakeRect(50, 20, 400, 300);
	ETLayoutItem *item = [itemFactory item];
	[item setFrame: rect];
	ETUUID *uuid = [item UUID];

	UKNotNil(uuid);

	[item becomePersistentInContext: ctxt rootObject: item];
	[self checkValidityForNewPersistentObject: item isFault: NO];

	[ctxt commit];
	[self recreateContext];

	ETLayoutItem *newItem = (id)[ctxt objectWithUUID: uuid];

	UKNotNil(newItem);
	UKObjectsNotSame(item, newItem);
	UKRectsEqual([item contentBounds], [newItem contentBounds]);
	UKPointsEqual([item position], [newItem position]);
	UKPointsEqual([item anchorPoint], [newItem anchorPoint]);
	UKRectsEqual([item frame], [newItem frame]);

	[self checkValidityForNewPersistentObject: newItem isFault: NO];
}

- (ETLayoutItemGroup *) basicItemGroupWithRect: (NSRect)rect
{
	[itemFactory beginRootObject];

	ETLayoutItem *item = [self basicItemWithRect: NSMakeRect(10, 10, 50, 50)];
	ETLayoutItemGroup *itemGroup = [itemFactory itemGroupWithItems: A(item)];
	ETController *controller = AUTORELEASE([[ETController alloc] init]);

	[itemGroup setFrame: rect];
	[itemGroup setShouldMutateRepresentedObject: YES];
	[itemGroup setController: controller];

	[itemFactory endRootObject];

	return itemGroup;
}

- (void) testBasicItemGroupSerialization
{
	NSRect rect = NSMakeRect(50, 20, 400, 300);
	ETLayoutItemGroup *itemGroup = [self basicItemGroupWithRect: rect];

	UKSizesEqual(rect.size, [[itemGroup roundTripValueForProperty: @"contentBounds"] rectValue].size);
	UKPointsEqual([itemGroup position], [[itemGroup roundTripValueForProperty: @"position"] pointValue]);
	UKTrue([[itemGroup roundTripValueForProperty: @"shouldMutateRepresentedObject"] boolValue]);
}

- (void) testBasicItemGroupPersistency
{
	[self recreateContext];

	NSRect rect = NSMakeRect(50, 20, 400, 300);
	ETLayoutItemGroup *itemGroup = [self basicItemGroupWithRect: rect];
	ETLayoutItem *item = [itemGroup firstItem];
	ETController *controller = [itemGroup controller];

	ETUUID *uuid = [itemGroup UUID];

	UKNotNil(uuid);
	UKNotNil([item UUID]);

	[itemGroup becomePersistentInContext: ctxt rootObject: itemGroup];
	[self checkValidityForNewPersistentObject: itemGroup isFault: NO];
	[self checkValidityForNewPersistentObject: item isFault: NO];
	[self checkValidityForNewPersistentObject: controller isFault: NO];

	[ctxt commit];
	[self recreateContext];

	ETLayoutItemGroup *newItemGroup = (id)[ctxt objectWithUUID: uuid];
	ETLayoutItem *newItem = (id)[ctxt objectWithUUID: [item UUID]];
	ETController *newController = (id)[ctxt objectWithUUID: [controller UUID]];

	UKNotNil(newItemGroup);
	UKObjectsNotSame(itemGroup, newItemGroup);
	UKRectsEqual([itemGroup contentBounds], [newItemGroup contentBounds]);
	UKPointsEqual([itemGroup position], [newItemGroup position]);
	UKPointsEqual([itemGroup anchorPoint], [newItemGroup anchorPoint]);
	UKRectsEqual([itemGroup frame], [newItemGroup frame]);
	UKObjectsEqual(A(newItem), [newItemGroup items]);
	UKObjectsEqual(newController, [newItemGroup controller]);

	UKNotNil(newController);
	UKObjectsEqual(newItemGroup, [newController content]);

	UKNotNil(newItem);
	UKObjectsNotSame(item, newItem);
	UKRectsEqual([item contentBounds], [newItem contentBounds]);
	UKPointsEqual([item position], [newItem position]);
	UKPointsEqual([item anchorPoint], [newItem anchorPoint]);
	UKRectsEqual([item frame], [newItem frame]);

	[self checkValidityForNewPersistentObject: newItemGroup isFault: NO];
	[self checkValidityForNewPersistentObject: newItem isFault: NO];
	[self checkValidityForNewPersistentObject: newController isFault: NO];
}

@end

#endif
