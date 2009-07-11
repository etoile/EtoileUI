/** <title>ETLineLayout</title>
	
	<abstract>A layout class that organize items in a single horizontal line or 
	row.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */
 
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETFlowLayout.h>

/** ETLineLayout overrides the following property values defined by ETFlowLayout:
<list>
<item>itemSizeConstraintStyle to be disabled</item>
<item>itemMargin to a 0 px border</item>
</list> */
@interface ETLineLayout : ETFlowLayout
{

}

@end
