/*
	ETLayoutItem+Factory.m
	
	ETLayoutItem category providing a factory for building various kinds of 
	layout items and keeping track of special nodes of the layout item tree.
 
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
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItem.h>

@class ETLayoutItemGroup, ETLayer;


@interface ETLayoutItem (ETLayoutItemFactory)

/* Basic Item Factory Methods */

+ (ETLayoutItem *) item;
+ (ETLayoutItem *) itemWithView: (NSView *)view;
+ (ETLayoutItem *) itemWithValue: (id)value;
+ (ETLayoutItem *) itemWithRepresentedObject: (id)object;

/* Group Factory Methods */

+ (ETLayoutItemGroup *) itemGroup;
+ (ETLayoutItemGroup *) itemGroupWithItem: (ETLayoutItem *)item;
+ (ETLayoutItemGroup *) itemGroupWithItems: (NSArray *)items;
+ (ETLayoutItemGroup *) itemGroupWithView: (NSView *)view;
+ (ETLayoutItemGroup *) itemGroupWithValue: (id)value;
+ (ETLayoutItemGroup *) itemGroupWithRepresentedObject: (id)object;
+ (ETLayoutItemGroup *) itemGroupWithContainer;

+ (ETLayoutItemGroup *) graphicsGroup;

/* Leaf Widget Factory Methods */

+ (id) button;
+ (id) buttonWithTitle: (NSString *)aTitle target: (id)aTarget action: (SEL)aSelector;
+ (id) radioButton;
+ (id) checkbox;
+ (id) labelWithTitle: (NSString *)aTitle;
+ (id) textField;
+ (id) searchField;
+ (id) textView;
+ (id) progressIndicator;
+ (id) horizontalSlider;
+ (id) verticalSlider;
+ (id) stepper;
+ (id) textFieldAndStepper;

/* Decorator Item Factory Methods */

+ (ETWindowItem *) itemWithWindow: (NSWindow *)window;
+ (ETWindowItem *) fullScreenWindow;

/* Layer Factory Methods */

+ (ETLayer *) layer;
+ (ETLayer *) layerWithItem: (ETLayoutItem *)item;
+ (ETLayer *) layerWithItems: (NSArray *)items;
+ (ETLayer *) guideLayer;
+ (ETLayer *) gridLayer;

/* Special Group Access Methods */

+ (id) rootGroup;
+ (id) localRootGroup;

+ (id) floatingItemGroup;

+ (id) screen;
+ (id) screenGroup;
+ (id) project;
+ (id) projectGroup;

+ (ETLayoutItemGroup *) windowGroup;
+ (void) setWindowGroup: (ETLayoutItemGroup *)windowGroup;

+ (id) pickboardGroup;

/* Shape Factory Methods */

+ (ETLayoutItem *) itemWithBezierPath: (NSBezierPath *)aPath;

+ (ETLayoutItem *) rectangleWithRect: (NSRect)aRect;
+ (ETLayoutItem *) rectangle;
+ (ETLayoutItem *) ovalWithRect: (NSRect)aRect;
+ (ETLayoutItem *) oval;

/* Deprecated (DO NOT USE, WILL BE REMOVED LATER) */

+ (ETLayoutItem *) layoutItem;
+ (ETLayoutItem *) layoutItemWithView: (NSView *)view;
+ (ETLayoutItem *) layoutItemWithValue: (id)value;
+ (ETLayoutItem *) layoutItemWithRepresentedObject: (id)object;
+ (ETLayoutItemGroup *) layoutItemGroup;
+ (ETLayoutItemGroup *) layoutItemGroupWithLayoutItem: (ETLayoutItem *)item;
+ (ETLayoutItemGroup *) layoutItemGroupWithLayoutItems: (NSArray *)items;
+ (ETLayoutItemGroup *) layoutItemGroupWithView: (NSView *)view;
+ (ETLayer *) layerWithLayoutItem: (ETLayoutItem *)item;
+ (ETLayer *) layerWithLayoutItems: (NSArray *)items;

@end
