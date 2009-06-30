/*
	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  June 2009
	License:  Modified BSD (see COPYING)
 */

#import "ETPaintActionHandler.h"
#import "ETLayoutItem.h"
#import "ETShape.h"
#import "ETStyle.h"
#import "ETCompatibility.h"


@implementation ETActionHandler (ETPaintActionHandler)

- (BOOL) canFill: (ETLayoutItem *)item
{
	return [[item style] respondsToSelector: @selector(setFillColor:)];
}

- (BOOL) canStroke: (ETLayoutItem *)item
{
	return [[item style] respondsToSelector: @selector(setStrokeColor:)];
}

- (void) handleFill: (ETLayoutItem *)item withColor: (NSColor *)aColor
{
	[[item style] setFillColor: aColor];
	[item setNeedsDisplay: YES];
}

- (void) handleStroke: (ETLayoutItem *)item withColor: (NSColor *)aColor
{
	[[item style] setStrokeColor: aColor];
	[item setNeedsDisplay: YES];
}

@end
