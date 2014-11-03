/**
	Copyright (C) 2007 Eric Wasylishen

	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETCompatibility.h>
#import <EtoileUI/ETStyle.h>

/** @abstract Draws an existing style tinted with a color.

Warning: Unstable API. */
@interface ETTintStyle : ETStyle
{
	@private
	ETStyle *_content;
	NSColor *_color;
}

+ (id) tintWithStyle: (ETStyle *)style color: (NSColor *)color objectGraphContext: (COObjectGraphContext *)aContext;
+ (id) tintWithStyle: (ETStyle *)style objectGraphContext: (COObjectGraphContext *)aContext;
- (id) initWithStyle: (ETStyle *)style objectGraphContext: (COObjectGraphContext *)aContext;
- (void) setColor: (NSColor *)color;
- (NSColor *) color;

@end
