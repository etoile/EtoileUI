/*
	ETRenderer.h
	
	Description forthcoming.
 
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

// WARNING: Very unstable API. Please don't use.

/** Factory renderer constants that can be used to retrieve a renderer */
kETSelectionStyle
kETBlurFilter
kETBrushTool
etc.

@interface ETRenderer : NSObject
{
	ETRenderer *_nextRenderer;
}

/** Returns renderer shared instance identified by name parameter. 
	In fact returns a proxy renderer referencing the real renderer. But the 
	proxy behaves exactly like the real instance. Proxy class is 
	ETProxyRenderer subclass of ETRenderer. */
+ (ETRenderer *) rendererForName:

-registerRendererForName:
-unregisterRendererForName:

/* Accessors */

-setName:
-name

/** Before calling any rendering methods, you need to lock the focus on some
	output view or image. */
- (void) render: (NSDictionary *)inputValues;
// Method below should be kept or not?
- (void) renderLayoutItem: (ETLayoutItem *)item;

- (void) setNextRenderer: (ETRenderer *)renderer;

@end

/* You need to have a value for key ETGraphicPath */
@interface ETStyleRenderer : ETRenderer
{
	NSColor *_outlineColor;
	NSColor *_interiorColor;
	float _alpha;
	// NSMutableDictionary *_styleValues;
}

- (void) setAlphaValue: (float);
- (float) alphaValue;

- (void) setInteriorColor: (NSColor *)color;
- (NSColor *) interiorColor;
- (void) setOutlineColor: (NSColor *)color;
- (NSColor *) outlineColor;

- (void) drawShape: (ETShape *)shape;

- (void) drawInRect: (NSRect);

//- renderLayoutItem: inLayoutItem: (ETLayoutItemGroup *)
//- renderLayoutItem: inDisplayObject: (id)
//- renderLayoutItem: inView: (NSView *)
//- renderLayoutItem: inRect: (NSRect)

@end

/** ETShape instances are model objects. As such they are never manipulated 
	directly by layout or container, bu these objects interacts with them
	indirectly through layout items. A shape is made of a path and optional
	style and transform. Unlike NSBezierPath instances, they support boolean 
	operations (will probably implemented in a another framework with a 
	category). */
@interface ETShape : ETRenderer
{
	id _path; // We may later support other paths like spline
	ETStyleRenderer *_style;
	NSAffineTransform *_transform;
}

- (id) initWithPath: (NSBezierPath *)path;
- (id) initWithPath: (NSBezierPath *)path style: (ETStyleRenderer *)style;

/** Returns whether the shape acts as a mask over previous drawing. All drawing
	done by all previous renderers will be clipped by the path of the receiver. 
	Following this renderer, only the area matching the non-filled part the 
	shape will remain and be put through next renderers. */
- (BOOL) isMask;
- (void) setMask: (BOOL)flag;

/*- (void) setRotation: (float)rotation;
- (float) rotation;*/

@end
