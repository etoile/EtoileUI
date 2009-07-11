/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETLineLayout.h"


@implementation ETLineLayout

- (id) init
{
	SUPERINIT
	
	/* Overriden default property values */
	[self setItemSizeConstraintStyle: ETSizeConstraintStyleNone];
	[self setItemMargin: 0];
	
	return self;
}

- (ETSizeConstraintStyle) layoutSizeConstraintStyle
{
	// NOTE: We use this constrain value to express our needs because
	// ETFlowLayout doesn't use it.
	return ETSizeConstraintStyleNone;
}

@end
