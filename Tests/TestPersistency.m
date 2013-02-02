/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
    License:  Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"

#ifdef COREOBJECT

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETPropertyViewpoint.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <CoreObject/COEditingContext.h>
#import <CoreObject/COObject.h>
#import <CoreObject/COPersistentRoot.h>
#import <CoreObject/COSQLStore.h>
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

- (NSURL *)storeURL
{
	return [NSURL fileURLWithPath: [@"~/TestEtoileUIStore.sqlite" stringByExpandingTildeInPath]];
}

- (void)deleteStore
{
	if ([[NSFileManager defaultManager] fileExistsAtPath: [[self storeURL] path]] == NO)
		return;
	
	NSError *error = nil;
	[[NSFileManager defaultManager] removeItemAtPath: [[self storeURL] path]
	                                           error: &error];
	ETAssert(error == nil);
}

- (id) init
{
	SUPERINIT
	/* Delete existing db file in case -dealloc didn't run */
	[self deleteStore];
	[[ETLayoutExecutor sharedInstance] removeAllItems];
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	/* Just to ensure COREOBJECT preprocessor macro gives us the correct base class (see ETUIObject.h) */
	ETAssert([[[ETUIObject class] superclass] isEqual: [COObject class]]);
	return self;
}

- (void)dealloc
{
	DESTROY(itemFactory);
	[self deleteStore];
	[super dealloc];
}

- (COEditingContext *) createContext
{
	COStore *store = [[COSQLStore alloc] initWithURL: [self storeURL]];
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

	UKObjectsSame(ctxt, [[obj persistentRoot] parentContext]);
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
	ETUUID *uuid = [[ctxt insertNewPersistentRootWithRootObject: shape] persistentRootUUID];

	UKNotNil(uuid);

	[self checkValidityForNewPersistentObject: shape isFault: NO];

	[ctxt commit];
	[self recreateContext];

	ETShape *shape2 = [[ctxt persistentRootForUUID: uuid] rootObject];

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

	[itemFactory beginRootObject];

	NSRect rect = NSMakeRect(50, 20, 400, 300);
	ETLayoutItem *item = [itemFactory item];
	[item setFrame: rect];

	[itemFactory endRootObject];

	NSSet *itemAndAspects = S(item, [item actionHandler], [item styleGroup], [item coverStyle]);
	ETUUID *uuid = [[ctxt insertNewPersistentRootWithRootObject: item] persistentRootUUID];

	UKNotNil(uuid);
	UKObjectsEqual(itemAndAspects, [[item persistentRoot] insertedObjects]);

	[self checkValidityForNewPersistentObject: item isFault: NO];

	[ctxt commit];
	[self recreateContext];

	ETLayoutItem *newItem = [[ctxt persistentRootForUUID: uuid] rootObject];

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

	ETUUID *uuid = [[ctxt insertNewPersistentRootWithRootObject: itemGroup] persistentRootUUID];
	
	UKNotNil(uuid);

	[self checkValidityForNewPersistentObject: itemGroup isFault: NO];
	[self checkValidityForNewPersistentObject: item isFault: NO];
	[self checkValidityForNewPersistentObject: controller isFault: NO];

	[ctxt commit];
	[self recreateContext];

	ETLayoutItemGroup *newItemGroup = [[ctxt persistentRootForUUID: uuid] rootObject];
	ETLayoutItem *newItem = (id)[[newItemGroup persistentRoot] objectWithUUID: [item UUID]];
	ETController *newController = (id)[[newItemGroup persistentRoot] objectWithUUID: [controller UUID]];

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

- (void) testWidgetItemPersistency
{
	[self recreateContext];

	NSRect rect = NSMakeRect(50, 20, 400, 300);
	
	[itemFactory beginRootObject];

	ETLayoutItem *sliderItem = [itemFactory horizontalSlider];
	ETLayoutItem *buttonItem = [itemFactory buttonWithTitle: @"Picturesque" 
	                                           target: [sliderItem view] 
	                                           action: @selector(print:)];
	ETLayoutItemGroup *itemGroup = [itemFactory itemGroupWithItems: A(buttonItem, sliderItem)];

	[[sliderItem view] setAction: @selector(close:)];
	[[sliderItem view] setTarget: itemGroup];
	[buttonItem setFrame: rect];
	
	[itemFactory endRootObject];

	UKNotNil([buttonItem UUID]);
	UKNotNil([sliderItem UUID]);
	UKNotNil([itemGroup UUID]);

	ETUUID *uuid = [[ctxt insertNewPersistentRootWithRootObject: itemGroup] persistentRootUUID];

	[self checkValidityForNewPersistentObject: buttonItem isFault: NO];
	[self checkValidityForNewPersistentObject: sliderItem isFault: NO];
	[self checkValidityForNewPersistentObject: itemGroup isFault: NO];

	[ctxt commit];
	[self recreateContext];

	ETLayoutItem *newItemGroup = (id)[[ctxt persistentRootForUUID: uuid] rootObject];
	ETLayoutItem *newButtonItem = (id)[[newItemGroup persistentRoot] objectWithUUID: [buttonItem UUID]];
	ETLayoutItem *newSliderItem = (id)[[newItemGroup persistentRoot] objectWithUUID: [sliderItem UUID]];

	UKNotNil(newButtonItem);
	UKObjectsNotSame(buttonItem, newButtonItem);
	UKObjectKindOf([newButtonItem view], NSButton);
	UKRectsEqual(rect, [newButtonItem frame]);
	UKStringsEqual(@"Picturesque", [[newButtonItem view] title]);
	UKObjectsEqual([newSliderItem view], [[newButtonItem view] target]);
	UKTrue(@selector(print:) == [[newButtonItem view] action]);

	UKNotNil(newSliderItem);
	UKObjectsNotSame(sliderItem, newSliderItem);
	UKObjectKindOf([newSliderItem view], NSSlider);
	UKRectsNotEqual(rect, [newSliderItem frame]);
	UKObjectsEqual(newItemGroup, [[newSliderItem view] target]);
	UKTrue(@selector(close:) == [[newSliderItem view] action]);

	[self checkValidityForNewPersistentObject: newButtonItem isFault: NO];
	[self checkValidityForNewPersistentObject: newSliderItem isFault: NO];
	[self checkValidityForNewPersistentObject: newItemGroup isFault: NO];
}

- (void) testItemGroupUndoRedo
{
	[self recreateContext];

	NSRect rect = NSMakeRect(50, 20, 400, 300);
	ETLayoutItemGroup *itemGroup = [self basicItemGroupWithRect: rect];
	ETLayoutItem *item = [itemGroup firstItem];

	[[ctxt insertNewPersistentRootWithRootObject: itemGroup] persistentRootUUID];
	[ctxt commit];

	// Create a rectangle and commit
	[[itemGroup actionHandler] insertRectangle: nil onItem: itemGroup];

	ETLayoutItem *rectItem = [itemGroup lastItem];

	[self checkValidityForNewPersistentObject: rectItem isFault: NO];

	[[itemGroup commitTrack] undo];

	UKIntsEqual(1, [itemGroup numberOfItems]);
	UKObjectsSame([itemGroup lastItem], item);

	[[itemGroup commitTrack] redo];

	UKIntsEqual(2, [itemGroup numberOfItems]);
	UKObjectsNotSame([itemGroup lastItem], rectItem);
	UKObjectsEqual([[itemGroup lastItem] UUID], [rectItem UUID]);
}

@end

#endif
