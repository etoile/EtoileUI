/** <title>ETTemplateItemLayout</title>

	<abstract>A layout subclass that formalizes and simplifies temporary layout 
	item customization.</abstract>

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
When a new layout is set on the layout context, every item will have its 
overriden properties reverted back to their original values.

For example, you may want to display a custom and temporary view per layout 
item without altering their usual display outside of this layout.

-setTemplateItem: and -setTemplateKeys: let you specify how the layout will 
customize the items handed by the layout context. 
Here is a short example to create a IM-like area where each item will be 
drawn inside a speech bubble and laid out vertically with some space around 
each one:
<code>
ETTemplateItemLayout *chatLayout = [ETTemplateItemLayout layout];
ETLayoutItem *item = [[ETLayoutItemFactory factory] item];
ETLayoutItemGroup *chatAreaItem = [[ETLayoutItemFactory factory] itemGroup];

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

To override the item properties, ETTemplateItemLayout uses Key Value Coding and 
not Property Value Coding since the latter would only give access to the model 
side when the item has a represented object. Key Value Coding when invoked on 
a layout item consistenly read and write the item properties and will never try 
to read and write its represented object properties.<br />
This point means you cannot override properties set on the represented object 
or include key paths in the array returned by -templateKeys. We were unable 
to find a use case where this would be really be needed, that's why we chose 
not to support it.

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
