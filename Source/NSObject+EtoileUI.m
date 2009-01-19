/*  <title>NSObject+EtoileUI</title>

	NSObject+EtoileUI.m
	
	<abstract>NSObject EtoileUI specific additions.</abstract>
 
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

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/NSObject+Model.h>
#import "NSObject+EtoileUI.h"
#import "ETObjectBrowserLayout.h"
#import "ETLayoutItemGroup.h"
#import "ETLayoutItem+Factory.h"
#import "ETInspector.h"
#import "ETViewModelLayout.h"
#import "ETCompatibility.h"


@implementation NSObject (EtoileUI)

/* Basic Properties */

/** Returns the icon used to represent unknown object.
	Subclasses can override this method to return an icon that suits and 
	describes better their own objects. */
- (NSImage *) icon
{
	// FIXME: Asks Jesse to create an icon representing an unknown object
	return nil;
}

/* Lively feeling */

/** Shows the receiver content in the object browser panel and allows to 
	navigate the whole Étoilé environment object graph (including outside the
	application the browsed object is part of). */
- (IBAction) browse: (id)sender
{
	ETObjectBrowser *browser = [[ETObjectBrowser alloc] init]; // FIXME: Leak

	ETDebugLog(@"browse %@", self);
	[browser setBrowsedObject: self];
	[[browser panel] makeKeyAndOrderFront: self];
}

/** Shows the layout item representing the receiver by enforcing referential
	stability (more commonly named spatiality in the case of UI objects).
	If the receiver is a layout item, this layout item is simply brought to 
	front and made the first responder. 
	When the receiver is some other kind of objects, the object registry is 
	looked up to know whether there is a layout item bound to the receiver.
	If the lookup succeeds, the matching layout item is requested to display
	itself by sending -view: to it.
	If no visual representation exists, a new layout item is created and 
	bound to the receiver with the object registry. Then this layout item is
	made visible and active as described in the previous paragraph. */
- (IBAction) view: (id)sender
{
	// TODO: Implement. Request the type (UTI) of the receiver, the looks up
	// in the aspect repository which item template should be used to create a
	// UI represention of the receiver. Simply copy the template and set the 
	// receiver as the represented object, then attach the copied item to the 
	// window group.
}

/** Shows an inspector which provides informations about the receiver. The 
	inspector makes possible to edit the object state and behavior. For some
	objects, the built-in inspector could have been overriden by a third-party 
	inspector. By inspecting a third-party inspector, you can easily revert it
	or bring back the basic inspector. */
- (IBAction) inspect: (id)sender
{
	id <ETInspector> inspector = nil;

	if ([self conformsToProtocol: @protocol(ETObjectInspection)])
		inspector = [self inspector];

	if (inspector == nil)
		inspector = [[ETInspector alloc] init]; // FIXME: Leak

	ETDebugLog(@"inspect %@", self);
	[inspector setInspectedObjects: A(self)];
	[[inspector panel] makeKeyAndOrderFront: self];
}

/** Shows a developer-centric inspector based on ETViewModelLayout which 
provides informations about the receiver object. This explorer inspector allows 
to inspect properties, instances variables, methods and also the content when 
the receiver is a collection (ETCollection protocol must be implemented).

The inspector makes possible to edit the object state and behavior. 

Unlike the inspector shown by -inspect:, this built-in inspector is not expected 
to overriden by a third-party inspector. */
- (IBAction) explore: (id)sender
{
	// TODO: Should be -itemGroupWithRepresentedObject: once ETLayoutItemGroup 
	// is able to create a container as supervisor view by itself if needed.
	ETLayoutItemGroup *item = [ETLayoutItem itemGroupWithContainer];
	ETViewModelLayout *layout = [ETViewModelLayout layout];

	[item setRepresentedObject: self];
	if ([self isLayoutItem])
	{
		[layout setShouldInspectRepresentedObjectAsView: YES];
		[layout setDisplayMode: ETLayoutDisplayModeViewObject];
	}
	else
	{
		[layout setDisplayMode: ETLayoutDisplayModeModelObject];
	}
	[item setLayout: layout];
	[item setName: [NSString stringWithFormat: _(@"Explorer %@"), [self primitiveDescription]]];
	[item setSize: NSMakeSize(350, 500)];
	[[ETLayoutItem windowGroup] addItem: item];
}

@end

@implementation NSResponder (EtoileUI)

- (IBAction) browse: (id)sender
{
	[super browse: sender];
	//[[self nextResponder] browse: sender];
}

- (IBAction) view: (id)sender
{
	[[self nextResponder] view: sender];
}

- (IBAction) inspect: (id)sender
{
	[[self nextResponder] inspect: sender];
}

@end

@implementation NSImage (EtoileModel)
- (BOOL) isCommonObjectValue { return YES; }
@end
