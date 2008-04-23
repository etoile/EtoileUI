/*  <title>ETStyle</title>

	ETStyle.m
	
	<abstract>Generic object chain class to implement late-binding of behavior
	through delegation.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  November 2007
 
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

#import <EtoileUI/ETStyle.h>


@implementation ETStyle

/** Returns a new style connected to an existing style. */
- (id) initWithStyle: (ETStyle *)style
{
	return [self initWithObject: style];
}

/** <init /> Returns a new style by chaining styles passed in parameter. */
- (id) initWithCollection: (id <ETCollection>)styles
{
	return [super initWithCollection: styles];
}

/** Returns the style following the receiver in the style chain. */
- (ETStyle *) nextStyle
{
	return (ETStyle *)[self nextObject];
}

/** Sets the style following the receiver in the style chain. 
	Take note this method discards the existing next style and the whole 
	style chain connected to it. If you want to reconnect the existing 
	next style, it's up to you to handle it. */
- (void) setNextStyle: (ETStyle *)style
{
	[self setNextObject: style];
}

/** Returns the style terminating the style chain the receiver belongs
	to. In other words, returns the first style that has no next style 
	connected to it. */
- (ETStyle *) lastStyle
{
	return (ETStyle *)[self lastObject];
}

/** Returns the selector uses for style rendering which is equal to -render:
	if you don't override the method. 
	Try also to override -render: if you override this method, so you your 
	custom styles can be used in other style chains in some sort of fallback
	mode. */
- (SEL) styleSelector
{
	return @selector(render:);
}

/** Renders object with the style chain by passing the parameter from 
	style-to-style with the order resulting from calling -nextStyle on each
	style.
	When overriding this method, you should usually handle the receiver 
	rendering before delegating it to the rest of the style chain. This 
	implies using return [super render: object] at the end of the overriden 
	method. */
- (id) render: (id)object
{
	return [[self nextStyle] render: object];
}

@end
