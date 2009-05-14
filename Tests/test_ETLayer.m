/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2009

	License:  Modified BSD (see COPYING)
 */
 
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/Macros.h>
#import <UnitKit/UnitKit.h>
#import "ETFreeLayout.h"
#import "ETInstrument.h"
#import "ETLayer.h"
#import "ETSelectTool
.h"
#import "ETCompatibility.h"

#define UKRectsEqual(x, y) UKTrue(NSEqualRects(x, y))
#define UKRectsNotEqual(x, y) UKFalse(NSEqualRects(x, y))
#define UKPointsEqual(x, y) UKTrue(NSEqualPoints(x, y))
#define UKPointsNotEqual(x, y) UKFalse(NSEqualPoints(x, y))
#define UKSizesEqual(x, y) UKTrue(NSEqualSizes(x, y))

@interface WindowLayerTest : NSObject
{
	ETWindowLayer *layer;
}

@end

@implementation WindowLayerTest

- (id) init
{
	SUPERINIT
	layer = [[ETWindowLayer alloc] init];
	return self;
}

DEALLOC(DESTROY(layer))

- (void) testFrame
{
	UKTrue(NSContainsRect([[NSScreen mainScreen] frame], [layer frame]));
	UKTrue(NSContainsRect([layer frame], [[NSScreen mainScreen] visibleFrame]));
}

- (void) testInitialActiveInstrument
{
	UKObjectsSame([[layer layout] attachedInstrument], [ETInstrument activeInstrument]);
}

- (void) testLayout
{
	[layer setLayout: [ETFreeLayout layout]];

	ETInstrument *instrument = [[layer layout] attachedInstrument];
	UKObjectKindOf(instrument, ETSelectTool);


	//UKObjectsSame([ETInstrument activeInstrument], [[layer layout] attachedInstrument]);	
}

@end
