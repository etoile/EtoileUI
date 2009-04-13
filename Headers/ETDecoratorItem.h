/*
	ETDecoratorItem.h
	
	ETUIItem subclass which makes possibe to decorate any layout items, 
	usually with a widget view.

	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  March 2009
 
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

@class ETDecoratorItem, ETView;

/** An abstract class/mixin that provides some basic behavior common to both 
ETLayoutItem and ETDecoratorItem.

TODO: Turn this class into a mixin and a protocol. */
@interface ETUIItem : ETStyle
{
	ETDecoratorItem *_decoratorItem; // next decorator
	ETView *_view;
}

+ (NSRect) defaultItemRect;

- (BOOL) isFlipped;
- (id) supervisorView;
- (void) setSupervisorView: (ETView *)aView;
- (ETView *) displayView;
- (void) beginEditingUI;
/*- (BOOL) isEditingUI;
- (void) commitEditingUI;*/

- (void) render: (NSMutableDictionary *)inputValues dirtyRect: (NSRect)dirtyRect inView: (NSView *)view ;

/* Decoration */

- (ETDecoratorItem *) decoratorItem;
- (void) setDecoratorItem: (ETDecoratorItem *)decorator;
- (id) lastDecoratorItem;
- (ETUIItem *) decoratedItem;
- (id) firstDecoratedItem;
- (BOOL) acceptsDecoratorItem: (ETDecoratorItem *)item;
- (NSRect) decorationRect;

/* Framework Private */

- (void) didChangeDecoratorOfItem: (ETUIItem *)item;
- (BOOL) shouldSyncSupervisorViewGeometry;
- (NSRect) convertDisplayRect: (NSRect)rect 
        toAncestorDisplayView: (NSView **)aView 
                     rootView: (NSView *)topView
                   parentItem: (ETLayoutItem *)parent;

@end


/** Decorator class which can be subclassed to turn wrapper-like widgets such 
as scrollers, windows, group boxes etc., provided by the widget backend 
(e.g. AppKit), into decorator items to be applied to the semantic items that 
make up the layout item tree.

ETDecoratorItem can be seen as an ETLayoutItem variant with limited abilities 
and whose instances don't have a semantic role, hence they remain invisible 
in the layout item tree. They allow EtoileUI to maintain a very tight mapping 
between the model graph and the layout item tree. By limiting the number of 
non-semantic nodes in the tree, the feeling of working with real and cohesive 
objects is greatly enhanced at both code and UI level.

A decorator item must currently not break the following rules (this is subject 
to change though):
<list>
<item>[self displayView] must return [[self decoratorItem] supervisorView]</item>
<item>[self supervisorView] must return [[[self decoratorItem] supervisorView] wrappedView]</item>
</list>
However -supervisorView can be overriden to return nil. */
@interface ETDecoratorItem : ETUIItem
{
	ETUIItem *_decoratedItem; // previous decorator (weak reference)
}

+ (id) item;

- (id) initWithSupervisorView: (ETView *)supervisorView;

- (BOOL) usesWidgetView;

/* Decoration Geometry */

- (void) setDecorationRect: (NSRect)rect;

- (NSRect) visibleContentRect;
- (NSRect) contentRect;

- (NSRect) convertDecoratorRectFromContent: (NSRect)rectInContent;
- (NSRect) convertDecoratorRectToContent: (NSRect)rectInDecorator;

- (BOOL) isFlipped;
- (void) setFlipped: (BOOL)flipped;

/* Subclass Hooks */

- (BOOL) canDecorateItem: (ETUIItem *)item;
- (void) handleDecorateItem: (ETUIItem *)item 
             supervisorView: (ETView *)decoratedView 
                     inView: (ETView *)parentView;
- (void) handleUndecorateItem: (ETUIItem *)item inView: (ETView *)parentView;
- (void) handleSetDecorationRect: (NSRect)rect;
- (NSSize) decoratedItemRectChanged: (NSRect)rect;

/* Private Use */

- (void) setDecoratedItem: (ETUIItem *)item;

@end
