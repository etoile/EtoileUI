/** <title>ETFlowLayout</title>

	<abstract>A layout class that organize items in an horizontal flow and
	starts a new line each time the content width is filled.</abstract>

	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETComputedLayout.h>


/** See [ETComputedLayout] API to customize ETFlowLayout look and behavior.

ETFlowLayout overrides several property values defined by ETLayout and 
ETComputedLayout:
<list>
<item>itemSizeConstraintStyle to apply to width and height</item> 
<item>constrainedItemSize to a 256 * 256 px size</item>
<item>itemMargin to a 15 px border</item>
</list>
 
For now, -layoutSizeConstraintStyle only supports 
ETSizeConstraintStyleHorizontal which means items are laid out into horizontal
lines inside the content height. This height is unlimited if -isContentSizeLayout
returns YES, otherwise the content height will match the proposed layout size 
(see -layoutSize). */
@interface ETFlowLayout : ETComputedLayout 
{
	@private
	ETSizeConstraintStyle _layoutConstraint;
	BOOL _usesGrid;
}

/** @taskunit Flow Constraining and Streching */

@property (nonatomic) ETSizeConstraintStyle layoutSizeConstraintStyle;

/** @taskunit Additions */

@property (nonatomic) BOOL usesGrid;

@end
