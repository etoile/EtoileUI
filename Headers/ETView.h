/*
	ETView.h
	
	NSView replacement class with extra facilities like delegated drawing.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2007
 
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
#import <EtoileFoundation/ETPropertyValueCoding.h>

@class ETLayoutItem;

#ifdef GNUSTEP
// NOTE: This hack is needed because GNUstep doesn't retrieve -isFlipped in a 
// consistent way. For example in -[NSView _rebuildCoordinates] doesn't call 
// -isFlipped and instead retrieve it directly from the rFlags structure.
#define USE_NSVIEW_RFLAGS
#endif

/** Display Tree Description

 */

/** ETView is the generic view class extensively used by EtoileUI. It 
	implements several facilities in addition to the ones already provided by
	NSView. If you want to write Etoile-native UI code, you should always use
	or subclass ETView and not NSView when you need a custom view and you don't
	rely an AppKit-specific NSView subclasses.
	Take note that if you want to add subviews (or child items) you should use
	ETContainer and not ETView which throws exceptions if you try to call 
	-addSubview: directly.
	
	A key feature is additional control and flexibility over the 
	drawing process. It lets you sets a render delegate by calling 
	-setRenderer:. This delegate can implement -render:  method to avoid the 
	tedious subclassing involved by -drawRect:. 
	More importantly, -render: isn't truly a delegated version of -drawRect:. 
	This new method enables the possibility to draw directly over the subviews 
	by offering another drawing path. This drawing option is widely used in 
	EtoileUI and is the entry point of every renderer chains when they are 
	asked to render themselves on screen. See Display Tree Description if you
	want to know more. 
	
	An ETView instance is also always bound to a layout item unlike NSView 
	instances. When a view is set on a layout item, when this view isn't an
	ETView class or subclass instance, ETLayoutItem automatically wraps the
	view in an ETView making possible to apply renderers, styles etc. over the
	real view.
	
	ETView also offers a customizable title bar. The title bar visibility can
	always be turned on or off. By default, it's turned off. If you are in 
	Live Development mode, most view title bars are usually visible and are 
	tuned for live UI editing with various buttons to switch between available
	edition modes like view, model, object, component etc. By clicking and 
	dragging a title bar in Live Development you can edit your UI layout. 
	Outside of Live Development mode, title bars support collapse and expand
	operations (think of it as window shading at view level) which is useful
	to build complex inspectors or very flexible UI based on disclosable views.
	Title bar support also means an ETContainer embedding ETView instances and 
	using a layout of type ETFreeLayout will give you a built-in window manager.
	Title bar views can be customized at application-level by setting a title
	bar view prototype to be reused by all instances. Instance-by-instance 
	customization is also possible by calling -setTitleBarView:, in this case
	calling +setTitleBarViewPrototype: will never be reflected at instance 
	level until you call -setTitleBarView: nil which resets the title bar to 
	the class-shared prototype.
*/

// TODO: Implement ETTitleBarView subclass to handle the title bar as a layout
// item which can be introspected and edited at runtime. A subclass is 
// necessary to create the title bar of title bars in a lazy way, otherwise
// ETView instantiation would lead to infinite recursion on the title bar set up.

@interface ETView : NSView <ETPropertyValueCoding>
{
	ETLayoutItem *_layoutItem;
	id _renderer;
	// NOTE: May be remove the view ivars to make the class more lightweight
	NSView *_titleBarView;
	NSView *_wrappedView;
	NSView *_temporaryView;
#ifndef USE_NSVIEW_RFLAGS
	BOOL _flipped;
#endif
	BOOL _disclosable;
	BOOL _usesCustomTitleBar;
}

/* Title Bar */

+ (void) setTitleBarViewPrototype: (NSView *)barView;
+ (NSView *) titleBarViewPrototype;

- (id) initWithFrame: (NSRect)rect layoutItem: (ETLayoutItem *)item;

/* Basic Accessors */

- (id) layoutItem;
- (void) setLayoutItem: (ETLayoutItem *)item;
- (void) setLayoutItemWithoutInsertingView: (ETLayoutItem *)item;
- (void) setRenderer: (id)renderer;
- (id) renderer;
- (BOOL) isFlipped;
- (void) setFlipped: (BOOL)flag;

/* Embbeded Views */

- (void) setWrappedView: (NSView *)subview;
- (NSView *) wrappedView;
- (void) setTemporaryView: (NSView *)subview;
- (NSView *) temporaryView;
- (NSView *) contentView;

- (void) setDisclosable: (BOOL)flag;
- (BOOL) isDisclosable;
- (BOOL) isExpanded;

- (BOOL) isTitleBarVisible;
- (BOOL) usesCustomTitleBar;
- (void) setTitleBarView: (NSView *)barView;
- (NSView *) titleBarView;

/* Actions */

- (void) collapse: (id)sender;
- (void) expand: (id)sender;

/* Property Value Coding */

- (id) valueForProperty: (NSString *)key;
- (BOOL) setValue: (id)value forProperty: (NSString *)key;
- (NSArray *) properties;

/* Live Development */

//- (BOOL) isEditingUI;

/* Subclassing */

- (NSView *) mainView;
- (void) tile;

@end

/* Notifications */

extern NSString *ETViewTitleBarViewPrototypeDidChangeNotification;

/* Private stuff */

@interface ETScrollView : ETView
{
	NSScrollView *_mainView;
}

- (id) initWithMainView: (id)scrollView layoutItem: (ETLayoutItem *)item;

@end
