/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import "TestCommon.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItem.h"
#import "NSView+Etoile.h"
#import "ETCompatibility.h"

@interface TestView : NSObject <UKTest>
@end

@implementation TestView

- (void) testPopUpCopyDoesNotEncodeRepresentedObjectsAndTarget
{
	ETLayoutItem *popUpItem = [[ETLayoutItemFactory factory]
		popUpMenuWithItemTitles: A(@"A", @"B", @"C")
		     representedObjects: A([NSNull null], self)
		                 target: self
	                     action: @selector(paste:)];
	NSPopUpButton *popUpCopy = [[popUpItem view] copy];

	UKNil([[popUpCopy itemAtIndex: 0] representedObject]);
	UKObjectsSame(self, [[popUpCopy itemAtIndex: 1] representedObject]);
	UKNil([[popUpCopy itemAtIndex: 2] representedObject]);
	UKObjectsSame(self, [popUpCopy target]);
	UKStringsEqual(@"paste:", NSStringFromSelector([popUpCopy action]));
}

@end

