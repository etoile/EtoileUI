/**	<title>ETUIItemFactory</title>

	<abstract>Factory for building various kinds of UI items and keeping track 
	of special nodes of the layout item tree.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETLayoutItem, ETLayoutItemGroup, ETLayer, ETScrollableAreaItem, ETWindowItem;


@interface ETUIItemFactory : NSObject

+ (id) factory;

/* Basic Item Factory Methods */

- (ETLayoutItem *) item;
- (ETLayoutItem *) itemWithView: (NSView *)view;
- (ETLayoutItem *) itemWithValue: (id)value;
- (ETLayoutItem *) itemWithRepresentedObject: (id)object;

/* Group Factory Methods */

- (ETLayoutItemGroup *) itemGroup;
- (ETLayoutItemGroup *) itemGroupWithFrame: (NSRect)aRect;
- (ETLayoutItemGroup *) itemGroupWithItem: (ETLayoutItem *)item;
- (ETLayoutItemGroup *) itemGroupWithItems: (NSArray *)items;
- (ETLayoutItemGroup *) itemGroupWithView: (NSView *)view;
- (ETLayoutItemGroup *) itemGroupWithValue: (id)value;
- (ETLayoutItemGroup *) itemGroupWithRepresentedObject: (id)object;

- (ETLayoutItemGroup *) graphicsGroup;

/* Leaf Widget Factory Methods */

- (id) button;
- (id) buttonWithTitle: (NSString *)aTitle target: (id)aTarget action: (SEL)aSelector;
- (id) radioButton;
- (id) checkbox;
- (id) labelWithTitle: (NSString *)aTitle;
- (id) textField;
- (id) searchField;
- (id) textView;
- (id) progressIndicator;
- (id) horizontalSlider;
- (id) verticalSlider;
- (id) stepper;
- (id) textFieldAndStepper;

/* Decorator Item Factory Methods */

- (ETWindowItem *) itemWithWindow: (NSWindow *)window;
- (ETWindowItem *) fullScreenWindow;
- (ETWindowItem *) transparentFullScreenWindow;
- (ETScrollableAreaItem *) itemWithScrollView: (NSScrollView *)scrollView;

/* Layer Factory Methods */

- (ETLayer *) layer;
- (ETLayer *) layerWithItem: (ETLayoutItem *)item;
- (ETLayer *) layerWithItems: (NSArray *)items;
- (ETLayer *) guideLayer;
- (ETLayer *) gridLayer;

/* Special Group Access Methods */

- (id) rootGroup;
- (id) localRootGroup;

- (id) screen;
- (id) screenGroup;
- (id) project;
- (id) projectGroup;

- (ETLayoutItemGroup *) windowGroup;
- (void) setWindowGroup: (ETLayoutItemGroup *)windowGroup;

- (id) pickboardGroup;

/* Shape Factory Methods */

- (ETLayoutItem *) itemWithBezierPath: (NSBezierPath *)aPath;

- (ETLayoutItem *) rectangleWithRect: (NSRect)aRect;
- (ETLayoutItem *) rectangle;
- (ETLayoutItem *) ovalWithRect: (NSRect)aRect;
- (ETLayoutItem *) oval;

/* Deprecated (DO NOT USE, WILL BE REMOVED LATER) */

- (ETLayoutItemGroup *) itemGroupWithContainer;

@end
