/*
	ETLayoutItemGroup.h
	
	Description forthcoming.
 
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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "ETLayoutItem.h"


@interface ETLayoutItemGroup : ETLayoutItem
{
	BOOL _usesLayoutBasedFrame;
}

+ (ETLayoutItemGroup *) layoutItemGroup;
+ (ETLayoutItemGroup *) layoutItemGroupWithLayoutItem: (ETLayoutItem *)item;
+ (ETLayoutItemGroup *) layoutItemGroupWithLayoutItems: (NSArray *)items;

- (id) initWithLayoutItems: (NSArray *)layoutItems view: (NSView *)view;

- (NSArray *) items;

- (BOOL) usesLayoutBasedFrame;
- (void) setUsesLayoutBasedFrame: (BOOL)flag;

- (NSArray *) visibleLayoutItems;
- (void) setVisibleLayoutItems: (NSArray *)items;

- (void) render: (NSMutableDictionary *)inputValues dirtyRect: (NSRect)dirtyRect inView: (NSView *)view;

//- isContainer

// NOTE: Note sure it's really doable to provide such methods. May only work in
// a safe way if we provide it as part of ETContainer API
- (NSArray *) ungroup;
/* Take a note +group: is +layoutItemGroupWithLayoutItems: */

/* Stacking */

/*- (ETViewLayout *) stackedItemLayout;
- (void) setStackedItemLayout: (ETViewLayout *)layout;
- (ETViewLayout *) unstackedItemLayout;
- (void) setUnstackedItemLayout: (ETViewLayout *)layout;*/

- (void) stack;
- (void) unstack;

@end
