/*
	ETLayoutItem.h
	
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
#import <EtoileUI/ETStyleRenderer.h>

#define ETUTI NSString

@class ETView;

/** WARNING: Personal notes that are vague and may change, move or become part
	of another framework.

	Rendering tree is an extension of renderer support, this extension is 
	useful essentially in imaging applications either vector or bitmap based.

	Rendering is the step which precedes display and encompass both layout and
	real time graphics computation.
	A renderer tree would be roughly identical to GEGL model.
	Layout item tree and renderer tree form two parallel trees which are 
	bridged together and ruled by layout items. 
	At each layout item node, a renderer branch is connected.
	Both trees are visited together from top to bottom at rendering time.
	At rendering time, a visitor object which encapsulates the rendering state
	is passed through layout items:
	- it enters a layout item
	- it visits the item renderer branch and computes it if needed
	- it memorizes the first renderer directly connected to the layout item
	- it quits the layout item
	- it enters a second layout item
	- it checks whether the first renderer of the layout item has a second 
	input if we put aside renderer branch which plays the first input role; if
	no second input is present, it uses the last memorized renderer in this 
	role
	- it removes the last memorized renderer of the second input if necessary
	- it memorizes the renderer connected to the second layout
	- it quits the layout item
 */


@interface ETLayoutItem : ETStyleRenderer 
{
	id _value;
	id _modelObject;
	ETView *_view;
	ETStyleRenderer *_renderer;
	BOOL _selected;
	BOOL _visible;
	NSRect _defaultFrame;
	NSRect _frame;
	NSString *_name;
	BOOL _resizeBounds;
}

+ (ETLayoutItem *) layoutItemWithView: (NSView *)view;

- (ETLayoutItem *) initWithValue: (id)value;
- (ETLayoutItem *) initWithRepresentedObject: (id)object;
- (ETLayoutItem *) initWithView: (NSView *)view;

/** Facility methods to store a name acting like a last fallback property for 
	display. Name is also used as a path component to build 
	paths passed through tree source protocol to the container source. If no 
	name is available, the layout item is referenced in the path by its index 
	in layout item group which owns it. Name have the advantage to be more 
	stable than index in some cases, you can also store id or uuid in this
	field.
	You can retrieve a layout item bound a know path by simply passing this 
	path as a parameter to -[ETContainer layoutItemForPath:]. Layout items
	tree structure are managed by container archictecture so you never need
	to worry about releasing/retaining items. Only your wrapped model if you
	need/have one must be memory-managed by your code. 
	NOTE: the feature described below isn't yet supported by container
	architecture and could never be.
	If you use no container source, and you call -[ETContainer addItem:] with
	a layout item group referencing other items, in this case the management
	of the tree structure is up to you.*/
- (NSString *) name;
- (void) setName: (NSString *)name;

/* Display Element */

- (id) value;
- (void) setValue: (id)value;

- (NSView *) view;
- (void) setView: (NSView *)view;

- (NSView *) displayView;

//-displayObject

- (NSImage *) image;

/* If you have a shape set, it's always inserted after image renderer in the
	rendering chain. */
/*setShape
shape*/

/* Model Access */

- (id) representedObject;
- (void) setRepresentedObject: (id)modelObject;

- (id) valueForProperty: (NSString *)key;
- (BOOL) setValue: (id)value forProperty: (NSString *)key;

/* Utility Accessors */

/** When selection is enabled on -render call, the layout item checks a
	selection renderer (ETSelection class or subclasses) is part of its 
	rendering chain. When none is found, it inserts default selection
	renderer at the end of the chain.
	[ETRenderer rendererForName: kETStyleSelection
	If selection is disabled, it does nothing. If you call 
	-setEnablesSelection: with NO, it removes all selection renderers part
	of the rendering chain. */
/*- setEnablesSelection:
- isSelectionEnabled;*/
- (void) setSelected: (BOOL)selected;
- (BOOL) isSelected;
- (void) setVisible: (BOOL)visible;
- (BOOL) isVisible;

/** Used to select items which can be dragged or dropped in a dragging operation */
- (ETUTI *) type;

/* Layouting & Rendering Chain */

- (void) apply: (NSMutableDictionary *)inputValues;
- (void) render: (NSMutableDictionary *)inputValues;
- (void) render;
- (ETStyleRenderer *) renderer;
- (void) setStyleRenderer: (ETStyleRenderer *)renderer;

/* Sizing */

- (NSRect) frame;
- (void) setFrame: (NSRect)rect;
- (NSPoint) origin;
- (void) setOrigin: (NSPoint)origin;
- (NSSize) size;
- (void) setSize: (NSSize)size;
- (float) x;
- (void) setX: (float)x;
- (float) y;
- (void) setY: (float)y;
- (float) height;
- (void) setHeight: (float)height;
- (float) width;
- (void) setWidth: (float)width;

- (NSRect) defaultFrame;
- (void) setDefaultFrame: (NSRect)frame;
- (void) restoreDefaultFrame;
- (void) setAppliesResizingToBounds: (BOOL)flag;
- (BOOL) appliesResizingToBounds;

/* Actions */

- (void) doubleClick;

@end


@interface NSImage (ETLayoutItem)
- (NSImage *) initWithView: (NSView *)view;
@end

/*
@interface ETLayoutItem (NSCellCompatibility)
- (NSCell *) cell;
- (void) setCell: (NSCell *)cell;
@end
*/
