//
//  ETFlowView.m
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 26/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ETFlowView.h"
#import "ETFlowLayout.h"
#import "GNUstep.h"


@implementation ETFlowView

- (id) initWithFrame: (NSRect)frame 
{
    self = [super initWithFrame: frame];
	
    if (self != nil) 
	{
		[self setLayout: (ETViewLayout *)AUTORELEASE([[ETFlowLayout alloc] init])];
    }
	
    return self;
}

@end