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
#import <EtoileFoundation/EtoileFoundation.h>

@class COObjectGraphContext;
@class ETLayoutItem, ETLayoutItemGroup, ETScrollableAreaItem, ETWindowItem, 
ETStyle, ETActionHandler;

@interface ETLayoutItemFactory : NSObject
{
	@private
	COObjectGraphContext *_objectGraphContext;
	BOOL _isCreatingRootObject;
	ETStyle *_currentCoverStyle;
	ETActionHandler *_currentActionHandler;
	ETStyle *_currentBarElementStyle;
	CGFloat _currentBarElementHeight;
}

+ (instancetype) factory;
+ (instancetype) factoryWithObjectGraphContext: (COObjectGraphContext *)aContext;

/** @taskunit Object Graph Context */

- (COObjectGraphContext *) objectGraphContext;

/** Aspect Sharing Boundaries and Persistency */

- (void) beginRootObject;
- (void) endRootObject;
- (BOOL) isCreatingRootObject;
- (void) setAspectProviderItem: (ETLayoutItem *)anItem;
- (ETStyle *) currentCoverStyle;
- (ETActionHandler *) currentActionHandler;

/* Bar Building Settings */

- (ETStyle *) currentBarElementStyle;
- (void) setCurrentBarElementStyle: (ETStyle *)aStyle;
- (CGFloat) currentBarElementHeight;
- (void) setCurrentBarElementHeight: (CGFloat)aHeight;
- (CGFloat) defaultIconAndLabelBarHeight;

/* Basic Item Factory Methods */

- (ETLayoutItem *) item;
- (ETLayoutItem *) itemWithView: (NSView *)view;
- (ETLayoutItem *) itemWithRepresentedObject: (id)object;

- (ETLayoutItem *) barElementFromItem: (ETLayoutItem *)anItem 
                            withLabel: (NSString *)aLabel;
- (ETLayoutItem *) barElementFromItem: (ETLayoutItem *)anItem 
                            withLabel: (NSString *)aLabel
                                style: (ETStyle *)aStyle;

/* Group Factory Methods */

- (ETLayoutItemGroup *) itemGroup;
- (ETLayoutItemGroup *) itemGroupWithFrame: (NSRect)aRect;
- (ETLayoutItemGroup *) itemGroupWithSize: (NSSize)aSize;
- (ETLayoutItemGroup *) itemGroupWithItem: (ETLayoutItem *)item;
- (ETLayoutItemGroup *) itemGroupWithItems: (NSArray *)items;
- (ETLayoutItemGroup *) itemGroupWithRepresentedObject: (id)object;

- (ETLayoutItemGroup *) graphicsGroup;

- (ETLayoutItemGroup *) horizontalBarWithSize: (NSSize)aSize;

- (ETLayoutItemGroup *) collectionEditorWithSize: (NSSize)aSize
                               representedObject: (id <ETCollection>)aCollection
                                      controller: (id)aController;

/* Leaf Widget Factory Methods */

- (id) button;
- (id) buttonWithTitle: (NSString *)aTitle target: (id)aTarget action: (SEL)aSelector;
- (id) buttonWithImage: (NSImage *)anImage target: (id)aTarget action: (SEL)aSelector;
- (id) radioButton;
- (id) checkboxWithLabel: (NSString *)aLabel 
                  target: (id)aTarget 
                  action: (SEL)aSelector
             forProperty: (NSString *)aKey
                 ofModel: (id)aModel;
- (id) checkBox;
- (id) labelWithTitle: (NSString *)aTitle;
- (ETLayoutItem *) textField;
- (id) searchFieldWithTarget: (id)aTarget action: (SEL)aSelector;
- (id) textView;
- (id) progressIndicator;
- (id) verticalSlider;
- (id) horizontalSlider;
- (id) horizontalSliderWithWidth: (CGFloat)aWidth 
                        minValue: (CGFloat)min 
                        maxValue: (CGFloat)max
                    initialValue: (CGFloat)aValue 
                          target: (id)aTarget 
                          action: (SEL)aSelector;
- (id) horizontalSliderWithWidth: (CGFloat)aWidth
                        minValue: (CGFloat)min 
                        maxValue: (CGFloat)max
                     forProperty: (NSString *)aKey
                         ofModel: (id)anObject;
- (id) stepper;
- (ETLayoutItem *) numberPicker;
- (ETLayoutItem *) numberPickerWithWidth: (CGFloat)aWidth
                                minValue: (double)min
                                maxValue: (double)max
                            initialValue: (double)aValue
                             forProperty: (NSString *)aKey
                                 ofModel: (id)anObject;
- (ETLayoutItemGroup *) pointEditorWithWidth: (CGFloat)aWidth
                                forXProperty: (NSString *)aXKey
                                   yProperty: (NSString *)aYKey
                                     ofModel: (id)anObject;
- (ETLayoutItemGroup *) sizeEditorWithWidth: (CGFloat)aWidth
                           forWidthProperty: (NSString *)aWidthKey
                             heightProperty: (NSString *)aHeightKey
                                    ofModel: (id)anObject;
- (ETLayoutItem *) popUpMenu;
- (id) popUpMenuWithItemTitles: (NSArray *)entryTitles 
            representedObjects: (NSArray *)entryModels 
                        target: (id)aTarget 
                        action: (SEL)aSelector;

/* Special Group Access Methods */

- (ETLayoutItemGroup *) windowGroup;
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

@end

/** Line separator minimum width or height depending on the layout orientation 
(vertical vs horizontal). */
extern const NSUInteger kETLineSeparatorMinimumSize;
/** Line separator item name. */
extern NSString * const kETLineSeparatorItemIdentifier;
/** Space item name. */
extern NSString * const kETSpaceSeparatorItemIdentifier;
/** Flexible space item name. */
extern NSString * const kETFlexibleSpaceSeparatorItemIdentifier;
