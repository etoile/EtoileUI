/**
	Copyright (C) 2016 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2016
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>

/** The insets to apply a rect for each edge.

Positive values grow the rect, while negative ones shrink it (this is the 
inverse of NSEdgetInsets). */
typedef struct ETEdgeInsets
{
    CGFloat top;
    CGFloat left;
    CGFloat bottom;
    CGFloat right;
} ETEdgeInsets;
