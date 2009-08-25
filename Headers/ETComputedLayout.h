/** <title>ETComputedLayout</title>
	
	<abstract>An abstract layout class whose subclasses position items by 
	computing their location based on a set of rules.</asbtract>
 
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date: July 2008
	License:  Modified BSD (see COPYING)
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayout.h>

@class ETLayoutLine;


/** ETComputedLayout is a basic abstract class that must be subclassed everytime 
a layout role only consists in positioning, orienting and sizing the layout 
items handed to it.

The layout logic must be strictly positional and not touch anything else than 
the item geometry (position, width, height, scale, rotation etc.).

Subclasses must not hide, replace or modify the layout item tree structure bound 
to the layout context in any way, unlike what ETCompositeLayout or 
ETTemplateItemLayout are allowed to do. */
@interface ETComputedLayout : ETLayout <ETPositionalLayout>
{
	float _itemMargin;
	ETLayoutItem *_seperatorTemplateItem;
}

- (void) setItemMargin: (float)margin;
- (float) itemMargin;

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent;

/* Line-based Layout */

- (ETLayoutLine *) layoutLineForLayoutItems: (NSArray *)items;
- (NSArray *) layoutModelForLayoutItems: (NSArray *)items;
- (void) computeLayoutItemLocationsForLayoutModel: (NSArray *)layoutModel;

/* Seperator support */

- (void) setSeparatorTemplateItem: (ETLayoutItem *)seperator;
- (ETLayoutItem *) seperatorTemplateItem;

@end
