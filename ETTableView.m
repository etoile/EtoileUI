//
//  ETTableView.m
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 26/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ETTableView.h"
#import "ETTableLayout.h"
#import "GNUstep.h"


@implementation ETTableView

- (id) initWithFrame: (NSRect)frame 
{
    self = [super initWithFrame: frame];
	
    if (self != nil) 
	{
		[self setLayout: (ETViewLayout *)AUTORELEASE([[ETTableLayout alloc] init])];
    }
	
    return self;
}

@end
