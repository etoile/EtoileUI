/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/NSObject+Model.h>
#import <CoreObject/COEditingContext.h>
#import <CoreObject/COEditingContext+Debugging.h>
#import <CoreObject/COObject.h>
#import <CoreObject/COObjectGraphContext.h>
#import <CoreObject/COObjectGraphContext+Debugging.h>
#import <CoreObject/COPersistentRoot.h>
#import <CoreObject/COSQLiteStore.h>
#import <CoreObject/COSerialization.h>
#import "ETDecoratorItem.h"
#import "ETGeometry.h"
#import "ETLayoutExecutor.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItemFactory.h"
#import "ETTool.h"

#define SA(x) [NSSet setWithArray: x]

#define UKRectsEqual(x, y) UKTrue(NSEqualRects(x, y))
#define UKRectsNotEqual(x, y) UKFalse(NSEqualRects(x, y))
#define UKPointsEqual(x, y) UKTrue(NSEqualPoints(x, y))
#define UKPointsNotEqual(x, y) UKFalse(NSEqualPoints(x, y))
#define UKSizesEqual(x, y) UKTrue(NSEqualSizes(x, y))
#define UKSizesNotEqual(x, y) UKFalse(NSEqualSizes(x, y))

#define UKObjectUUIDsEqual(a, b) UKObjectsEqual([a UUID], [b UUID])
#define UKCollectionUUIDsEqual(a, b) UKObjectsEqual([[a mappedCollection] UUID], [[b mappedCollection] UUID])

/** Test macro to be used in the block passed to
-[TestCommon checkWithExistingAndNewRootObject:inBlock:]. */
#define UKValidateLoadedObjects(newObject, oldObject, aliased) \
    if (isCopy && isNew == NO) \
    { \
		if (aliased) \
		{ \
			UKObjectsSame(newObject, [[newObject objectGraphContext] loadedObjectForUUID: [oldObject UUID]]); \
		} \
		else \
		{ \
        	UKObjectsNotEqual(newObject, [[newObject objectGraphContext] loadedObjectForUUID: [oldObject UUID]]); \
		} \
    } \
    else \
    { \
        UKObjectsEqual(newObject, [[newObject objectGraphContext] loadedObjectForUUID: [oldObject UUID]]); \
    }

/* A simple model object for testing purpose */
@interface Person : NSObject
{
	NSString *_name;
	NSDictionary *_emails;
	NSArray *_groupNames;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, copy) NSDictionary *emails;
@property (nonatomic, retain) NSArray *groupNames;
@end


@class ETTool;

@interface TestCommon : NSObject
{
    COEditingContext *editingContext;
	ETLayoutItemFactory *itemFactory;
}

- (NSURL *) storeURL;

- (void) checkWithExistingAndNewRootObject: (COObject *)rootObject 
                                   inBlock: (void (^)(id rootObject, BOOL isNew, BOOL isCopy))block;

- (ETLayoutItem *) basicItemWithRect: (NSRect)rect;

@end


/** Use EVT() to create an event with a point expressed in the main item coordinates. 
The main item is the window content. */
#define CLICK_EVT(x, y, clicks) (id)[self createEventAtContentPoint: NSMakePoint(x, y) clickCount: clicks inWindow: [self window]]
#define EVT(x, y) CLICK_EVT(x, y, 1)

@interface TestEvent : TestCommon
{
	ETLayoutItemGroup *mainItem;
	id tool;
}

- (ETEvent *) createEventAtPoint: (NSPoint)loc clickCount: (NSUInteger)clickCount inWindow: (NSWindow *)win;
- (ETEvent *) createEventAtContentPoint: (NSPoint)loc clickCount: (NSUInteger)clickCount inWindow: (NSWindow *)win;
- (NSWindow *) window;
- (ETEvent *) createEventAtScreenPoint: (NSPoint)loc isFlipped: (BOOL)flip;

@end


@interface TestLayoutPersistency : TestCommon <UKTest>
{
	ETLayoutItemGroup *itemGroup;
	ETLayoutItem *item;
	ETLayoutItem *buttonItem;
	id layout;
}

- (Class) layoutClass;

@end


@interface ETUIObject (ETUIObjectTestAdditions)
- (void) recordDeallocation;
+ (void) clearRecordedDeallocations;
+ (BOOL) isObjectDeallocatedForUUID: (ETUUID *)aUUID;
@end

@interface ETTool (ETToolTestAdditions)
+ (id) tool;
@end

@interface ETLayoutItem (ETLayoutItemTestAdditions)
/** For test, patch the framework implementation. */
+ (NSRect) defaultItemRect;
@end

@interface ETDecoratorItem (ETDecoratorTestAdditions)
+ (ETDecoratorItem *) itemWithDummySupervisorView;
@end

@interface ETLayout (ETLayoutTestAdditions)
- (NSSize) oldProposedLayoutSize;
- (CGFloat) previousScaleFactor;
@end
