/*
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  June 2014
    License:  Modified BSD (see COPYING)
 */

#import <CoreObject/COBranch.h>
#import "TestCommon.h"
#import "EtoileUIProperties.h"
#import "ETBasicItemStyle.h"
#import "ETShape.h"
#import "ETCompatibility.h"

@interface TestStylePersistency : TestCommon <UKTest>
{
    
}

@end

@implementation TestStylePersistency

- (id) init
{
	SUPERINIT;
    ASSIGN(itemFactory, [ETLayoutItemFactory factoryWithObjectGraphContext:
        [COObjectGraphContext objectGraphContext]]);
	return self;
}

- (void) testBasicItemStyle
{
	ETBasicItemStyle *style = AUTORELEASE([[ETBasicItemStyle alloc]
		initWithObjectGraphContext: [itemFactory objectGraphContext]]);
	
	[style setLabelPosition: ETLabelPositionInsideTop];
	[style setLabelMargin: 5];
	[style setMaxImageSize: NSMakeSize(50, 100)];
	[style setEdgeInset: 10];

	[self checkWithExistingAndNewRootObject: style
                                    inBlock: ^(ETBasicItemStyle *newStyle, BOOL isNew, BOOL isCopy)
    {
        UKValidateLoadedObjects(newStyle, style);

        UKIntsEqual(ETLabelPositionInsideTop, [newStyle labelPosition]);
        UKIntsEqual(5, [newStyle labelMargin]);
        UKSizesEqual([style maxLabelSize], [newStyle maxLabelSize]);
        UKSizesEqual(NSMakeSize(50, 100), [newStyle maxImageSize]);
        UKIntsEqual(10, [newStyle edgeInset]);

        NSRect labelRect = [newStyle rectForLabel: @"Whatever"
                                          inFrame: NSMakeRect(0, 0, 200, 20)
                                           ofItem: [itemFactory item]];
        
        UKTrue(labelRect.size.width > 10);
        /* Font size must be big enough to ensure label height is bigger than 10px */
        UKTrue(labelRect.size.height > 10);
    }];
}

- (void) testBasicShapeSerialization
{
	NSRect rect = NSMakeRect(50, 20, 400, 300);
	ETShape *shape = [ETShape rectangleShapeWithRect: rect
								  objectGraphContext: [itemFactory objectGraphContext]];

	[shape setPathResizeSelector: @selector(resizedPathWithRect:)];
	[shape setFillColor: [NSColor redColor]];
	[shape setStrokeColor: nil];
	[shape setAlphaValue: 0.4];
	[shape setHidden: YES];

	UKRectsEqual(rect, [[shape roundTripValueForProperty: @"path"] bounds]);
	UKStringsEqual(@"resizedPathWithRect:", [shape roundTripValueForProperty: @"pathResizeSelector"]);
	UKObjectsEqual([NSColor redColor], [shape roundTripValueForProperty: @"fillColor"]);
	UKNil([shape roundTripValueForProperty: @"strokeColor"]);
	UKTrue([[shape roundTripValueForProperty: @"hidden"] boolValue]);
}

- (void) testBasicShape
{
	NSRect rect = NSMakeRect(50, 20, 400, 300);
	ETShape *shape = [ETShape rectangleShapeWithRect: rect
	                              objectGraphContext: [itemFactory objectGraphContext]];

	[self checkWithExistingAndNewRootObject: shape
                                    inBlock: ^(ETShape *newShape, BOOL isNew, BOOL isCopy)
    {
        UKValidateLoadedObjects(newShape, shape);
        UKRectsEqual(rect, [newShape bounds]);
    }];
}

@end
