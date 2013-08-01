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
	@private
	ETLayoutItemGroup *_contentItem;
	ETLayoutItemGroup *_barItem;
	ETLayoutItem *_currentItem;
	ETPanePosition _barPosition;
	CGFloat _barThickness;
	BOOL _isSwitching;
	BOOL _ensuresContentFillsVisibleArea;
}

/** @taskunit Initialization */

+ (id) layoutWithBarItem: (ETLayoutItemGroup *)barItem
             contentItem: (ETLayoutItemGroup *)contentItem
      objectGraphContext: (COObjectGraphContext *)aContext;
- (id) initWithBarItem: (ETLayoutItemGroup *)barItem
           contentItem: (ETLayoutItemGroup *)contentItem
    objectGraphContext: (COObjectGraphContext *)aContext;

/** @taskunit Navigation */

- (BOOL) canGoBack;
- (BOOL) canGoForward;
- (void) goBack;
- (void) goForward;
- (id) currentItem;
- (id) backItem;
- (id) forwardItem;
- (BOOL) goToItem: (ETLayoutItem *)item;

/** @taskunit Presentation */

- (ETPanePosition) barPosition;
- (void) setBarPosition: (ETPanePosition)position;
- (CGFloat) barThickness;
- (void) setBarThickness: (CGFloat)aThickness;
- (void) setBarItem: (ETLayoutItemGroup *)item;
- (ETLayoutItemGroup *) barItem;
- (ETLayoutItemGroup *) contentItem;
- (BOOL) ensuresContentFillsVisibleArea;
- (void) setEnsuresContentFillsVisibleArea: (BOOL)fill;
- (void) tile;

/** @taskunit Navigation Behavior */

- (id) beginVisitingItem: (ETLayoutItem *)tabItem;
- (void) endVisitingItem: (ETLayoutItem *)tabItem;
- (BOOL) shouldSelectVisitedItem: (ETLayoutItem *)tabItem;

@end


@interface ETPaneLayout (Factory)

+ (ETPaneLayout *) masterDetailLayoutWithObjectGraphContext: (COObjectGraphContext *)aContext;
+ (ETPaneLayout *) masterContentLayoutWithObjectGraphContext: (COObjectGraphContext *)aContext;
+ (ETPaneLayout *) slideshowLayoutWithObjectGraphContext: (COObjectGraphContext *)aContext;
+ (ETPaneLayout *) slideshowLayoutWithNavigationBarWithObjectGraphContext: (COObjectGraphContext *)aContext;
+ (ETPaneLayout *) drillDownLayoutWithObjectGraphContext: (COObjectGraphContext *)aContext;
+ (ETPaneLayout *) paneNavigationLayoutWithObjectGraphContext: (COObjectGraphContext *)aContext;
+ (ETPaneLayout *) wizardLayoutWithObjectGraphContext: (COObjectGraphContext *)aContext;

@end
