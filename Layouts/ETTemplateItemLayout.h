/** <title>ETTemplateItemLayout</title>

	<abstract>A layout subclass that formalizes and simplifies temporary layout 
	item customization.</abstract>

	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETLayout.h>
#import <EtoileUI/ETComputedLayout.h>

@class ETLayoutItem, ETBasicItemStyle;

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

<example>
ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factoryWithObjectGraphContext: someContext];
ETLayoutItem *item = [itemFactory item];
ETLayoutItemGroup *chatAreaItem = [itemFactory itemGroup];
ETTemplateItemLayout *chatLayout = [ETTemplateItemLayout layoutWithObjectGraphContext: someContext];
 
[item setCoverStyle: nil]
[item setStyle: [ETSpeechBubbleStyle styleWithObjectGraphContext: someContext]];
[chatLayout setTemplateItem: item];
[chatLayout setTemplateKeys: A(kETCoverStyleProperty, kETStyleProperty)];
[chatLayout setPositionalLayout: [ETColumnLayout layoutWithObjectGraphContext: someContext];
[[chatLayout positionalLayout] setItemMargin: 15];

[chatAreaItem setLayout: chatLayout];
</example>

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
	@private
	id <ETComputableLayout> _positionalLayout;
	ETLayoutItem *_templateItem;
	NSMutableArray *_templateKeys;
	NSMutableDictionary *_localBindings;
	/* All the items that got rendered since the layout has been set up */
	NSMutableSet *_renderedItems;
	NSArray *_renderedTemplateKeys;
	BOOL _needsPrepareItems;
}

- (ETLayoutItem *) templateItem;
- (void) setTemplateItem: (ETLayoutItem *)item;
- (NSArray *) templateKeys;
- (void) setTemplateKeys: (NSArray *)keys;

- (void) bindTemplateItemKeyPath: (NSString *)templateKeyPath 
               toItemWithKeyPath: (NSString *)itemProperty;
- (void) unbindTemplateItem;

- (id <ETComputableLayout>) positionalLayout;
- (void) setPositionalLayout: (id <ETComputableLayout>)layout;

/* Subclass Hooks */

- (BOOL) ignoresItemScaleFactor;

- (void) setUpTemplateElementsForItem: (ETLayoutItem *)item;
- (void) setUpTemplateElementWithNewValue: (id)templateValue
                                   forKey: (NSString *)aKey
                                   inItem: (ETLayoutItem *)anItem;
- (void) setUpKVOForItem: (ETLayoutItem *)item;
- (void) tearDownKVO;

- (void) tearDown;
- (void) prepareNewItems: (NSArray *)items;
- (void) restoreAllItems;
- (void) willRenderItems: (NSArray *)items isNewContent: (BOOL)isNewContent;

/* Layouting */

- (NSSize) renderWithItems: (NSArray *)items isNewContent: (BOOL)isNewContent;

@end
