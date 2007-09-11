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
#import <EtoileUI/ETInspector.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/GNUstep.h>

#define ETLog NSLog
#define ETUTIAttribute @"uti"

@interface ETLayoutItem (Private)
- (void) layoutItemViewFrameDidChange: (NSNotification *)notif;
@end

@interface ETLayoutItem (SubclassVisibility)
- (void) setDisplayView: (ETView *)view;
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
	subclassing, that's why the common solution is to implemente ETLayout
	delegate method called -layout:renderLayoutItem:. With this method you will
	be able to customize the rendering of layout items on the fly depending on
	the layout settings which may change between each rendering. */


@implementation ETLayoutItem

+ (ETLayoutItem *) layoutItemWithView: (NSView *)view
{
	return (ETLayoutItem *)AUTORELEASE([[self alloc] initWithView: view]);
}

- (id) init
{
	return [self initWithView: nil value: nil representedObject: nil];
}

- (id) initWithValue: (id)value
{
	return [self initWithView: nil value: value representedObject: nil];
}

- (id) initWithRepresentedObject: (id)object
{
	return [self initWithView: nil value: nil representedObject: object];
}

- (id) initWithView: (NSView *)view
{
	return [self initWithView: view value: nil representedObject: nil];
}

- (id) initWithView: (NSView *)view value: (id)value representedObject: (id)repObject
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
	DESTROY(_parentLayoutItem);
    
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
	
	desc = [@"<" stringByAppendingFormat: @"%@ id: %@, selected:%d>", 
		desc, [self identifier], [self isSelected]];
	
	return desc;
}

- (ETLayoutItemGroup *) rootItem
{
	if ([self parentLayoutItem] == nil)
	{
		return [self parentLayoutItem];
	}
	else
	{
		return [self rootItem];
	}
}

- (ETLayoutItemGroup *) parentLayoutItem
{
	return _parentLayoutItem;
}

- (void) setParentLayoutItem: (ETLayoutItemGroup *)parent
{
	[[self displayView] removeFromSuperview];
	ASSIGN(_parentLayoutItem, parent);
}

- (ETContainer *) closestAncestorContainer
{
	if ([[self displayView] isKindOfClass: [ETContainer class]])
		return (ETContainer *)[self displayView];
		
	if ([self parentLayoutItem] != nil)
	{
		return [[self parentLayoutItem] closestAncestorContainer];
	}
	else
	{
		ETLog(@"WARNING: Found no ancestor container by ending lookup on %@", self);
		return nil;
	}
}

- (ETView *) closestAncestorDisplayView
{
	if ([self displayView] != nil)
		return (ETContainer *)[self displayView];

	if ([self parentLayoutItem] != nil)
	{
		return [[self parentLayoutItem] closestAncestorDisplayView];
	}
	else
	{
		ETLog(@"WARNING: Found no ancestor display view by ending lookup on %@", self);
		return nil;
	}
}

- (NSIndexPath *) indexPathFromItem: (ETLayoutItem *)item
{
	NSIndexPath *indexPath = nil;
	
	if ([self parentLayoutItem] != nil && (item == nil || [self isEqual: item] == NO))
	{
		indexPath = [[self parentLayoutItem] indexPathFromItem: item];
		indexPath = [indexPath indexPathByAddingIndex: 
			[(ETLayoutItemGroup *)[self parentLayoutItem] indexOfItem: self]];
	}
	else
	{
		indexPath = AUTORELEASE([[NSIndexPath alloc] init]);
	}
	
	return indexPath;
}

/** Returns an index path relative to the receiver by traversing our layout 
	item subtree until we find item parameter and pushing parent relative index
	of each layout item in the sequence into an index path. 
	Resulting path uses internally '.' as path seperator and internally always 
	begins by an index number and not a path seperator. */
- (NSIndexPath *) indexPathForItem: (ETLayoutItem *)item
{
	if ([item isEqual: self])
		return [self indexPath];

	NSIndexPath *indexPath = [item indexPath];
	NSIndexPath *parentIndexPath = nil;
	NSIndexPath *receiverIndexPath = [self indexPath];
	unsigned int *indexPathIndexes; 
	
	if ([indexPath length] < [receiverIndexPath length])
		return nil;
	
	[indexPath getIndexes: indexPathIndexes];
	parentIndexPath = [NSIndexPath indexPathWithIndexes: indexPathIndexes length: [receiverIndexPath length]];
	
	if ([parentIndexPath isEqual: receiverIndexPath] == NO)
		return nil;
	

	unsigned int lengthDifference = [indexPath length] - [receiverIndexPath length];
	unsigned int receiverPosition = lengthDifference - 1; 
	
	[indexPath getIndexes: indexPathIndexes];
	indexPath = [NSIndexPath indexPathWithIndexes: &indexPathIndexes[receiverPosition] 
										   length: lengthDifference];
										   
	return indexPath;
}

/** Returns absolute index path of the receiver by collecting index of each
	parent layout item until the root layout item is reached (when -parentItem
	returns nil). 
	This method is equivalent to [[self rootItem] indexPathForItem: self]. */
- (NSIndexPath *) indexPath
{
	// TODO: Test whether it is worth to optimize or not
	return [[self rootItem] indexPathForItem: self];
}

/** Returns absolute path of the receiver by collecting the name of each
	parent layout item until the root layout item is reached (when -parentItem
	returns nil). 
	This method is equivalent to [[self rootItem] pathForIndexPath: 
	[[self rootItem] indexPathForItem: self]]. */
- (NSString *) path
{
	/* We rebuild the path by chaining names of the layout item tree to which 
	   we belong. */
	NSString *path = @"/";
	
	if ([self parentLayoutItem] != nil)
	{
		path = [[[self parentLayoutItem] path] 
			stringByAppendingPath: [self identifier]];
	}
	
	return path;
}

/** Returns the represented path. */
- (NSString *) representedPath
{
	NSString *path = [self representedPathBase];
	
	if (path == nil)
	{
		if ([self parentLayoutItem] != nil)
		{
			path = [[self parentLayoutItem] representedPath];
			path = [path stringByAppendingPathComponent: [self identifier]];
		}
		else
		{
			path = [self identifier];
		}
	}
	
	return path;
}

/** Returns the represented path base which is nil by default. This represented
	path base can be provided by a container, then allowing to build 
	represented paths for every descendant layout items which don't specify 
	their own custom represented path base (in other words when this method 
	returns nil). 
	By setting the represented path of a container, the related layout item 
	group is able to provide a represented path base automatically used by 
	descendant items. This represented path base is valid until a descendant 
	provides a new represented path base. */
- (NSString *) representedPathBase
{
	return nil;
}

/** Returns the identifier associated with the layout item. By default, the
	returned value is the name. If -name returns nil or an empty string, the
	identifier is a string made of the index used by the parent item to 
	reference the receiver. */
- (NSString *) identifier
{
	NSString *identifier = [self name];
	
	if (identifier == nil || [identifier isEqual: @""])
	{
		identifier = [NSString stringWithFormat: @"%d", 
			[[self parentLayoutItem] indexOfItem: self]];
	}
	
	return identifier;
}

/** Returns the name associated with the layout item.
	Take note the returned value can be nil or an empty string. */
- (NSString *) name
{
	return _name;
}

/** Sets the name associated with the layout item.
	Take note the returned value can be nil or an empty string. */
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
		/* Sync layout item frame with display view frame (see -setFrame:) */
		_frame = [_view frame];
		/* Restore view initial state */
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
	id value = nil;
	
	if ([_modelObject respondsToSelector: @selector(valueForProperty:)])
	{
		value = [_modelObject valueForProperty: key];
	}
	else if ([_modelObject respondsToSelector: @selector(objectForKey:)])
	{
		/* Useful for dictionary objects */
		value = [_modelObject objectForKey: key];
	}
	else
	{
		value = [_modelObject valueForKey: key];
	}
	
	return value;
}

/** Sets a value identified by key of the model object returned by 
	-representedObject. 
	See -valueForProperty: for more details. */
- (BOOL) setValue: (id)value forProperty: (NSString *)key
{
	BOOL result = YES;
	
	if ([_modelObject respondsToSelector: @selector(setValue:forProperty:)])
	{
		result = [_modelObject setValue: value forProperty: key];
	}
	else if ([_modelObject respondsToSelector: @selector(setObject:forKey:)])
	{
		/* Useful for dictionary objects */
		[_modelObject setObject: value forKey:key];
	}
	else
	{
		// FIXME: Catch key value coding exception here
		[_modelObject setValue: value forKey: key];
	}
	
	[self didChangeValueForKey: key];
	
	return result;
}

- (NSArray *) properties
{
	NSArray *properties = nil;

	/* Meta layout item responds to -properties because their represented
	   object is a layout item. Model objects may implement this method too. 
	   For example OrganizeKit objects responds to it. */
	if ([_modelObject respondsToSelector: @selector(properties)])
	{
		properties = (NSArray *)[_modelObject properties];
	}
	else if ([_modelObject respondsToSelector: @selector(entity)]
	 && [[_modelObject entity] respondsToSelector: @selector(properties)])
	{
		/* Managed Objects have an entity which describes them */
		properties = (NSArray *)[[_modelObject entity] properties];
	}
	else if ([_modelObject respondsToSelector: @selector(allKeys)])
	{
		/* Useful for dictionary objects */
		properties = [_modelObject allKeys];
	}
	else if ([_modelObject respondsToSelector: @selector(classDescription)])
	{
		/* Any objects can declare a class description, so we try to use it */
		NSClassDescription *desc = [_modelObject classDescription];
		
		properties = [NSMutableArray arrayWithObjects: [desc attributeKeys]];
		// NOTE: Not really sure we should include relationship keys
		[(NSMutableArray *)properties addObjects: (NSArray *)[desc toManyRelationshipKeys]];
		[(NSMutableArray *)properties addObjects: (NSArray *)[desc toOneRelationshipKeys]];
	}
	
	if (properties != nil && [properties count] == 0)
		properties = nil;
		
	return [properties copy];;
}

- (BOOL) isMetaLayoutItem
{
	return [_modelObject isKindOfClass: [ETLayoutItem class]];
}

- (void) didChangeValueForKey: (NSString *)key
{

}

- (NSView *) displayView
{
	return _view;
}

- (void) setDisplayView: (ETView *)view
{
	// FIXME
	NSView *enclosedView = nil;
}

// TODO: Modify to lookup for the selection state in the closest container ancestor
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

- (void) updateLayout
{
	/* See -apply: */
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
	[self updateLayout];
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

- (void) setNeedsDisplay: (BOOL)now
{
	NSRect displayRect = [self frame];
	
	/* If the layout item has a display view, this view will be asked to draw
	   by itself, so the rect to refresh must be expressed in display view
	   coordinates system and not the one of its superview. */
	if ([self displayView] != nil)
		displayRect.origin = NSZeroPoint;
		
	[[self closestAncestorDisplayView] setNeedsDisplayInRect: displayRect];
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
	if ([self displayView] != nil)
	{
		return [[self displayView] frame];
	}
	else
	{
		return _frame;
	}
}

- (void) setFrame: (NSRect)rect
{
	if ([self displayView] != nil)
	{
		[[self displayView] setFrame: rect];
	}
	else
	{
		_frame = rect;
	}
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
	/* Update display view frame only if needed */
	if (NSEqualRects(_defaultFrame, [[self displayView] frame]) == NO)
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

- (void) showInspectorPanel
{
	[[[self inspector] panel] makeKeyAndOrderFront: self];
}

- (id <ETInspector>) inspector
{
	ETContainer *container = [self closestAncestorContainer];
	id <ETInspector> inspector = nil;
	
	if (container != nil)
		inspector = [container inspector];
		
	if (inspector != nil)
		[inspector setInspectedItems: [NSArray arrayWithObject: self]];
		
	return inspector;
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
