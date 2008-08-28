/*  <title>ETComputedLayout</title>

	ETComputedLayout.m

	<abstract>An abstract layout class whose subclasses position items by 
	computing their location based on a set of rules.</abstract>

	Copyright (C) 2008 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2008
 
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

#import <EtoileUI/ETComputedLayout.h>
#import <EtoileUI/ETCompatibility.h>


@implementation ETComputedLayout

- (BOOL) isComputedLayout
{
	return YES;
}

/** Sets the size of the margin around each item to be layouted and triggers a 
    layout update. */
- (void) setItemMargin: (float)aMargin
{
	_itemMargin = aMargin;

	// TODO: Evaluate whether we should add an API at ETLayout level to request 
	// layout refresh, or rather remove this code and let the developer triggers
	// the layout update.
	if ([self isRendering] == NO)
	{	
		[self render: nil isNewContent: NO];
		[[self layoutContext] setNeedsDisplay: YES];
	}
}

/** Returns the size of the margin around each item to be layouted. */
- (float) itemMargin
{
	return _itemMargin;
}

@end
