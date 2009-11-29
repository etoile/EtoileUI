/** <title>ETIconLayout</title>

	<abstract>A layout subclass to present layout items in an icon view.</abstract>

	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
	License:  Modified BSD (see COPYING)
*/

#import <EtoileUI/ETTemplateItemLayout.h>
#import <EtoileUI/ETActionHandler.h>
#import <EtoileUI/ETBasicItemStyle.h>


@interface ETIconLayout : ETTemplateItemLayout
{
	NSFont *_itemLabelFont;
	NSSize _iconSizeForScaleFactorUnit;
	NSSize _minIconSize;
}

- (void) setItemTitleFont: (NSFont *)font;

/* Icon Sizing */

- (NSSize) iconSizeForScaleFactorUnit;
- (void) setIconSizeForScaleFactorUnit: (NSSize)aSize;
- (NSSize) minIconSize;
- (void) setMinIconSize: (NSSize)aSize;

@end

@interface ETIconAndLabelStyle : ETBasicItemStyle

@end

@interface ETIconAndLabelActionHandler : ETActionHandler
- (void) handleClickItem: (ETLayoutItem *)item atPoint: (NSPoint)aPoint;
@end
