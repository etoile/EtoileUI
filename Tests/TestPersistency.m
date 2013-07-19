/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2011
    License:  Modified BSD (see COPYING)
 */

#import "ETCompatibility.h"

#ifdef COREOBJECT

#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETViewpoint.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <CoreObject/COEditingContext.h>
#import <CoreObject/COObject.h>
#import <CoreObject/COPersistentRoot.h>
#import <CoreObject/COSQLiteStore.h>
#import <CoreObject/COSerialization.h>
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
	return [NSURL fileURLWithPath: [@"~/TestEtoileUIStore.store" stringByExpandingTildeInPath]];
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
	COSQLiteStore *store = [[COSQLiteStore alloc] initWithURL: [self storeURL]];
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
	//UKFalse([obj isRoot]);
	// FIXME: UKFalse([obj isDamaged]);

	UKObjectsSame(ctxt, [[obj persistentRoot] parentContext]);
	UKTrue([[ctxt loadedObjects] containsObject: obj]);
	UKObjectsSame(obj, [[obj persistentRoot] objectWithUUID: [obj UUID]]);
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

	UKRectsEqual(rect, [[shape roundTripValueForProperty: @"path"] bounds]);
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

- (void) testBasicItemStylePersistency
{
	[self recreateContext];
	
	ETBasicItemStyle *style = [ETBasicItemStyle new];
	
	[style setLabelPosition: ETLabelPositionInsideTop];
	[style setLabelMargin: 5];
	[style setMaxImageSize: NSMakeSize(50, 100)];
	[style setEdgeInset: 10];

	ETUUID *uuid = [[ctxt insertNewPersistentRootWithRootObject: style] persistentRootUUID];

	UKNotNil(uuid);
	
	[self checkValidityForNewPersistentObject: style isFault: NO];
	
	[ctxt commit];
	[self recreateContext];
	
	ETBasicItemStyle *style2 = [[ctxt persistentRootForUUID: uuid] rootObject];
	
	UKNotNil(style2);
	UKObjectsNotSame(style, style2);

	UKIntsEqual(ETLabelPositionInsideTop, [style2 labelPosition]);
	UKIntsEqual(5, [style2 labelMargin]);
	UKSizesEqual([style maxLabelSize], [style2 maxLabelSize]);
	UKSizesEqual(NSMakeSize(50, 100), [style2 maxImageSize]);
	UKIntsEqual(10, [style2 edgeInset]);

	NSRect labelRect = [style2 rectForLabel: @"Whatever"
	                                inFrame: NSMakeRect(0, 0, 200, 20)
	                                 ofItem: [itemFactory item]];
	
	UKTrue(labelRect.size.width > 10);
	/* Font size must be big enough to ensure label height is bigger than 10px */
	UKTrue(labelRect.size.height > 10);

	[self checkValidityForNewPersistentObject: style2 isFault: NO];
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
	[[itemFactory windowGroup] addItem: item];

	CODictionary *valueTransformers = [item primitiveValueForKey: @"valueTransformers"];
	NSSet *itemAndAspects = S(item, [item actionHandler], [item styleGroup], [item coverStyle], valueTransformers);
	ETUUID *uuid = [[ctxt insertNewPersistentRootWithRootObject: item] persistentRootUUID];

	UKNotNil(uuid);
	UKObjectsEqual(itemAndAspects, [[item persistentRoot] insertedObjects]);
	UKTrue([[[item persistentRoot] updatedObjects] isEmpty]);
	UKFalse([[itemFactory windowGroup] isPersistent]);

	[self checkValidityForNewPersistentObject: item isFault: NO];

	[ctxt commit];
	[self recreateContext];

	ETLayoutItem *newItem = [[ctxt persistentRootForUUID: uuid] rootObject];
	
	UKNotNil(newItem);
	UKObjectsNotSame(item, newItem);
	UKNil([newItem parentItem]);
	UKRectsEqual([item contentBounds], [newItem contentBounds]);
	UKPointsEqual([item position], [newItem position]);
	UKPointsEqual([item anchorPoint], [newItem anchorPoint]);
	[[itemFactory windowGroup] addItem: newItem];
	UKRectsEqual([item frame], [newItem frame]);

	[self checkValidityForNewPersistentObject: newItem isFault: NO];
	
	[[itemFactory windowGroup] removeItem: item];
	[[itemFactory windowGroup] removeItem: newItem];
}

#if 0
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
	UKObjectsEqual(A(newItem), [newItemGroup arrangedItems]);
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

- (void) testViewRoundtrip
{
	ETLayoutItem *item = [itemFactory textField];
	NSView *newView = [item roundTripValueForProperty: kETViewProperty];

	UKNil([newView superview]);
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
	UKRectsEqual(ETMakeRect(NSZeroPoint, rect.size), [[newButtonItem view] frame]);
	UKStringsEqual(@"Picturesque", [[newButtonItem view] title]);
	UKObjectsEqual([newSliderItem view], [[newButtonItem view] target]);
	UKTrue(sel_isEqual(@selector(print:), [[newButtonItem view] action]));

	UKNotNil(newSliderItem);
	UKObjectsNotSame(sliderItem, newSliderItem);
	UKObjectKindOf([newSliderItem view], NSSlider);
	UKRectsNotEqual(rect, [newSliderItem frame]);
	//UKRectsEqual(ETMakeRect(NSZeroPoint, rect.size), [[newSliderItem view] frame]);
	UKObjectsEqual(newItemGroup, [[newSliderItem view] target]);
	UKTrue(sel_isEqual(@selector(close:), [[newSliderItem view] action]));

	[self checkValidityForNewPersistentObject: newButtonItem isFault: NO];
	[self checkValidityForNewPersistentObject: newSliderItem isFault: NO];
	[self checkValidityForNewPersistentObject: newItemGroup isFault: NO];
}

// TODO: Improve to test geometry issues more exhaustively and be less verbose
- (void) testResizeWidgetItem
{
	[self recreateContext];
	
	NSRect rect = NSMakeRect(50, 20, 400, 300);
	
	[itemFactory beginRootObject];

	ETLayoutItem *buttonItem = [itemFactory buttonWithTitle: @"Picturesque"
													 target: nil
													 action: @selector(print:)];
	ETLayoutItemGroup *itemGroup = [itemFactory itemGroupWithItem: buttonItem];
	
	[buttonItem setFrame: rect];
	
	[itemFactory endRootObject];
	
	UKNotNil([buttonItem UUID]);
	UKNotNil([itemGroup UUID]);
	
	ETUUID *uuid = [[ctxt insertNewPersistentRootWithRootObject: itemGroup] persistentRootUUID];
	
	[self checkValidityForNewPersistentObject: buttonItem isFault: NO];
	[self checkValidityForNewPersistentObject: itemGroup isFault: NO];
	
	[ctxt commit];
	
	NSSize lastSize = NSMakeSize(100, 400);
	
	[buttonItem setSize: lastSize];

	[ctxt commit];

	[self recreateContext];
	
	ETLayoutItem *newItemGroup = (id)[[ctxt persistentRootForUUID: uuid] rootObject];
	ETLayoutItem *newButtonItem = (id)[[newItemGroup persistentRoot] objectWithUUID: [buttonItem UUID]];
	
	UKRectsEqual(ETMakeRect(rect.origin, lastSize), [newButtonItem frame]);
	UKRectsEqual(ETMakeRect(NSZeroPoint, lastSize), [[newButtonItem view] frame]);

	[self checkValidityForNewPersistentObject: newButtonItem isFault: NO];
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

- (void) testControllerPersistency
{
	[self recreateContext];

	[itemFactory beginRootObject];

	ETLayoutItemGroup *itemGroup = [itemFactory itemGroup];
	ETController *controller = AUTORELEASE([ETController new]);

	[itemGroup setShouldMutateRepresentedObject: YES];
	[itemGroup setController: controller];

	ETItemTemplate *objectTemplate =
		[ETItemTemplate templateWithItem: [itemFactory textField] entityName: @"COBookmark"];
	ETUTI *URLType = [ETUTI typeWithString: @"public.url"];
	ETItemTemplate *groupTemplate =
		[ETItemTemplate templateWithItem: [itemFactory itemGroup] objectClass: [NSMutableArray class]];

	[controller setCurrentObjectType: URLType];
	[controller setTemplate: objectTemplate forType: URLType];
	[controller setTemplate: groupTemplate forType: [controller currentGroupType]];

	NSSortDescriptor *sortDescriptor1 =
		[NSSortDescriptor sortDescriptorWithKey: @"name" ascending: YES];
	NSSortDescriptor *sortDescriptor2 =
		[NSSortDescriptor sortDescriptorWithKey: @"creationDate" ascending: NO selector: @selector(compare:)];
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"URL.absoluteString CONTAINS 'etoile-project.org'"];

	[controller setSortDescriptors: A(sortDescriptor1, sortDescriptor2)];
	[controller setFilterPredicate: predicate];

	[itemFactory endRootObject];

	ETUUID *uuid = [[ctxt insertNewPersistentRootWithRootObject: itemGroup] persistentRootUUID];
	
	UKNotNil(uuid);
	
	[self checkValidityForNewPersistentObject: itemGroup isFault: NO];
	[self checkValidityForNewPersistentObject: controller isFault: NO];
	
	[ctxt commit];
	[self recreateContext];
	
	ETLayoutItemGroup *newItemGroup = [[ctxt persistentRootForUUID: uuid] rootObject];
	ETController *newController = (id)[[newItemGroup persistentRoot] objectWithUUID: [controller UUID]];
	ETItemTemplate *newObjectTemplate = [newController templateForType: URLType];
	ETItemTemplate *newGroupTemplate = [newController templateForType: [newController currentGroupType]];

	UKNotNil(newController);
	UKObjectsEqual(newController, [newItemGroup controller]);
	UKObjectsEqual(newItemGroup, [newController content]);

	UKObjectsEqual(URLType, [newController currentObjectType]);
	UKObjectsEqual([controller currentGroupType], [newController currentGroupType]);
	UKObjectsEqual(objectTemplate, newObjectTemplate);
	UKObjectsEqual(groupTemplate, newGroupTemplate);

	UKObjectKindOf([[newObjectTemplate item] view], NSTextField);
	UKNil([newObjectTemplate objectClass]);
	UKStringsEqual([objectTemplate entityName], [newObjectTemplate entityName]);
	
	UKTrue([[newGroupTemplate item] isGroup]);
	UKTrue([(ETLayoutItemGroup *)[newGroupTemplate item] isEmpty]);
	UKTrue([[newGroupTemplate objectClass] isSubclassOfClass: [NSMutableArray class]]);
	UKNil([newGroupTemplate entityName]);

	UKObjectsEqual(predicate, [newController filterPredicate]);
	UKObjectsEqual(A(sortDescriptor1, sortDescriptor2), [newController sortDescriptors]);
	UKObjectsEqual(predicate, [newController filterPredicate]);

	[self checkValidityForNewPersistentObject: newItemGroup isFault: NO];
	[self checkValidityForNewPersistentObject: newController isFault: NO];
}

- (void) testFreeLayout
{
	[self recreateContext];
	
	[itemFactory beginRootObject];

	ETLayoutItem *item = [self basicItemWithRect: NSMakeRect(10, 10, 50, 50)];
	ETLayoutItem *buttonItem = [itemFactory button];
	ETLayoutItemGroup *itemGroup = [itemFactory itemGroupWithItems: A(item, buttonItem)];

	[itemGroup setLayout: [ETFreeLayout layout]];
	[itemGroup setSelectionIndex: 1];

	[itemFactory endRootObject];

	ETUUID *uuid = [[ctxt insertNewPersistentRootWithRootObject: itemGroup] persistentRootUUID];

	[self checkValidityForNewPersistentObject: buttonItem isFault: NO];
	[self checkValidityForNewPersistentObject: itemGroup isFault: NO];
	[self checkValidityForNewPersistentObject: item isFault: NO];

	[ctxt commit];

	//ETLog(@"Serialized layout: %@", [[itemGroup layout] serializedRepresentation]);

	[self recreateContext];

	ETLayoutItemGroup *newItemGroup = (id)[[ctxt persistentRootForUUID: uuid] rootObject];
	ETLayoutItem *newItem = (id)[[newItemGroup persistentRoot] objectWithUUID: [item UUID]];
	ETLayoutItem *newButtonItem = (id)[[newItemGroup persistentRoot] objectWithUUID: [buttonItem UUID]];

	UKTrue([newButtonItem isSelected]);
	UKIntsEqual(1, [newItemGroup selectionIndex]);
	// FIXME: UKFalse([ctxt hasChanges]);
	UKNotNil([[newItemGroup layout] handleGroupForItem: newButtonItem]);
	UKNil([[newItemGroup layout] handleGroupForItem: newItem]);
	UKIntsEqual(1, [[[newItemGroup layout] layerItem] numberOfItems]);

	UKObjectKindOf([[newItemGroup layout] attachedTool], ETSelectTool);
	UKTrue([[[newItemGroup layout] attachedTool] shouldProduceTranslateActions]);

	[[[newItemGroup layout] attachedTool] makeSingleSelectionWithItem: newItem];

	UKFalse([newButtonItem isSelected]);
	UKIntsEqual(0, [newItemGroup selectionIndex]);
	UKNil([[newItemGroup layout] handleGroupForItem: newButtonItem]);
	UKNotNil([[newItemGroup layout] handleGroupForItem: newItem]);
	UKIntsEqual(1, [[[newItemGroup layout] layerItem] numberOfItems]);

	// FIXME: the bounding box is damaged due to the selection
	//[self checkValidityForNewPersistentObject: newItemGroup isFault: NO];
	//[self checkValidityForNewPersistentObject: newItem isFault: NO];
	//[self checkValidityForNewPersistentObject: newButtonItem isFault: NO];
}
#endif

@end

#endif
