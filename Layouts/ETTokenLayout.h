/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD (see COPYING)
*/

#import <EtoileUI/ETTemplateItemLayout.h>
#import <EtoileUI/ETActionHandler.h>
#import <EtoileUI/ETBasicItemStyle.h>

@interface ETTokenLayout : ETTemplateItemLayout
{
	@private
	NSFont *_itemLabelFont;
	CGFloat _maxTokenWidth;
}

/** @taskunit Token Look */

- (void) setItemTitleFont: (NSFont *)font;

/** @taskunit Token Sizing */

+ (CGFloat) defaultTokenHeight;
+ (CGFloat) defaultMaxTokenWidth;

- (CGFloat) maxTokenWidth;
- (void) setMaxTokenWidth: (CGFloat)aWidth;

@end


@interface ETTokenStyle : ETBasicItemStyle
{
	@private
	NSColor *_tintColor;
	NSDictionary *_selectedLabelAttributes;
}

- (void) setTintColor: (NSColor *)color;
- (NSColor *) tintColor;

- (void) drawRoundedTokenInRect: (NSRect)indicatorRect isSelected: (BOOL)isSelected;

@end


@interface ETTokenActionHandler : ETActionHandler
- (void) handleClickItem: (ETLayoutItem *)item atPoint: (NSPoint)aPoint;
@end
