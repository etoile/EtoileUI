/*
	ETComputedLayout.h
	
	An abstract layout class whose subclasses position items by computing their 
	location based on a set of rules.
 
	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date: July 2008
 
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
#import <EtoileUI/ETLayout.h>

@class ETLayoutLine, ETContainer;


/** ETComputedLayout is a basic abstract class that must be subclassed by all 
    classes that are expected to implement a layout algorithm that only consists 
	of positioning layout items. The logic of the algorithm must be strictly 
	positional and not touch anything else than the item frame, scale and 
	rotation.
	All subclasses must not replace the item tree of the layout context 
	by hiding its child item, as ETCompositeLayout or ETTemplateItemLayout do 
	when they their display their layout item tree. */
@interface ETComputedLayout : ETLayout <ETPositionalLayout>
{
	float _itemMargin;
}

- (void) setItemMargin: (float)margin;
- (float) itemMargin;

- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent;

/* Line-based Layout */

- (ETLayoutLine *) layoutLineForLayoutItems: (NSArray *)items;
- (NSArray *) layoutModelForLayoutItems: (NSArray *)items;
- (void) computeLayoutItemLocationsForLayoutModel: (NSArray *)layoutModel;

@end
