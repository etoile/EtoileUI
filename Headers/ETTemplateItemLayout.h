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

/** ETTemplateItemLayout is a layout that allows to substitute the child items 
    of the layout context by others, in order to deeply customize the look of 
	each layouted item.
	For example, you may want to display a custom and temporary view per layout 
	item without altering their usual display outside of this layout.
	The items of the layout context are used as represented objects of the new 
	ones. The new displayed items which are created by cloning a template item. 
	When this layout is active, the original items of the layout context are 
	never displayed. However you get the illusion they are and you manipulate 
	them, because the temporary items are symetric and replicate all changes 
	applied to them by treating the original items as model objects. 
	
	-itemAtLocation: to return to return the real item and not the replacement 
	item. If the selection state changes in the layout context, it will get 
	transparently applied to the replacement items on the next display update, 
	because the replacement item selected property... No, selection state is 
	isn't inherited by meta items from their represented items. */
@interface ETTemplateItemLayout : ETLayout <ETCompositeLayout, ETLayoutingContext>
{
	id <ETPositionalLayout> _positionalLayout;
	ETLayoutItem *_templateItem;
	NSMutableArray *_replacementItems;
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
