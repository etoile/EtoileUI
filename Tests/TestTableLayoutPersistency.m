/*
	Copyright (C) 2014 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2014
	License:  Modified BSD (see COPYING)
 */
 
#import "TestCommon.h"
#import "ETTableLayout.h"
#import "ETSelectTool.h"
#import "ETCompatibility.h"

@interface TestTableLayoutPersistency : TestLayoutPersistency
@end

@implementation TestTableLayoutPersistency

- (Class) layoutClass
{
	return [ETTableLayout class];
}

- (CGFloat) previousScaleFactorForLayout: (id)newLayout
{
	// ETTableLayout doesn't use _previousItemScaleFactor
	return [[newLayout layoutContext] itemScaleFactor];
}

- (void) testSelectionAttributes
{
	ETSelectTool *tool = [ETSelectTool toolWithObjectGraphContext: [layout objectGraphContext]];

	[tool setAllowsMultipleSelection: YES];
	[tool setAllowsEmptySelection: YES];

	[layout setAttachedTool: tool];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETTableLayout *newLayout = [newItemGroup layout];

		UKTrue([[newLayout tableView] allowsMultipleSelection]);
		UKTrue([[newLayout tableView] allowsEmptySelection]);
    }];
}

- (void) testExternalTableAttributes
{
	NSFont *font = [NSFont fontWithName: @"Helvetica" size: 64];

	[layout setContentFont: font];
	[layout setSortable: YES];

    [self checkWithExistingAndNewRootObject: itemGroup
                                    inBlock: ^(ETLayoutItemGroup *newItemGroup, BOOL isNew, BOOL isCopy)
    {
        ETTableLayout *newLayout = [newItemGroup layout];

		UKObjectsEqual(font, [newLayout contentFont]);
		UKTrue([newLayout isSortable]);
    }];
}

// TODO: -testTableViewTarget, -testSelectionPropagationFromTable, -testSelectionPropagationToTable

@end
