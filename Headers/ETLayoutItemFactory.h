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

@class ETLayoutItem, ETLayoutItemGroup, ETScrollableAreaItem, ETWindowItem, 
ETStyle, ETActionHandler;


@interface ETLayoutItemFactory : NSObject
{
	@private
	BOOL _isCreatingRootObject;
	ETStyle *_currentCoverStyle;
	ETActionHandler *_currentActionHandler;
	ETStyle *_currentBarElementStyle;
	float _currentBarElementHeight;
}

+ (instancetype) factory;

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
- (ETLayoutItemGroup *) itemGroupWithSize: (NSSize)aSize;
- (ETLayoutItemGroup *) itemGroupWithItem: (ETLayoutItem *)item;
- (ETLayoutItemGroup *) itemGroupWithItems: (NSArray *)items;
- (ETLayoutItemGroup *) itemGroupWithValue: (id)value;
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
- (id) horizontalSliderWithWidth: (float)aWidth 
                        minValue: (float)min 
                        maxValue: (float)max
                    initialValue: (float)aValue 
                          target: (id)aTarget 
                          action: (SEL)aSelector;
- (id) horizontalSliderWithWidth: (float)aWidth
                        minValue: (float)min 
                        maxValue: (float)max
                     forProperty: (NSString *)aKey
                         ofModel: (id)anObject;
- (id) stepper;
- (ETLayoutItem *) numberPicker;
- (ETLayoutItem *) numberPickerWithWidth: (CGFloat)aWidth
                                minValue: (CGFloat)min
                                maxValue: (CGFloat)max
                            initialValue: (CGFloat)aValue
                                  target: (id)aTarget
                                  action: (SEL)aSelector
                             forProperty: (NSString *)aKey
                                 ofModel: (id)anObject;
- (id) popUpMenuWithItemTitles: (NSArray *)entryTitles 
            representedObjects: (NSArray *)entryModels 
                        target: (id)aTarget 
                        action: (SEL)aSelector;

/* Special Group Access Methods */

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
