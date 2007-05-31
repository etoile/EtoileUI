//
//  ETLayer.h
//  Container
//
//  Created by Quentin Mathé on 30/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ETLayoutItem.h"


@interface ETLayer : ETLayoutItem 
{
	BOOL _visible;
	BOOL _outOfFlow;
}

+ (ETLayer *) layer;
+ (ETLayer *) layerWithLayoutItem: (ETLayoutItem *)item;
+ (ETLayer *) layerWithLayoutItems: (NSArray *)items;
+ (ETLayer *) guideLayer;
+ (ETLayer *) gridLayer;

- (void) setMovesOutOfLayoutFlow: (BOOL)floating;
- (BOOL) movesOutOfLayoutFlow;

/*- (void) setVisible;
- (BOOL) isVisible;*/

@end
