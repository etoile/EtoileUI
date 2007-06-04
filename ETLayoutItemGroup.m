//
//  ETLayoutItemGroup.m
//  Container
//
//  Created by Quentin Mathé on 31/05/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ETLayoutItemGroup.h"
#import "ETContainer.h"
#import "GNUstep.h"

#define DEFAULT_FRAME NSMakeRect(0, 0, 50, 50)


@implementation ETLayoutItemGroup

+ (ETLayoutItemGroup *) layoutItemGroup
{
	return AUTORELEASE([[self alloc] init]);
}

+ (ETLayoutItemGroup *) layoutItemGroupWithLayoutItem: (ETLayoutItem *)item
{
	return [ETLayoutItemGroup layoutItemGroupWithLayoutItem: [NSArray arrayWithObject: item]];
}

+ (ETLayoutItemGroup *) layoutItemGroupWithLayoutItems: (NSArray *)items
{
	return AUTORELEASE([[self alloc] initWithLayoutItems: items view: nil]);
}

+ (ETLayoutItem *) layoutItemWithView: (NSView *)view
{
	return AUTORELEASE([[self alloc] initWithLayoutItems: nil view: view]);
}

/** Designated initialize */
- (id) initWithLayoutItems: (NSArray *)layoutItems view: (NSView *)view
{
	ETContainer *containerAsLayoutItemGroup = 
		[[ETContainer alloc] initWithFrame: DEFAULT_FRAME];
		
	AUTORELEASE(containerAsLayoutItemGroup);
    self = (ETLayoutItemGroup *)[super initWithView: (NSView *)containerAsLayoutItemGroup];
    
    if (self != nil)
    {
		if ([[self view] isKindOfClass: [ETContainer class]] == NO)
		{
			if ([self view] == nil)
			{
				NSLog(@"WARNING: New %@ must have a container as view and not nil", self);
			}
			else
			{
				NSLog(@"WARNING: New %@ must embed a container and not another view %@", self, [self view]);
			}
			return nil;
		}
		
		if (layoutItems != nil)
			[(ETContainer *)[self view] addItems: layoutItems];
		if (view != nil)
		{
			[view removeFromSuperview]; // Note sure we should pay heed to such case
			[view setFrame: [[self view] frame]];
			[(ETContainer *)[self view] addSubview: view];
		}
    }
    
    return self;
}

- (id) init
{
	return [self initWithLayoutItems: nil view: nil];
}

- (NSArray *) ungroup
{
	return nil;
}

/* Stacking */

- (void) stack
{

}

- (void) unstack
{

}

@end
