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

/** @abstract Draws a speech bubble around the item to which this style is 
applied. */
@interface ETSpeechBubbleStyle : ETStyle
{
	@private
	ETStyle *_content;
}

+ (id) speechWithStyle: (ETStyle *)style objectGraphContext: (COObjectGraphContext *)aContext;
- (id) initWithStyle: (ETStyle *)style objectGraphContext: (COObjectGraphContext *)aContext;

@end
