/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  January 2007
	License:  Modified BSD (see COPYING)
 */

#import "MarkupEditorController.h"
#import "MarkupEditorItemFactory.h"


@implementation MarkupEditorController

- (id) initWithNibName: (NSString *)aNibName bundle: (NSBundle *)aBundle
{
	self = [super initWithNibName: aNibName bundle: aBundle];
	if (nil == self)
		return nil;

	MarkupEditorItemFactory *itemFactory = [MarkupEditorItemFactory factory];
	ETLayoutItemGroup *item = [itemFactory itemGroup];

	[self setTemplate: [ETItemTemplate templateWithItem: item  objectClass: [NSMutableDictionary class]]
	          forType: [self currentObjectType]];
	/*[self setTemplate: [ETItemTemplate templateWithItem: [itemFactory item] objectClass: [NSString class]]
	          forType: [self currentObjectType]];*/

	return self;
}

- (ETLayoutItemGroup *) content
{
	return (ETLayoutItemGroup *)[[super content] itemForIdentifier: @"documentContent"];
}

@end
