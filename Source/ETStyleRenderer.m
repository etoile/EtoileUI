/*  <title>ETStyleRenderer</title>

	ETStyleRenderer.m
	
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

#import <EtoileUI/ETStyleRenderer.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/ETCompatibility.h>


@implementation ETSelection

- (id) init
{
	self = [super init];

    if (self != nil)
    {
        [self setDrawingShape: [NSBezierPath bezierPathWithRect: NSMakeRect(0, 0, 100, 100)]];
        [self setEditingShape: [NSBezierPath bezierPathWithRect: NSMakeRect(0, 0, 200, 200)]];
        [self setOutlineColor: [NSColor darkGrayColor]];
        [self setInteriorColor: [NSColor lightGrayColor]];
        [self setAlphaValue: 0.5];
        [self setHidden: NO];
    }
	
    return self;
}

- (void) dealloc
{
    DESTROY(_drawingShape);
    DESTROY(_editingShape);
    DESTROY(_outlineColor);
    DESTROY(_interiorColor);
    [super dealloc];
}

- (NSBezierPath *) drawingShape
{
    return AUTORELEASE([_drawingShape copy]); 
}

- (void) setDrawingShape: (NSBezierPath *)shape
{
    ASSIGN(_drawingShape, [shape copy]); 
}

- (NSBezierPath *) editingShape
{
    return AUTORELEASE([_editingShape copy]); 
}

- (void) setEditingShape: (NSBezierPath *)shape
{
    ASSIGN(_editingShape, [shape copy]); 
}

- (NSColor *) outlineColor
{
    return AUTORELEASE([_outlineColor copy]); 
}

- (void) setOutlineColor: (NSColor *)color
{
	ASSIGN(_outlineColor, [color copy]);
}

- (NSColor *) interiorColor
{
    return AUTORELEASE([_interiorColor copy]); 
}

- (void) setInteriorColor: (NSColor *)color
{
	ASSIGN(_interiorColor, [color copy]);
}

- (float) alphaValue
{
    return _alpha;
}

- (void) setAlphaValue: (float)newAlpha
{
    _alpha = newAlpha;
}

- (BOOL) hidden
{
    return _hidden;
}

- (void) setHidden: (BOOL)flag
{
    _hidden = flag;
}

- (void) renderLayoutItem: (ETLayoutItem *)item
{
	NSRect itemRect = ETMakeRect([item origin], [item size]);
	if ([item isSelected])
	{
		NSLog(@"Draw selection for %@", item);
		[self drawInRect: NSInsetRect(itemRect, 30, 30)];
	}
}

- (void) drawInRect: (NSRect)rect
{
	[[NSColor redColor] set];
	NSRectFill(rect);
}

@end
