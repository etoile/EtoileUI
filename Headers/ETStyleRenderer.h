/*
	ETStyleRenderer.h
	
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
#import <EtoileUI/ETStyle.h>

@class ETLayoutItem;

// WARNING: Very unstable API. Please don't use.

/** Render represents a chain of drawing operations which operates in a drawing context
	with a focused view or image. This method is equivalent to -drawRect: method. */
//- (void) render: (NSMutableDictionary *)inputValues;
/** Apply represents a chain of transformations which produces or returns a result that 
	may eventually be renderered by a rendering chain with -render: method. */
//- (void) apply: (NSMutableDictionary *)inputValues;

@interface ETSelection : NSObject
{
	NSBezierPath *_drawingShape;
	NSBezierPath *_editingShape;
	NSColor *_outlineColor;
	NSColor *_interiorColor;
	float _alpha;
	BOOL _hidden;
}

- (void) setAlphaValue: (float)alpha;
- (float) alphaValue;

- (BOOL) hidden;
- (void) setHidden: (BOOL)flag;

- (void) setInteriorColor: (NSColor *)color;
- (NSColor *) interiorColor;
- (void) setOutlineColor: (NSColor *)color;
- (NSColor *) outlineColor;

- (void) setDrawingShape: (NSBezierPath *)shape;
- (NSBezierPath *) drawingShape;
- (void) setEditingShape: (NSBezierPath *)shape;
- (NSBezierPath *) editingShape;

/*- (void) setAlwaysDrawsEditingShape: (BOOL)flag;
- (void) setUsesItemGranularityForDrawing: (BOOL)flag;*/

- (void) renderLayoutItem: (ETLayoutItem *)item;
- (void) drawInRect: (NSRect)rect;

@end
