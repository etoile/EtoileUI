/*
	ETStyle.h
	
	Generic object chain class to implement late-binding of behavior
	through delegation.
 
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

#import <Foundation/Foundation.h>
#import <EtoileFoundation/ETObjectChain.h>
#import <EtoileFoundation/ETRendering.h>

@class ETLayoutItem;

/** Style class is widely used in EtoileUI to implement pervasive late-binding 
	of state in combination with ETObjectRegistry.
	Many classes in EtoileUI are subclasses of ETStyle and thereby benefit from 
	the built-in support of delegation chain. The delegation chain is used as a
	basic rendering chain that can be refined through subclassing to implement 
	more complex rendering operations.
	By the means of delegation and changing state of objects at runtime,
	the class also provides a common interface to create new styles by 
	combining other styles together. The order in which styles are chained 
	results in a compositing order: each style is rendered over the previously
	rendered style. Hence ETStyle is a typical renderer object.
	Take note ETFilter provides a mostly identical class in EtoileFoundation. 
	ETStyle is state oriented, it is used to represent objects that have a 
	visual translation or representation (like style, layout, brush stroke 
	etc.) and display them on screen. 
	ETFilter is behavior-oriented, it is used to handle filtering, 
	transforming and converting where you give data in input and you get 
	other data in output. 
	
	input | type  |  output
	data -> style -> display
	data -> filter -> data  
	
	Both ETFilter and ETStyle have a common object chain interface (through
	ETObjectChain superclass) and implements ETRendering protocol. The benefit
	is a polymorphic API and the possibility to combine styles and filters in 
	hybrid processing chains.
 */

@interface ETStyle : ETObjectChain <ETRendering>
{
	id _nextStyle;
}

/* Initialization */

- (id) initWithStyle: (ETStyle *)style;
- (id) initWithCollection: (id <ETCollection>)styles;

/* Style Chaining */

- (ETStyle *) nextStyle;
- (void) setNextStyle: (ETStyle *)style;
- (ETStyle *) lastStyle;

/* Style Rendering */

- (SEL) styleSelector;
- (void) render: (NSMutableDictionary *)inputValues;
- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
	  
- (void) didChangeItemBounds: (NSRect)bounds;

@end


@interface ETBasicItemStyle : ETStyle
{
	BOOL _titleVisible;
}

+ (id) sharedInstance;

- (void) render: (NSMutableDictionary *)inputValues 
     layoutItem: (ETLayoutItem *)item 
	  dirtyRect: (NSRect)dirtyRect;
	  
- (void) drawImage: (NSImage *)itemImage flipped: (BOOL)itemFlipped inRect: (NSRect)aRect;
- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect;
- (void) drawStackIndicatorInRect: (NSRect)indicatorRect;

// TODO: Implement
//- (BOOL) setTitleVisible: (BOOL)flag;
//- (BOOL) isTitleVisible;
//- (void) drawTitleInRect: (NSRect)aRect;

@end
