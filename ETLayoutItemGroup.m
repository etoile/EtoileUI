/*  <title>ETLayoutItemGroup</title>

	ETLayoutItemGroup.m
	
	<abstract>Description forthcoming.</abstract>
 
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

#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETContainer.h>
#import <EtoileUI/GNUstep.h>

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
