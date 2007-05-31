//
//  ETLayer.m
//  Container
//
//  Created by Quentin Mathé on 30/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

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
