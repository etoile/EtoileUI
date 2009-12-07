/**	<title>ETLayoutItemFactory</title>

	<abstract>Factory for building various kinds of UI items and keeping track 
	of special nodes of the layout item tree.</abstract>

	Copyright (C) 2007 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class ETLayoutItem, ETLayoutItemGroup, ETLayer, ETScrollableAreaItem, ETStyle, ETWindowItem;


@interface ETLayoutItemFactory : NSObject
{
	ETStyle *_currentBarElementStyle;
	float _currentBarElementHeight;
}

+ (id) factory;

/* Bar Building Settings */

- (ETStyle *) currentBarElementStyle;
- (void) setCurrentBarElementStyle: (ETStyle *)aStyle;
- (float) currentBarElementHeight;
- (void) setCurrentBarElementHeight: (float)aHeight;
- (float) defaultIconAndLabelBarHeight;

/* Basic Item Factory Methods */

- (ETLayoutItem *) item;
- (ETLayoutItem *) itemWithView: (NSView *)view;
- (ETLayoutItem *) itemWithValue: (id)value;
- (ETLayoutItem *) itemWithRepresentedObject: (id)object;

- (ETLayoutItem *) barElementFromItem: (ETLayoutItem *)anItem 
                            withLabel: (NSString *)aLabel;
- (ETLayoutItem *) barElementFromItem: (ETLayoutItem *)anItem 
                            withLabel: (NSString *)aLabel
                                style: (ETStyle *)aStyle;

/* Group Factory Methods */

- (ETLayoutItemGroup *) itemGroup;
- (ETLayoutItemGroup *) itemGroupWithFrame: (NSRect)aRect;
- (ETLayoutItemGroup *) itemGroupWithItem: (ETLayoutItem *)item;
- (ETLayoutItemGroup *) itemGroupWithItems: (NSArray *)items;
- (ETLayoutItemGroup *) itemGroupWithValue: (id)value;
- (ETLayoutItemGroup *) itemGroupWithRepresentedObject: (id)object;

- (ETLayoutItemGroup *) graphicsGroup;

- (ETLayoutItemGroup *) horizontalBarWithSize: (NSSize)aSize;

/* Leaf Widget Factory Methods */

- (id) button;
- (id) buttonWithTitle: (NSString *)aTitle target: (id)aTarget action: (SEL)aSelector;
- (id) buttonWithImage: (NSImage *)anImage target: (id)aTarget action: (SEL)aSelector;
- (id) radioButton;
- (id) checkboxWithLabel: (NSString *)aLabel 
                  target: (id)aTarget 
                  action: (SEL)aSelector
            propertyName: (NSString *)aKey
                 ofModel: (id)aModel; 
- (id) labelWithTitle: (NSString *)aTitle;
- (id) textField;
- (id) searchFieldWithTarget: (id)aTarget action: (SEL)aSelector;
- (id) textView;
- (id) progressIndicator;
- (id) horizontalSlider;
- (id) verticalSlider;
- (id) stepper;
- (id) textFieldAndStepper;
- (id) popUpMenuWithItemTitles: (NSArray *)entryTitles 
            representedObjects: (NSArray *)entryModels 
                        target: (id)aTarget 
                        action: (SEL)aSelector;

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

/* Seperator Factory Methods */

- (ETLayoutItem *) lineSeparator;
- (ETLayoutItem *) spaceSeparator;
- (ETLayoutItem *) flexibleSpaceSeparator;

/* Deprecated (DO NOT USE, WILL BE REMOVED LATER) */

- (ETLayoutItemGroup *) itemGroupWithContainer;

@end


/** Deprecated (DO NOT USE, WILL BE REMOVED LATER) */
@interface ETUIItemFactory : ETLayoutItemFactory
- (ETWindowItem *) itemWithWindow: (NSWindow *)window;
- (ETWindowItem *) fullScreenWindow;
- (ETWindowItem *) transparentFullScreenWindow;
- (ETScrollableAreaItem *) itemWithScrollView: (NSScrollView *)scrollView;
@end
