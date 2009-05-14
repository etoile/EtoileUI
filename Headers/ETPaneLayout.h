/**	<title>ETPaneLayout</title>

	<abstract>Description forthcoming.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETComputedLayout.h>

@class ETLayoutItemGroup;


typedef enum {
	ETPanePositionNone,
	ETPanePositionTop,
	ETPanePositionBottom,
	ETPanePositionLeft,
	ETPanePositionRight
} ETPanePosition;


@interface ETPaneLayout : ETLayout
{
	ETLayoutItemGroup *_contentItem;
	ETLayoutItemGroup *_barItem;
	ETLayoutItem *_currentItem;
}

/* Navigation */

- (BOOL) canGoBack;
- (BOOL) canGoForward;
- (void) goBack;
- (void) goForward;
- (id) currentItem;
- (id) backItem;
- (id) forwardItem;
- (void) goToItem: (ETLayoutItem *)item;

/* Presentation */

/*- (ETPanePosition) barPosition;
- (void) setBarPosition: (ETPanePosition)position;*/
- (void) setBarItem: (ETLayoutItemGroup *)item;
- (ETLayoutItemGroup *) barItem;
- (ETLayoutItemGroup *) contentItem;
- (void) tile;

- (NSArray *) tabItemsWithItems: (NSArray *)items;

@end
