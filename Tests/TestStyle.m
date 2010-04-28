/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  October 2009
    License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <UnitKit/UnitKit.h>
#import <EtoileFoundation/Macros.h>
#import "ETBasicItemStyle.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETCompatibility.h"

#define UKRectsEqual(x, y) UKTrue(NSEqualRects(x, y))
#define UKRectsNotEqual(x, y) UKFalse(NSEqualRects(x, y))
#define UKPointsEqual(x, y) UKTrue(NSEqualPoints(x, y))
#define UKPointsNotEqual(x, y) UKFalse(NSEqualPoints(x, y))
#define UKSizesEqual(x, y) UKTrue(NSEqualSizes(x, y))
#define UKSizesNotEqual(x, y) UKFalse(NSEqualSizes(x, y))

@interface TestStyle: NSObject <UKTest>
{
	ETLayoutItemFactory *itemFactory;
	ETLayoutItem *item;
}

@end

@implementation TestStyle

- (id) init
{
	SUPERINIT
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	item = [[ETLayoutItem alloc] init];
	[item setFrame: NSMakeRect(100, 50, 300, 200)];
	return self;
}

DEALLOC(DESTROY(itemFactory); DESTROY(item))

- (void) testSharedInstance
{
	UKNotNil([ETBasicItemStyle sharedInstance]);
}

- (void) testRectForViewBasic
{
	NSRect sliderFrame = NSMakeRect(0, 0, 150, 20);

	[item setContentAspect: ETContentAspectNone]; /* Disable any autoresizing */
	[[item coverStyle] setLabelPosition: ETLabelPositionInsideBottom];
	[item setView: AUTORELEASE([[NSSlider alloc] initWithFrame: sliderFrame])];

	/* Preconditions */
	UKRectsEqual(sliderFrame, [[item view] frame]);

	NSRect labelRect = NSMakeRect(0, 0, 300, 100);
	NSRect viewRect = [[item coverStyle] rectForViewOfItem: item withLabelRect: labelRect];

	/* sliderY = (300 - 100 - 20) / 2
	   sliderX = (300 - 150) / 2 */
	UKRectsEqual(NSMakeRect(75, 40, 150, 20), viewRect); 
}

//UKPointsEqual(NSMakePoint(0, [item height]), labelRect.origin);

@end

