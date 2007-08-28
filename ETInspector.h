/*
	ETInspector.h
	
	Inspector protocol and related Inspector representation class which can be
	used as an inspector view wrapper.
 
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
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETViewLayout.h>

#define ETLayout ETViewLayout

@class ETView, ETContainer;

@protocol ETInspector
- (ETView *) view;
- (NSWindow *) window;
- (NSPanel *) panel;
/*- (NSArray *) inspectedItems;
- (void) setInspectedItems: (NSArray *)items;*/
@end

@protocol ETObjectInspection
- (id <ETInspector>) inspector;
@end


@interface ETInspector : ETLayoutItem <ETInspector>
{
	IBOutlet ETContainer *itemGroupView;
	IBOutlet ETContainer *propertyView;
	IBOutlet NSWindow *window;
	IBOutlet id viewModelLayout;

	NSArray *_inspectorViews;
	NSArray *_inspectedItems;
}

- (NSArray *) inspectedItems;
- (void) setInspectedItems: (NSArray *)items;

- (ETView *) view;
- (void) setView: (NSView *)view;

- (NSWindow *) window;
- (NSPanel *) panel;

- (IBAction) inspect: (id)sender;

@end

@interface ETLayoutItem (ETInspector)
+ (ETLayoutItem *) layoutItemWithInspectedObject: (id)object;
/** A basic meta model which inspects layout items by wrapping each one in a 
	new meta layout item. Achieved by setting the base layout item as the
	represented object of the new meta layout item. */
+ (ETLayoutItem *) layoutItemOfLayoutItem: (ETLayoutItem *)item;
- (ETView *) buildInspectorView;
@end

@interface NSObject (ETInspector) <ETObjectInspection>
- (id <ETInspector>) inspector;
@end

/*@interface ETInspectorLayout
{
	IBOutlet ETContainer *itemGroupView;
}

@end*/

typedef enum _ETLayoutDisplayMode {
	ETLayoutDisplayModeView,
	ETLayoutDisplayModeModel,
} ETLayoutDisplayMode;

@interface ETViewModelLayout : ETLayout
{
	IBOutlet id enclosingView;
	IBOutlet ETContainer *propertyView;
	ETLayoutDisplayMode _displayMode;
}

- (ETLayoutDisplayMode) displayMode;
- (void) setDisplayMode: (ETLayoutDisplayMode)mode;
- (void) switchDisplayMode: (id)sender;

@end
