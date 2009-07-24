/*
	ETCompositeLayout.h
	
	A layout subclass that formalizes and simplifies the composition of 
	layouts.
 
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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayout.h>

@class ETLayoutItemGroup;

/** The composition of layouts is a mechanism that allows to compose a layout 
    item tree playing only a presentation role, into a another layout item tree 
    that is characterized by a semantic role.
    The composition of layouts allows to compose layout item trees without 
    altering the structure of a target tree and as such to profoundly alter 
    its presentation without touching the semantic that is encoded by the 
    structure.
    When a composite layout is set on an item group, its children are routed 
    to the layout of a node of the item tree encapsulated in the layout. 
    Routed means the children item aren't attached to the internal item tree but 
    just passed to a target layout for which a target item exists in the 
    internal item tree.
    You can create a composite layout by subclassing and overriding methods like 
    -targetItem, -rootItem or you can create one dynamically by passing a 
    presentational layout item tree to be composed to -initWithRootItem:. 
    ETCompositeLayout encapsulates a presentational tree that doesn't appear 
    in the layout item group to which the layout is applied to. 
    Another way to look at composite layouts is to see them as inner decorator 
    items unlike decorator items you can set on ETLayoutItem instances which are 
    outer decorators. */
@interface ETCompositeLayout : ETLayout
{
	ETLayoutItemGroup *_targetItem; /* a descendent of the root virtual node */
}

+ (id) defaultPresentationProxyWithFrame: (NSRect)aRect;

/* Initialization */

- (id) initWithRootItem: (ETLayoutItemGroup *)itemGroup;
- (id) initWithRootItem: (ETLayoutItemGroup *)rootItem 
  firstPresentationItem: (ETLayoutItemGroup *)targetItem;
  
- (void) setRootItem: (ETLayoutItemGroup *)anItem;

- (id) presentationProxyWithItem: (ETLayoutItemGroup *)item;
- (void) renderWithLayoutItems: (NSArray *)items isNewContent: (BOOL)isNewContent;

- (id) firstPresentationItem;
- (void) setFirstPresentationItem: (ETLayoutItemGroup *)targetItem;
- (BOOL) isContentRouted;

/* Subclassing */

- (void) saveInitialContextState: (NSSet *)properties;
- (void) prepareNewContextState;
- (void) restoreInitialContextState: (NSSet *)properties;
- (void) restoreContextState;

@end
