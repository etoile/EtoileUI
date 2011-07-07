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
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETStyle.h"
#import "ETShape.h"

#define UKRectsEqual(x, y) UKTrue(NSEqualRects(x, y))
#define UKRectsNotEqual(x, y) UKFalse(NSEqualRects(x, y))

@interface TestPersistency : NSObject <UKTest>
{
	COEditingContext *ctxt;
	ETLayoutItemFactory *itemFactory;
	ETLayoutItem *item;
}

@end

@implementation TestPersistency

- (id) init
{
	SUPERINIT
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	ASSIGN(item, [itemFactory item]);
	return self;
}

DEALLOC(DESTROY(itemFactory); DESTROY(item))

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

@end

#endif
