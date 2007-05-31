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

#define DEFAULT_FRAME NSMakeRect(0, 0, 200, 200)


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
	ETLayoutItemGroup *layoutItemGroup = [[self alloc] init];
	
	if (layoutItemGroup != nil)
	{
		[(ETContainer *)[layoutItemGroup view] addItems: items];
	}
	
	return AUTORELEASE(layoutItemGroup);
}

- (id) init
{
	ETContainer *containerAsLayoutItemGroup = 
		[[ETContainer alloc] initWithFrame: DEFAULT_FRAME];
		
	AUTORELEASE(containerAsLayoutItemGroup);
    self = (ETLayoutItemGroup *)[super initWithView: (NSView *)containerAsLayoutItemGroup];
    
    if (self != nil)
    {

    }
    
    return self;
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
