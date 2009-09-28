/** <title>ETTemplateItemLayout</title>

	<abstract>A layout subclass that formalizes and simplifies the 
	composition of layouts.</abstract>

	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayout.h>

@class ETLayoutItem;

/** ETTemplateItemLayout is a layout that allows to temporarily override 
layout item properties, in order to deeply customize the item look and behavior.

For example, you may want to display a custom and temporary view per layout 
item without altering their usual display outside of this layout.

-setTemplateItem: and -setTemplateKeys: lets you specify how the layout will 
customize the items handed by the layout context. 
Here is a short example to create a IM-like area where each item will be 
drawn inside a speech bubble and laid out vertically with some space around 
each one:
<code>
ETTemplateItemLayout *bubbleLayout = [ETTemplateItemLayout layout];
ETLayoutItem *item = [[ETUIItemFactory factory] item];
ETLayoutItemGroup *chatAreaItem = [[ETUIItemFactory factory] itemGroup];

[item setStyle: [ETSpeechBubbleStyle style]];
[chatLayout setTemplateItem: item];
[chatLayout setTemplateKeys: A(kETStyleProperty)];
[chatLayout setPositionalLayout: [ETColumnLayout layout]];
[[chatLayout positionalLayout] setItemMargin: 15];

[chatAreaItem setLayout: chatLayout];
</code>

The item positioning and sizing is always delegated the layout returned by 
-positionalLayout. You can pass any layout that conforms to ETPositionalLayout 
protocol to -setPositionalLayout: to change how the items are organized spatially.

See ETFormLayout and ETIconLayout subclasses to better understand what is 
possible and how to use ETTemplateItemLayout. */
@interface ETTemplateItemLayout : ETLayout <ETCompositeLayout, ETLayoutingContext>
{
	id <ETPositionalLayout> _positionalLayout;
	ETLayoutItem *_templateItem;
	/* All the items that got rendered since the layout has been set up */
	NSMutableSet *_renderedItems; 
	NSArray *_templateKeys;
	NSMutableDictionary *_localBindings;

}

- (ETLayoutItem *) templateItem;
- (void) setTemplateItem: (ETLayoutItem *)item;
- (NSArray *) templateKeys;
- (void) setTemplateKeys: (NSArray *)keys;

- (void) bindTemplateItemKeyPath: (NSString *)templateKeyPath 
               toItemWithKeyPath: (NSString *)itemProperty;
- (void) unbindTemplateItem;

- (id <ETPositionalLayout>) positionalLayout;
- (void) setPositionalLayout: (id <ETPositionalLayout>)layout;

/* Subclass Hooks */

- (void) setUpTemplateElementsForItem: (ETLayoutItem *)item;
- (void) setUpKVOForItem: (ETLayoutItem *)item;
- (void) tearDownKVO;

- (void) tearDown;
- (void) prepareNewItems: (NSArray *)items;
- (void) restoreAllItems;

/* Layouting */

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent;

@end


@interface ETFormLayout : ETTemplateItemLayout
{
	NSFont *_itemLabelFont;
	NSTextAlignment _itemLabelAlignment;
	NSTextAlignment _alignment;
	float highestLabelWidth;
}

/*- (void) setAlignment: (NSTextAlignment)alignment;
- (void) setItemLabelFont: (NSFont *)font;
- (void) setItemLabelAlignment: (NSTextAlignment)alignment;
-setInsertSeparatorBetweenGroups*/

@end
