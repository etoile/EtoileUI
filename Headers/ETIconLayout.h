/** <title>ETIconLayout</title>

	<abstract>A layout subclass to present layout items in an icon view.</abstract>

	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
	License:  Modified BSD (see COPYING)
*/

#import <EtoileUI/ETTemplateItemLayout.h>


@interface ETIconLayout : ETTemplateItemLayout
{
	NSFont *_itemLabelFont;
}

- (void) setItemTitleFont: (NSFont *)font;

@end
