/**	<title>ETPaneLayout</title>

	<abstract>Description forthcoming.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETCompositeLayout.h>

@class ETLayoutItemGroup;


typedef enum {
	ETPanePositionNone,
	ETPanePositionTop,
	ETPanePositionBottom,
	ETPanePositionLeft,
	ETPanePositionRight
} ETPanePosition;


@interface ETPaneLayout : ETCompositeLayout
{
	ETLayoutItemGroup *_contentItem;
	ETLayoutItemGroup *_barItem;
	ETLayoutItem *_currentItem;
	ETPanePosition _barPosition;
}

+ (id) layoutWithBarItem: (ETLayoutItemGroup *)barItem contentItem: (ETLayoutItemGroup *)contentItem;

- (id) initWithBarItem: (ETLayoutItemGroup *)barItem contentItem: (ETLayoutItemGroup *)contentItem;

/* Navigation */

- (BOOL) canGoBack;
- (BOOL) canGoForward;
- (void) goBack;
- (void) goForward;
- (id) currentItem;
- (id) backItem;
- (id) forwardItem;
- (BOOL) goToItem: (ETLayoutItem *)item;

/* Presentation */

- (ETPanePosition) barPosition;
- (void) setBarPosition: (ETPanePosition)position;
- (void) setBarItem: (ETLayoutItemGroup *)item;
- (ETLayoutItemGroup *) barItem;
- (ETLayoutItemGroup *) contentItem;
- (void) tile;

- (id) beginVisitingItem: (ETLayoutItem *)tabItem;
- (void) endVisitingItem: (ETLayoutItem *)tabItem;

@end


@interface ETPaneLayout (Factory)

+ (ETPaneLayout *) masterDetailLayout;
+ (ETPaneLayout *) slideshowLayout;
+ (ETPaneLayout *) slideshowLayoutWithNavigationBar;
+ (ETPaneLayout *) drillDownLayout;
+ (ETPaneLayout *) paneNavigationLayout;
+ (ETPaneLayout *) wizardLayout;

@end
