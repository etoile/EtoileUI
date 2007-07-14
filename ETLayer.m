/*  <title>ETLayer</title>

	ETLayer.m
	
	<abstract>Layer class models the traditional layer element, very common in 
	Computer Graphics applications.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  May 2007
 
	Redistribution and use in source and binary forms, with or without
	modification, are permitted provided that the following conditions are met:

	* Redistributions of source code must retain the above copyright notice,
	  this list of conditions and the following disclaimer.
	* Redistributions in binary form must reproduce the above copyright notice,
	  this list of conditions and the following disclaimer in the documentation
	  and/or other materials provided with the distribution.
	* Neither the name of the Etoile project nor the names of its contributors
	  may be used to endorse or promote products derived from this software
	  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
	LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
	THE POSSIBILITY OF SUCH DAMAGE.
 */
 
#import "ETLayer.h"
#import "ETContainer.h"
#import "GNUstep.h"

#define DEFAULT_FRAME NSMakeRect(0, 0, 200, 200)


@implementation ETLayer

+ (ETLayer *) layer
{
	return (ETLayer *)AUTORELEASE([[self alloc] init]);
}

+ (ETLayer *) layerWithLayoutItem: (ETLayoutItem *)item
{	
	return [ETLayer layerWithLayoutItems: [NSArray arrayWithObject: item]];
}

+ (ETLayer *) layerWithLayoutItems: (NSArray *)items
{
	ETLayer *layer = [[self alloc] init];
	
	if (layer != nil)
	{
		[(ETContainer *)[layer view] addItems: items];
	}
	
	return (ETLayer *)AUTORELEASE(layer);
}

+ (ETLayer *) guideLayer
{
	return (ETLayer *)AUTORELEASE([[self alloc] init]);
}

+ (ETLayer *) gridLayer
{
	return (ETLayer *)AUTORELEASE([[self alloc] init]);
}

- (id) init
{
	ETContainer *containerAsLayer = [[ETContainer alloc] initWithFrame: DEFAULT_FRAME];
	
	AUTORELEASE(containerAsLayer);
    self = (ETLayer *)[super initWithView: (NSView *)containerAsLayer];
    
    if (self != nil)
    {
		_visible = YES;
		_outOfFlow = YES;
    }
    
    return self;
}

/** Sets whether the layer view has its frame bound to the one of its parent 
	container or not.
	If you change the value to NO, the layer view will be processed during 
	layout rendering as any other layout items. 
	See -movesOutOfLayoutFlow for more details. */
- (void) setMovesOutOfLayoutFlow: (BOOL)floating
{
	_outOfFlow = floating;
}

/** Returns whether the layer view has its frame bound to the one of its parent 
	container. Layouts items are usually displayed in some kind of flow unlike
	layers which are designed to float over their parent container layout.
	Returns YES by default. */
- (BOOL) movesOutOfLayoutFlow
{
	return _outOfFlow;
}

- (void) setVisible: (BOOL)visibility
{
	_visible = visibility;
}

- (BOOL) isVisible
{
	return _visible;
}

@end
