/**
	Copyright (C) 2007 Eric Wasylishen

	Date:  November 2007
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETCompatibility.h>
#import <EtoileUI/ETStyle.h>

@class COObjectGraphContext;

/** @abstract Draws a shadow. */
@interface ETShadowStyle : ETStyle
{
	@private
	ETStyle *_content;
	NSShadow *_shadow;
}

+ (id) shadowWithStyle: (ETStyle *)style objectGraphContext: (COObjectGraphContext *)aContext;
- (id) initWithStyle: (ETStyle *)style objectGraphContext: (COObjectGraphContext *)aContext;

@end
