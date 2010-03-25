/** <title>NSObject+EtoileUI</title>

	<abstract>NSObject EtoileUI specific additions.</abstract>

	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  September 2007
	License: Modified BSD (see COPYING)
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

- (NSComparisonResult) compare: (id)anObject;

/* Basic Properties (extends Model category in EtoileFoundation) */

- (NSImage *) icon;

/* Lively feeling */

- (IBAction) browse: (id)sender;
- (IBAction) view: (id)sender;
- (IBAction) inspect: (id)sender;
- (IBAction) explore: (id)sender;

/* Introspection Utility

   TODO: Move some of this stuff in EtoileFoundation once we have a clean 
   reflection layer. */

+ (NSString *) displayName;
+ (NSString *) baseClassName;
+ (NSString *) aspectName;

/* Event Dispatch */

- (BOOL) isFirstResponderProxy;

- (BOOL) isLayoutItem;
- (BOOL) isTool;
- (BOOL) isView;

@end

@interface NSObject (ETInspector) <ETObjectInspection>
- (id <ETInspector>) inspector;
@end

/** See NSObject+Model in EtoileFoudation */
@interface NSImage (EtoileModel)
- (BOOL) isCommonObjectValue;
@end
