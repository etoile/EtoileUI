/** <title>ETFlowLayout</title>

	<abstract>A layout class that organize items in an horizontal flow and
	starts a new line each time the content width is filled.</abstract>

	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETComputedLayout.h>


/** ETFlowLayout overrides several property values defined by ETLayout and 
ETComputedLayout:
<list>
<item>itemSizeConstraintStyle to apply to width and height</item> 
<item>constrainedItemSize to a 256 * 256 px size</item>
<item>itemMargin to a 15 px border</item>
</list> */
@interface ETFlowLayout : ETComputedLayout 
{
	@private
	ETSizeConstraintStyle _layoutConstraint;
	BOOL _grid;
}

/* Flow Constraining and Streching */

- (void) setLayoutSizeConstraintStyle: (ETSizeConstraintStyle)constraint;
- (ETSizeConstraintStyle) layoutSizeConstraintStyle;

/* Additions */

- (BOOL) usesGrid;
- (void) setUsesGrid: (BOOL)constraint;

@end
