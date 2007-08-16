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
#import <EtoileUI/ETView.h>
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
		[self setVisible: NO];
		[self setStyleRenderer: AUTORELEASE([[ETSelection alloc] init])];
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
	[item setFrame: [self frame]];
	[item setAppliesResizingToBounds: [self appliesResizingToBounds]];
	
	return item;
}

- (NSString *) description
{
	NSString *desc = [super description];
	
	desc = [@"<" stringByAppendingFormat: @"%@ selected:%d>", desc, [self isSelected]];
	
	return desc;
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
	if ([_value isKindOfClass: [NSImage class]])
	{
		ETImageStyle *imgStyle = [ETImageStyle styleWithImage: (NSImage *)_value];
		
		[self setDefaultFrame: ETMakeRect(NSZeroPoint, [_value size])];
		[self setStyleRenderer: imgStyle];
	}
	else if ([_value isKindOfClass: [NSString class]])
	{
	
	}
	else if ([_value isKindOfClass: [NSAttributedString class]])
	{
	
	}
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
	if ([_view isKindOfClass: [ETView class]] && [_view wrappedView] != nil)
	{
		return [_view wrappedView];
	}
	else
	{
		return _view;
	}
}

- (void) setView: (NSView *)view
{
	BOOL resizeBoundsActive = [self appliesResizingToBounds];
	ETView *wrapperView = nil;
	
	if (_view != nil)
	{
		[_view setFrame: [self defaultFrame]];
		[_view setRenderer: nil];
		/* Stop to observe notifications on current view and reset bounds size */
		[self setAppliesResizingToBounds: NO];
	}
	
	_defaultFrame = NSZeroRect;
	
	/* When the view isn't an ETView instance, we wrap it inside a new ETView 
	   instance to have -drawRect: asking the layout item to render by itself. */
	if ([view isKindOfClass: [ETView class]])
	{
		wrapperView = (ETView *)view;
	}
	else if ([view isKindOfClass: [NSView class]])
	{
		NSAssert1(view != nil, @"A nil view must not be wrapped in -setView: of %@", self);
		wrapperView = [[ETView alloc] initWithFrame: [view frame]];
		[wrapperView setWrappedView: view];
		AUTORELEASE(wrapperView);
	}
	
	ASSIGN(_view, wrapperView);
	
	if (_view != nil)
	{
		[_view setRenderer: self];
		[self setDefaultFrame: [_view frame]];
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
	[self didChangeValueForKey: key];
}

- (void) didChangeValueForKey: (NSString *)key
{

}

- (NSView *) displayView
{
	return _view;
}

- (void) setSelected: (BOOL)selected
{
	NSLog(@"Set layout item selection state %@", self);
	_selected = selected;
}

- (BOOL) isSelected
{
	return _selected;
}

- (void) setVisible: (BOOL)visible
{
	_visible = visible;
}

- (BOOL) isVisible
{
	return _visible;
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

/** Allows to compute the layout of the whole layout item tree without any 
	rendering/drawing. The layout begins with layout item leaves which can 
	simply returns their size, then moves up to layout item node which can 
	compute their layout and by side-effect their size. The process is 
	continued until the root layout item associated with a container is 
	reached.
	inputValues is usually nil. */
- (void) apply: (NSMutableDictionary *)inputValues
{
	
}

/** Propagates rendering/drawing in the layout item tree.
	This method doesn't involve any layout and size computation of the layout 
	items. If you need to do layout or size computation, implement the method
	-apply: in addition to this one.
    Override */
- (void) render: (NSMutableDictionary *)inputValues
{
	/* When we have a view, we wait to be asked to draw directly by our view 
	   before rendering anything. If a parent layout item asks us to draw, we
	   decline and wait the control return to the view who initiated the 
	   drawing and this view asks our view to draw itself as a subview. */
	//if ([self view] == nil) // || [[NSView focusView] isEqual: [[self displayView] superview]]
	{
		[_renderer renderLayoutItem: self];
	}
}

- (void) render: (NSMutableDictionary *)inputValues dirtyRect: (NSRect)dirtyRect inView: (NSView *)view 
{
	if (NSIntersectsRect(dirtyRect, [self frame]))
	{
		if ([[NSView focusView] isEqual: view] == NO)
			[view lockFocus];
			
		NSAffineTransform *transform = [NSAffineTransform transform];
		
		/* Modify coordinate matrix when the layout item doesn't use a view for 
		   drawing. */
		if ([self displayView] == nil)
		{
			[transform translateXBy: [self x] yBy: [self y]];
			[transform concat];
		}
		
		[[self renderer] renderLayoutItem: self];
		
		[transform invert];
		[transform concat];
			
		[view unlockFocus];
	}
}

- (void) render
{
	[self render: nil];
}

- (void) lockFocus
{
	// FIXME: Finds the first layout item ancestor with a view and asks it to
	// redraw itself at our rect location, this will flow back to us.
}

- (void) unlockFocus
{

}

// NOTE: Will probably become - (ETService *) renderer;
- (ETStyleRenderer *) renderer
{
	return _renderer;
}

- (void) setStyleRenderer: (ETStyleRenderer *)renderer
{
	ASSIGN(_renderer, renderer);
}

- (NSRect) frame
{
	return _frame;
}

- (void) setFrame: (NSRect)rect
{
	_frame = rect;
	if ([self displayView] != nil)
		[[self displayView] setFrame: rect];
}

- (NSPoint) origin
{
	return [self frame].origin;
}

- (void) setOrigin: (NSPoint)origin
{
	NSRect newFrame = [self frame];
	
	newFrame.origin = origin;
	[self setFrame: newFrame];
}

- (NSSize) size
{
	return [self frame].size;
}

- (void) setSize: (NSSize)size
{
	NSRect newFrame = [self frame];
	
	newFrame.size = size;
	[self setFrame: newFrame];
}

- (float) x
{
	return [self frame].origin.x;
}

- (void) setX: (float)x
{
	[self setOrigin: NSMakePoint(x, [self y])];
}

- (float) y
{
	return [self frame].origin.y;
}

- (void) setY: (float)y
{
	[self setOrigin: NSMakePoint([self x], y)];
}

- (float) height
{
	return [self size].height;
}

- (void) setHeight: (float)height
{
	[self setSize: NSMakeSize([self width], height)];
}

- (float) width
{
	return [self size].width;
}

- (void) setWidth: (float)width
{
	[self setSize: NSMakeSize(width, [self height])];
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
	[self setFrame: [self defaultFrame]]; 
}

/** When the layout item uses a view, pass YES to this method to have the 
	content resize when the view itself is resized (by modifying frame).
	Resizing content in a view is possible by simply updating bounds size to 
	match the view frame. 
	Presently uses in ETPaneSwitcherLayout. */
- (void) setAppliesResizingToBounds: (BOOL)flag
{
	_resizeBounds = flag;
	
	if ([self displayView] == nil)
	{
		NSLog(@"WARNING: -setAppliesResizingToBounds: called with no view for %@", self);
		return;
	}
	
	if (_resizeBounds && [self displayView] != nil)
	{
		[[NSNotificationCenter defaultCenter] addObserver: self 
		                                         selector: @selector(layoutItemViewFrameDidChange:) 
												     name: NSViewFrameDidChangeNotification
												   object: [self displayView]];
		/* Fake notification to update bounds size */
		[self layoutItemViewFrameDidChange: nil];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] removeObserver: self];
		/* Restore bounds size */
		[[self displayView] setBoundsSize: [[self displayView] frame].size];
		[[self displayView] setNeedsDisplay: YES];
	}
}

- (BOOL) appliesResizingToBounds
{
	return _resizeBounds;
}

- (void) layoutItemViewFrameDidChange: (NSNotification *)notif
{
	NSAssert1([self displayView] != nil, @"View of %@ cannot be nil on view notification", self);
	NSAssert1([self appliesResizingToBounds] == YES, @"Bounds resizing must be set on view notification in %@", self);
	
	ETLog(@"Receives NSViewFrameDidChangeNotification in %@", self);
	
	// FIXME: the proper way to handle such scaling is to use an 
	// NSAffineTransform and applies to item view in 
	// -resizeLayoutItems:scaleFactor: when -appliesResizingToBounds returns YES
	[[self displayView] setBoundsSize: [self defaultFrame].size];
	[[self displayView] setNeedsDisplay: YES];
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
