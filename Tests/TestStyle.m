/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  October 2009
    License:  Modified BSD (see COPYING)
 */

#import "TestCommon.h"
#import "ETBasicItemStyle.h"
#import "ETLayoutExecutor.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETCompatibility.h"

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
	[[ETLayoutExecutor sharedInstance] removeAllItems];
	ASSIGN(itemFactory, [ETLayoutItemFactory factory]);
	ASSIGN(item, [itemFactory item]);
	[item setFrame: NSMakeRect(100, 50, 300, 200)];
	return self;
}

DEALLOC(DESTROY(itemFactory); DESTROY(item))

- (void) testSharedInstance
{
	UKNotNil([ETBasicItemStyle sharedInstanceForObjectGraphContext: [itemFactory objectGraphContext]]);
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

