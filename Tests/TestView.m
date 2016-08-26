/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
 */

#import "TestCommon.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItem.h"
#import "NSView+EtoileUI.h"
#import "ETCompatibility.h"

@interface TestView : TestCommon <UKTest>
@end

@implementation TestView

- (void) testPopUpCopyDoesNotEncodeRepresentedObjectsAndTarget
{
	ETLayoutItem *popUpItem = [[ETLayoutItemFactory factory]
		popUpMenuWithItemTitles: @[@"A", @"B", @"C"]
		     representedObjects: @[[NSNull null], self]
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

