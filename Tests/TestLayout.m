/*
	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2008
	License:  Modified BSD (see COPYING)
 */
 
#import "TestCommon.h"
#import "ETColumnLayout.h"
#import "ETLayout.h"
#import "ETLayoutItem.h"
#import "ETLayoutItemFactory.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutExecutor.h"
#import "ETTableLayout.h"
#import "ETCompatibility.h"

@interface ETLayout (Private)
+ (NSString *) stripClassName;
+ (NSString *) displayName;
+ (NSString *) aspectName;
@end

@interface TestLayout : NSObject <UKTest>
@end

/* Dummy class for testing */
@interface WXYBirdTableBirdBird : ETLayout
@end

@implementation WXYBirdTableBirdBird
+ (NSString *) typePrefix {	return @"WXY"; }
+ (NSString *) baseClassName { return @"Bird"; }
@end


@implementation TestLayout

- (void) testDisplayName
{
	UKStringsEqual(@"Layout", [ETLayout displayName]);
	UKStringsEqual(@"Table Layout", [ETTableLayout displayName]);
	UKStringsEqual(@"Bird Table Bird Bird", [WXYBirdTableBirdBird displayName]);
}

- (void) testStripClassName
{
	UKStringsEqual(@"Layout", [ETLayout stripClassName]);
	UKStringsEqual(@"Table", [ETTableLayout stripClassName]);
	UKStringsEqual(@"BirdTableBird", [WXYBirdTableBirdBird stripClassName]);
}

- (void) testAspectName
{
	UKStringsEqual(@"layout", [ETLayout aspectName]);
	UKStringsEqual(@"table", [ETTableLayout aspectName]);
	UKStringsEqual(@"birdTableBird", [WXYBirdTableBirdBird aspectName]);
}

@end


@interface TestPositionalLayout : TestCommon <UKTest>
{
	ETLayoutItemGroup *itemGroup;
	ETLayoutItem *item;
}

@end

@implementation  TestPositionalLayout

- (id) init
{
	SUPERINIT;
	itemGroup = [itemFactory itemGroup];
	item = [itemFactory item];
	return self;
}

- (void) testUpsizedItemForContentSizeLayout
{
	ETColumnLayout *layout = [ETColumnLayout layoutWithObjectGraphContext: [itemGroup objectGraphContext]];
	
	[[layout positionalLayout] setIsContentSizeLayout: YES];
	[itemGroup setLayout: layout];

	ETLayoutItem *textItem = [itemFactory textField];

	[item setWidth: 700];
	[textItem setHeight: 500];

	CGFloat width = MAX([item width], [textItem width]);
	CGFloat height = [item height] + [textItem height];
	NSSize contentSize = NSMakeSize(width, height);

	[itemGroup addItems: A(item, textItem)];
	
	[[ETLayoutExecutor sharedInstance] execute];

	UKSizesEqual(contentSize, [layout layoutSize]);
	UKSizesEqual(contentSize, [itemGroup size]);
}

- (void) testDownsizedItemForContentSizeLayout
{
	itemGroup = [itemFactory itemGroupWithSize: NSMakeSize(10000, 10000)];
	[self testUpsizedItemForContentSizeLayout];
}

@end
