/*
	ETViewLayout.h
	
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

@class ETContainer, ETViewLayoutLine, ETLayoutItem;

/** Methods which must be implemented by an object to be layouted by any
	ETLayout subclasses. The object whose layout items are layouted is the
	layout context (plays a role analog to the graphic context) 
	- layout context is where the layouting occurs
	- graphic context is where the drawing occurs */
@protocol ETLayoutingContext

@end

// NOTE: May be this should be turned into a mask
typedef enum _ETSizeConstraintStyle 
{
	ETSizeConstraintStyleNone,
	ETSizeConstraintStyleVertical,
	ETSizeConstraintStyleHorizontal,
	ETSizeConstraintStyleVerticalHorizontal
} ETSizeConstraintStyle;

/** When you compute your layout in methods -layoutLineForLayoutItems:, 
	-layoutModelForLayoutItems: and -computeLayoutItemLocationsForLayoutModel:
	be careful not to reverse the item order, else selection and sorting will 
	be messed. */

@interface ETViewLayout : NSObject
{
	IBOutlet ETContainer *_container;
	IBOutlet id _layoutContext;
	IBOutlet id _delegate;
	IBOutlet NSView *_displayViewPrototype;
	
	BOOL _isLayouting; /* -isRendering */
	
	/* Layout and Content Size in Scrollview */
	NSSize _layoutSize;
	BOOL _layoutSizeCustomized;
	BOOL _maxSizeLayout;
	
	/* Items Sizing */
	NSSize _itemSize;
	ETSizeConstraintStyle _itemSizeConstraintStyle;
}

/* Factory  Method */

- (id) layoutPrototype;

/* Main Accessors */

- (void) setContainer: (ETContainer *)newContainer;
- (ETContainer *) container;

- (void) setLayoutContext: (id <ETLayoutingContext>)context;
- (id <ETLayoutingContext>) layoutContext;

/* -isSemantic is initially defined by superclass ETStyle */
- (BOOL) isSemantic;
- (BOOL) isComputedLayout;

/* Size And Utility Accessors */

- (void) setUsesCustomLayoutSize: (BOOL)flag;
- (BOOL) usesCustomLayoutSize;
- (void) setLayoutSize: (NSSize)size;
- (NSSize) layoutSize;
// Not sure the two next methods will be kept public
- (void) setContentSizeLayout: (BOOL)flag;
- (BOOL) isContentSizeLayout;

- (void) setDelegate: (id)delegate;
- (id) delegate;

/* Item Sizing Accessors */

- (void) setItemSizeConstraintStyle: (ETSizeConstraintStyle)constraint;
- (ETSizeConstraintStyle) itemSizeConstraintStyle;
- (void) setConstrainedItemSize: (NSSize)size;
- (NSSize) constrainedItemSize;

/* Sizing Methods */

- (BOOL) isAllContentVisible;
- (void) adjustLayoutSizeToContentSize;

/* Layouting */

- (BOOL) isRendering;

- (void) render;
- (void) renderWithLayoutItems: (NSArray *)items;

- (ETViewLayoutLine *) layoutLineForLayoutItems: (NSArray *)items;
- (NSArray *) layoutModelForLayoutItems: (NSArray *)items;
- (void) computeLayoutItemLocationsForLayoutModel: (NSArray *)layoutModel;

- (void) resizeLayoutItems: (NSArray *)items toScaleFactor: (float)factor;

/* Utility Methods */

- (ETLayoutItem *) itemAtLocation: (NSPoint)location;
- (NSRect) displayRectOfItem: (ETLayoutItem *)item;

/* Wrapping Existing View */

- (void) setDisplayViewPrototype: (NSView *)protoView;
- (NSView *) displayViewPrototype;

@end


@interface ETViewLayout (Delegate)

/** If you want to render layout items in different ways depending on the layout
	settings, you can implement this delegate method. When implemented in a
	delegate object, -[ETLayoutItem render] isn't called automatically anymore
	and you are in charge of calling it in this delegate method if you want to. */
- (void) layout: (ETViewLayout *) renderLayoutItem: (ETLayoutItem *)item;

@end
