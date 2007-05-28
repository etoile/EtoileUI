//
//  ETLineView.m
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 26/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ETLineView.h"
#import "ETLineLayout.h"


@implementation ETLineView

- (id) initWithFrame: (NSRect)frame 
{
    self = [super initWithFrame: frame];
	
    if (self != nil) 
	{
		[self setLayout: AUTORELEASE([[ETLineLayout alloc] init])];
    }
	
    return self;
}

@end
