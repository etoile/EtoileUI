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
#import <EtoileUI/ETShape.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/ETCompatibility.h>

@implementation ETSelectionAreaItem

- (id) initWithView: (NSView *)view value: (id)value representedObject: (id)repObject;
{
	self = [super initWithView: view value: value representedObject: repObject];
	if (self == nil)
		return nil;
	
	ETShape *shape = [ETShape rectangleShapeWithRect: NSMakeRect(0, 0, 100, 50)];

	[shape setStrokeColor: [NSColor darkGrayColor]];
	[shape setFillColor: [NSColor lightGrayColor]];
	[shape setAlphaValue: 0.5];
	[self setRepresentedObject: shape];
	[self setStyle: shape];

    return self;
}

- (void) setFrame: (NSRect)rect
{
	[super setFrame: rect];
	NSRect bounds = ETMakeRect(NSZeroPoint, rect.size);
	[[self representedObject] setBounds: bounds];
	[self setBoundingBox: NSInsetRect(bounds, -5, -5)]; // FIXME: Handle this properly
	//[[self representedObject] setPath: [NSBezierPath bezierPathWithRect: rect]];
}

@end

#if 0
@implementation ETSelection

- (id) init
{
	SUPERINIT
	
	[self setDrawingShape: [NSBezierPath bezierPathWithRect: NSMakeRect(0, 0, 100, 100)]];
	[self setEditingShape: [NSBezierPath bezierPathWithRect: NSMakeRect(0, 0, 200, 200)]];
	[self setStrokeColor: [NSColor darkGrayColor]];
	[self setFillColor: [NSColor lightGrayColor]];
	[self setAlphaValue: 0.5];
	
    return self;
}

- (void) dealloc
{
    DESTROY(_drawingShape);
    DESTROY(_editingShape);
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

@end
#endif
