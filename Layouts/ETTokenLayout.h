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
	NSString *_editedProperty;
	NSFont *_itemLabelFont;
	CGFloat _maxTokenWidth;
}

/** @taskunit Editing */

/** The edited property of the template item action handler.
 
You must not access this property if the template item action handler is not a 
ETTokenActionHandler.
 
See -[ETTemplateItemLayout templateItem] and -[ETTokenActionHandler editedProperty]. */
@property (nonatomic, retain) NSString *editedProperty;

/** @taskunit Token Look */

@property (nonatomic, retain) NSFont *itemLabelFont;

/** @taskunit Token Sizing */

+ (CGFloat) defaultTokenHeight;
+ (CGFloat) defaultMaxTokenWidth;

/** The maximum token width allowed.
 
By default, returns -defaultMaxTokenWidth.
 
See also -resizeLayoutItems:toScaleFactor:. */
@property (nonatomic, assign) CGFloat maxTokenWidth;

@end


@interface ETTokenStyle : ETBasicItemStyle
{
	@private
	NSColor *_tintColor;
}

@property (nonatomic, retain) NSColor *tintColor;

- (void) drawRoundedTokenInRect: (NSRect)indicatorRect isSelected: (BOOL)isSelected;

@end

@interface ETTokenActionHandler : ETActionHandler
{
	@private
	NSString *_editedProperty;
}

@property (nonatomic, retain) NSString *editedProperty;

- (void) handleDoubleClickItem: (ETLayoutItem *)item;
@end

@interface ETTokenBackgroundActionHandler : ETActionHandler
- (void) handleClickItem: (ETLayoutItem *)item atPoint: (NSPoint)aPoint;
@end
