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
#import <CoreObject/COObjectGraphContext.h>
#import "ETDecoratorItem.h"
#import "ETGeometry.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutExecutor.h"
#import "ETWindowItem.h"
#import "ETLayoutExecutor.h"
#import "ETScrollableAreaItem.h"
#import "ETCompatibility.h"

#define UKRectsEqual(x, y) UKTrue(NSEqualRects(x, y))
#define UKRectsNotEqual(x, y) UKFalse(NSEqualRects(x, y))
#define UKPointsEqual(x, y) UKTrue(NSEqualPoints(x, y))
#define UKPointsNotEqual(x, y) UKFalse(NSEqualPoints(x, y))
#define UKSizesEqual(x, y) UKTrue(NSEqualSizes(x, y))


@interface TestWindowItem : NSObject <UKTest>
{
	ETLayoutItemFactory *itemFactory;
}

@end

@implementation TestWindowItem

- (id) init
{
	SUPERINIT;
	[[ETLayoutExecutor sharedInstance] removeAllItems];
	itemFactory = [ETLayoutItemFactory factory];
	return self;
}

- (void) testWindowContentView
{
	ETLayoutItem *item = [itemFactory item];
	id decorator = [ETWindowItem itemWithObjectGraphContext: [itemFactory objectGraphContext]];
	
	[item setDecoratorItem: decorator];
	
	UKObjectsEqual([item supervisorView], [[decorator window] contentView]);
	
	[item setDecoratorItem: nil];
	
	UKNil([[decorator window] contentView]);

	/* Just ensure a -orderFront: drawing attempt don't cause issues */
	[[decorator window] orderOut: nil];
	[[decorator window] orderFront: nil];
}

- (void) testRetainCountForUndecorate
{
	[ETLayoutItem disablesAutolayout];
	
	ETLayoutItem *item = [itemFactory item];
	id decorator = [ETWindowItem itemWithObjectGraphContext: [itemFactory objectGraphContext]];
	
	CREATE_AUTORELEASE_POOL(pool);
	[item setDecoratorItem: decorator];
	[item setDecoratorItem: nil];
	[[itemFactory objectGraphContext] discardAllChanges];
	DESTROY(pool);
	
	UKIntsEqual(1, [decorator retainCount]);
	UKIntsEqual(1, [item retainCount]);

	[ETLayoutItem enablesAutolayout];
}

- (void) testWindowTitleBinding
{
	/* Release as many objects as possible to catch binding teardown issues */
	[ETLayoutItem disablesAutolayout];
	CREATE_AUTORELEASE_POOL(pool);

	ETLayoutItem *item = [itemFactory item];
	id decorator = [ETWindowItem itemWithObjectGraphContext: [itemFactory objectGraphContext]];

	[item setName: @"Jupiter"];
	[item setDecoratorItem: decorator];

	UKStringsEqual(@"Jupiter", [[decorator window] title]);
	
	[item setDecoratorItem: nil];

	UKStringsNotEqual(@"Jupiter", [[decorator window] title]);
	UKNil([[[decorator window] infoForBinding: NSTitleBinding] objectForKey: NSObservedObjectKey]);

	DESTROY(pool);
	[ETLayoutItem enablesAutolayout];
}

- (void) testWindowTitleBindingForInnerDecorator
{
	/* Release as many objects as possible to catch binding teardown issues */
	[ETLayoutItem disablesAutolayout];
	CREATE_AUTORELEASE_POOL(pool);
	
	ETLayoutItem *item = [itemFactory item];
	id decorator = [ETWindowItem itemWithObjectGraphContext: [itemFactory objectGraphContext]];
	id innerDecorator = [ETScrollableAreaItem itemWithObjectGraphContext: [itemFactory objectGraphContext]];
	
	[item setName: @"Jupiter"];
	[innerDecorator setDecoratorItem: decorator];
	[item setDecoratorItem: innerDecorator];
	
	UKStringsEqual(@"Jupiter", [[decorator window] title]);
	
	[item setDecoratorItem: nil];
	
	UKStringsNotEqual(@"Jupiter", [[decorator window] title]);
	UKNil([[[decorator window] infoForBinding: NSTitleBinding] objectForKey: NSObservedObjectKey]);
	
	DESTROY(pool);
	[ETLayoutItem enablesAutolayout];
}

@end
