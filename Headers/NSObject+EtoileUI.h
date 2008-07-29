/*
	NSObject+EtoileUI.h
	
	NSObject EtoileUI specific additions.
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  September 2007
 
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
#import <EtoileUI/ETInspecting.h>

/** EtoileUI binds to all objects a visual representation. In many cases, such
	representations are created only on demand.
	Any UI objects like (ETView, ETLayoutItem etc.) responds to -view: by 
	becoming frontmost UI objects and focused. Take note, this may involve 
	changing both the frontmost application and window).
	Non-UI objects are returned by looking up for a service or a component 
	which is registered in CoreObject as a viewer or editor for this object 
	type. If none can be found, the lookup continues by trying to find a 
	viewer/editor through CoreObject supercasting mechanism. If the fallback
	occurs on a raw data viewer/editor, -view: method doesn't handle by itself
	the viewing but delegates it to -inspect: which displays a basic object
	inspector built around ETModelViewLayout. 
	When a new UI object is created or when -view: is called on an object, in
	both cases the object represented by the UI object is registered as opened
	in the layout item registry. Any subsequent invocations of -view won't create
	a new visual representation but move the registered representation back to
	front. The layout item registry is a shared instance which can be accessed 
	by calling -[ETObjectRegistry(EtoileUI) layoutItemRegistry].
	*/


@interface NSObject (EtoileUI)

/* Basic Properties (extends Model category in EtoileFoundation) */

- (NSImage *) icon;

/* Lively feeling */

- (IBAction) browse: (id)sender;
- (IBAction) view: (id)sender;
- (IBAction) inspect: (id)sender;

@end

@interface NSObject (ETInspector) <ETObjectInspection>
- (id <ETInspector>) inspector;
@end

/** We override actions declared on NSObject to maintain the responder chain.
    The forwarding must now be added in NSResponder since every objects 
	including responders like NSTableView pretends to respond to -inspect: and
	-view: (but without doing anything). */
@interface NSResponder (EtoileUI)
- (IBAction) browse: (id)sender;
- (IBAction) view: (id)sender;
- (IBAction) inspect: (id)sender;
@end

/** See NSObject+Model in EtoileFoudation */
@interface NSImage (EtoileModel)
- (BOOL) isCommonObjectValue;
@end
