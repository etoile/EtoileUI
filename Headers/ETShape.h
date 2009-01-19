/*
	ETShape.h
	
	An ETStyle subclass used to represent arbitrary shapes. These shapes can be
	primitives such as rectangles, oval etc. or more complex shapes that embed 
	or combine text, image, shadow, mask etc.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  July 2007
 
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
#import <EtoileUI/ETStyle.h>

// WARNING: Unstable API

/** ETShape instances are model objects. As such they are never manipulated 
	directly by a layout, but ETLayout subclasses interact with them
	indirectly through layout items. A shape is made of a path and optional
	style and transform. Unlike NSBezierPath instances, they support boolean 
	operations (will probably implemented in a another framework with a 
	category). */
@interface ETShape : ETStyle
{
	NSBezierPath *_path;
	NSColor *_fillColor;
	NSColor *_strokeColor;
	float _alpha;
	BOOL _hidden;
	SEL _resizeSelector;
}

+ (NSRect) defaultShapeRect;
+ (void) setDefaultShapeRect: (NSRect)aRect;

+ (ETShape *) shapeWithBezierPath: (NSBezierPath *)aPath;
+ (ETShape *) rectangleShapeWithRect: (NSRect)aRect;
+ (ETShape *) ovalShapeWithRect: (NSRect)aRect;

- (id) initWithBezierPath: (NSBezierPath *)aPath;

- (NSBezierPath *) path;
- (void) setPath: (NSBezierPath *)aPath;
- (NSRect) bounds;
- (void) setBounds: (NSRect)aRect;
- (SEL) pathResizeSelector;
- (void) setPathResizeSelector: (SEL)aSelector;

- (NSColor *) fillColor;
- (void) setFillColor: (NSColor *)color;
- (NSColor *) strokeColor;
- (void) setStrokeColor: (NSColor *)color;

- (float) alphaValue;
- (void) setAlphaValue: (float)newAlpha;

- (BOOL) hidden;
- (void) setHidden: (BOOL)flag;

/** Returns whether the shape acts as a mask over previous drawing. All drawing
	done by all previous renderers will be clipped by the path of the receiver. 
	Following this renderer, only the area matching the non-filled part the 
	shape will remain and be put through next renderers. */
/*- (BOOL) isMask;
- (void) setMask: (BOOL)flag;*/

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
- (void) drawInRect: (NSRect)rect;
- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect;

@end
