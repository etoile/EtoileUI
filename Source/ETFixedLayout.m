/*
	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2009
	License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import "ETFixedLayout.h"
#import "ETCompatibility.h"


@implementation ETFixedLayout

/** Always returns YES since items are positioned based on their persistent 
geometry. */
- (BOOL) isPositional
{
	return YES;
}

/** Always returns NO since items are positioned based on their persistent 
geometry and not computed by the receiver. */
- (BOOL) isComputedLayout
{
	return NO;
}

@end
