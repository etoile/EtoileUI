/**  <title>ETFreeLayout</title>

	<abstract>Free layout class which let the user position the layout items by 
	direct manipulation</abstract>

	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
	License:  Modified BSD (see COPYING)
 */
 
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETFixedLayout.h>

@class ETComputedLayout, ETLayoutItemGroup;

/** The free layout requires an ETLayoutItemGroup object as the layout context. */
@interface ETFreeLayout : ETFixedLayout
{
	@private
	NSArray *_observedItems;
	BOOL _areHandlesHidden;
}

/* KVO */

- (void) updateKVOForItems: (NSArray *)items;

/* Handles */

- (BOOL) showsHandlesForTool: (ETTool *)anTool;
- (void) showHandles;
- (void) hideHandles;
- (void) showHandlesForItem: (ETLayoutItem *)item;
- (void) hideHandlesForItem: (ETLayoutItem *)item;
- (void) buildHandlesForItems: (NSArray *)manipulatedItems;
- (ETLayoutItemGroup *) handleGroupForItem: (ETLayoutItem *)item;

- (void) resetItemPersistentFramesWithLayout: (ETComputedLayout *)layout;

@end
