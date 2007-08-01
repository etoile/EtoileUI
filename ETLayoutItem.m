/*  <title>ETLayoutItem</title>

	ETLayoutItem.m
	
	<abstract>Description forthcoming.</abstract>
 
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

#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETStyleRenderer.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/GNUstep.h>

#define ETLog NSLog
#define ETUTIAttribute @"uti"

@interface ETLayoutItem (Private)
- (ETLayoutItem *) initWithView: (NSView *)view value: (id)value representedObject: (id)repObject;
- (void) layoutItemViewFrameDidChange: (NSNotification *)notif;
@end

/** Various approaches exists to customize layout items look rendering. 

	If you don't plan to rely on your object model, you can simply add to each 
	layout item a custom view  that already knows how to render/display itself.
	Usually you want something which allows to uses the object model properties
	and enables less crude or low-level rendering than an NSView subclass.
	
	If you want to render a layout item in a specific way, you can subclass
	ETLayoutItem and override -render method. This works pretty well if you are
	for example creating a photo collection display system. By combining 
	ETPhotoLayoutItem and ETFlowLayout plugged in a container, you can get a 
	full-featured photo view very easily. By subclassing ETFlowLayout in a new
	ETPhotoLayout class you would even gain more finer control on the layout 
	process itself if you think it's necessary.
	
	If you want to share the look of the rendering between several layout item
	kinds and desires the possibility to save it as a style or edit this render 
	process in a textual/script form, the best solution is to implement a 
	distinct ETRendererStyle sublass.
	
	Most of time, you want a quick yet quite flexible solution without any 
	subclassing, that's why the common solution is to implemente ETViewLayout
	delegate method called -layout:renderLayoutItem:. With this method you will
	be able to customize the rendering of layout items on the fly depending on
	the layout settings which may change between each rendering. */


@implementation ETLayoutItem

+ (ETLayoutItem *) layoutItemWithView: (NSView *)view
{
	return (ETLayoutItem *)AUTORELEASE([[self alloc] initWithView: view]);
}

- (ETLayoutItem *) initWithValue: (id)value
{
	return [self initWithView: nil value: value representedObject: nil];
}

- (ETLayoutItem *) initWithRepresentedObject: (id)object
{
	return [self initWithView: nil value: nil representedObject: object];
}

- (ETLayoutItem *) initWithView: (NSView *)view
{
	return [self initWithView: view value: nil representedObject: nil];
}

- (ETLayoutItem *) initWithView: (NSView *)view value: (id)value representedObject: (id)repObject
{
    self = [super init];
    
    if (self != nil)
    {
		[self setView: view];
		ASSIGN(_value, value);
		if (repObject != nil)
		{
			ASSIGN(_modelObject, repObject);
		}
		else
		{
			_modelObject = [[NSMutableDictionary alloc] init];
		}
    }
    
    return self;
}

- (void) dealloc
{
    DESTROY(_view);
	DESTROY(_value);
	DESTROY(_modelObject);
    
    [super dealloc];
}

- (id) copyWithZone: (NSZone *)zone
{
	ETLayoutItem *item = [[ETLayoutItem alloc] initWithView: nil 
	                                                  value: [self value] 
										  representedObject: [self representedObject]];
										  
	if ([[self view] respondsToSelector: @selector(copyWithZone)])
	{
		[item setView: [[self view] copy]];
	}
	[item setName: [self name]];
	[item setStyleRenderer: [self renderer]];
	[item setAppliesResizingToBounds: [self appliesResizingToBounds]];
	
	return item;
}

- (NSString *) name
{
	return _name;
}

- (void) setName: (NSString *)name
{
	ASSIGN(_name, name);
}

/** Returns a value which is used when only one value can be displayed like in
	a table view with a single column or an icon view with a rudimentary icon 
	unit cell. */
- (id) value
{
	return _value;
}

/** Sets a value to be used when only one value can be displayed like in
	a table view with a single column or an icon view with a rudimentary icon 
	unit cell.
	Most of time this method can be used as a conveniency which allows to 
	bypass -valueForProperty: and -setValue:forProperty: when the layout item
	is used by combox box, single column table view, line view made of simple
	images etc. */
- (void) setValue: (id)value
{
	ASSIGN(_value, value);
}

/** Returns model object which embeds the representation of what the layout 
	item displays. When a new layout item is created, by default it uses a
	dictionary as a rudimentary model object. */
- (id) representedObject
{
	return _modelObject;
}

/** Sets model object which embeds the representation of what the layout 
	item displays. 
	If you want to restore default model object initally set, pass a mutable 
	dictionary instance as parameter to this method.
	See -representedObject for more details. */
- (void) setRepresentedObject: (id)modelObject
{
	ASSIGN(_modelObject, modelObject);
}

- (NSView *) view
{
	return _view;
}

- (void) setView: (NSView *)view
{
	BOOL resizeBoundsActive = [self appliesResizingToBounds];
	
	_defaultFrame = NSZeroRect;
	/* Stop to observe notifications on current view and reset bounds size */
	[self setAppliesResizingToBounds: NO];
	
	ASSIGN(_view, view);
	
	if (_view != nil)
	{
		_defaultFrame = [_view frame];
		if (resizeBoundsActive)
			[self setAppliesResizingToBounds: YES];
	}
}

/** Returns a value of the model object -representedObject, usually by 
	calling -valueForProperty: else -valueForKey: with key parameter. By default 
	the model object is a simple dictionary which gets returned by both this 
	method and -representedObject method.
	When the model object is a custom one, it must implement -valueForProperty:
	and -setValue:forProperty: or conform to NSKeyValueCoding protocol. */
- (id) valueForProperty: (NSString *)key
{
	if ([_modelObject respondsToSelector: @selector(valueForProperty:)])
	{
		return [_modelObject valueForProperty: key];
	}
	else
	{
		return [_modelObject valueForKey: key];
	}
}

/** Sets a value identified by key of the model object returned by 
	-representedObject. 
	See -valueForProperty: for more details. */
- (BOOL) setValue: (id)value forProperty: (NSString *)key
{
	if ([_modelObject respondsToSelector: @selector(setValue:forProperty:)])
	{
		return [_modelObject setValue: value forProperty: key];
	}
	else
	{
		// FIXME: Catch key value coding exception here
		[_modelObject setValue: value forKey: key];
		return YES;
	}
}

- (NSView *) displayView
{
	return _view;
}

- (void) setSelected: (BOOL)selected
{
	_selected = selected;
}

- (BOOL) isSelected
{
	return _selected;
}

/** Commonly used to select items which can be dragged or dropped in a dragging operation */
- (ETUTI *) type
{
	if ([self representedObject] == nil
	 && [[self representedObject] isKindOfClass: [NSDictionary class]] == NO)
	{
		// FIXME: Replace by [ETUTI typeForClass: [self class]]
		return NSStringFromClass([self class]);
	}	
	else if ([[self representedObject] valueForProperty: ETUTIAttribute] != nil)
	{
		return [[self representedObject] valueForProperty: ETUTIAttribute];
	}
	else
	{
		// FIXME: Replace by [ETUTI typeForClass: [self class]]
		return NSStringFromClass([[self representedObject] class]);
	}
}

/** Forwards rendering along the container tree. 
    Override */
- (void) render
{
	// FIXME: Finds the first layout item ancestor with a view and asks it to
	// redraw itself at our rect location, this will flow back to us.
	[_renderer renderLayoutItem: self];

	if ([[self view] respondsToSelector: @selector(render)])
		[(id)[self view] render];
}

// Private
- (void) renderLayoutItem: (ETLayoutItem *)item inView: (NSView *)inView
{
	/* When we have a view, we wait to be asked to draw directly by our view 
	   before rendering anything. If a parent layout item asks us to draw, we
	   decline and wait the control return to the view who initiated the 
	   drawing and this view asks our view to draw itself as a subview. */
	if ([self view] != nil && [[self view] isEqual: inView])
		[_renderer renderLayoutItem: self];
}

- (ETStyleRenderer *) renderer
{
	return _renderer;
}

- (void) setStyleRenderer: (ETStyleRenderer *)renderer
{
	ASSIGN(_renderer, renderer);
}

- (NSRect) defaultFrame 
{ 
	return _defaultFrame; 
}

/** Modifies the item view frame when the item has a view. Default frame won't
	be touched by container transforms (like item scaling) unlike frame value
	returned by NSView. 
	Initiliazed with view frame passed in argument on ETLayoutItem instance
	initialization, else set to NSZeroRet. */
- (void) setDefaultFrame: (NSRect)frame
{ 
	_defaultFrame = frame;
	[self restoreDefaultFrame];
}

- (void) restoreDefaultFrame
{ 
	[[self view] setFrame: [self defaultFrame]]; 
}

/** When the layout item uses a view, pass YES to this method to have the 
	content resize when the view itself is resized (by modifying frame).
	Resizing content in a view is possible by simply updating bounds size to 
	match the view frame. 
	Presently uses in ETPaneSwitcherLayout. */
- (void) setAppliesResizingToBounds: (BOOL)flag
{
	_resizeBounds = flag;
	if (_resizeBounds && [self view] != nil)
	{
		[[NSNotificationCenter defaultCenter] addObserver: self 
		                                         selector: @selector(layoutItemViewFrameDidChange:) 
												     name: NSViewFrameDidChangeNotification
												   object: [self view]];
		/* Fake notification to update bounds size */
		[self layoutItemViewFrameDidChange: nil];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] removeObserver: self];
		/* Restore bounds size */
		[[self view] setBoundsSize: [[self view] frame].size];
		[[self view] setNeedsDisplay: YES];
	}
}

- (BOOL) appliesResizingToBounds
{
	return _resizeBounds;
}

- (void) layoutItemViewFrameDidChange: (NSNotification *)notif
{
	NSAssert1([self view] != nil, @"View of %@ cannot be nil on view notification", self);
	NSAssert1([self appliesResizingToBounds] == YES, @"Bounds resizing must be set on view notification in %@", self);
	
	ETLog(@"Receives NSViewFrameDidChangeNotification in %@", self);
	
	// FIXME: the proper way to handle such scaling is to use an 
	// NSAffineTransform and applies to item view in 
	// -resizeLayoutItems:scaleFactor: when -appliesResizingToBounds returns YES
	[[self view] setBoundsSize: [self defaultFrame].size];
	[[self view] setNeedsDisplay: YES];
}

/** Returns a default image representation of the layout item. 
	It tries to find it by looking up for 'image' property, then 'icon' 
	property. If none is found and a view is referenced by the layout item, it 
	generates an image by taking a snapshot of the view. */
- (NSImage *) image
{
	NSImage *img = [self valueForProperty: @"image"];
	
	if (img == nil)
		img = [self valueForProperty: @"icon"];
	
	// NOTE: -bitmapImageRepForCachingDisplayInRect:(NSRect)aRect on Mac OS 10.4
	if ([self view] != nil)
		img = (NSImage *)AUTORELEASE([[NSImage alloc] initWithView: [self view]]);
	
	if (img == nil)
		ETLog(@"Found neither image, icon nor view for %@", self);
		
	return img;
}

/* Actions */

/* You can override this method for your own custom layout item */
- (void) doubleClick
{

}

@end

/* Helper Category */

@implementation NSImage (ETLayoutItem)

- (NSImage *) initWithView: (NSView *)view
{
	self = [super init];
	
	if (self != nil)
	{
		NSRect viewFrameInWindow = NSMakeRect(0, 0, 32, 32); 
		NSBitmapImageRep *rep = nil;
		
		if ([view superview] != nil)
		{
			viewFrameInWindow = [[view superview] convertRect: [view frame] toView: nil];
			NSLog(@"Converted view frame %@ to %@ in window coordinates", 
				NSStringFromRect([view frame]), NSStringFromRect(viewFrameInWindow));
		}
		else
		{
			NSLog(@"FIXME: Unable to generate snapshot of view not located in a window yet");
			
			// FIXME: The following line probably doesn't work. We certainly 
			// need to put the view in a dummy off-screen window.
			viewFrameInWindow = [view frame];
			viewFrameInWindow.origin = NSZeroPoint;
		}
		rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect: viewFrameInWindow];
		
		[self addRepresentation: rep];
	}
	
	ETLog(@"Generated new image with reps %@ based on view %@", [self representations], view);
	
	return self;
}

@end
