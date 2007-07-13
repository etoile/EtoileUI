//
//  ETLayoutItem.m
//  FlowAutolayoutExample
//
//  Created by Quentin Mathé on 27/12/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ETLayoutItem.h"
#import "ETStyleRenderer.h"
#import "NSView+Etoile.h"
#import "GNUstep.h"

#define ETLog NSLog

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

/** Forwards rendering along the container tree. 
    Override */
- (void) render
{
	[_renderer render];

	if ([[self view] respondsToSelector: @selector(render)])
		[(id)[self view] render];
}

- (ETStyleRenderer *) renderer
{
	return _renderer;
}

- (void) setStyleRenderer: (ETStyleRenderer *)renderer
{
	ASSIGN(_renderer, renderer);
}

// FIXME: This doesn't take in account when view frame is modified afterwards
// by calling -[NSView setFrame:]
- (NSRect) defaultFrame { return _defaultFrame; }

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

/* Actions */

/* You can override this method for your own custom layout item */
- (void) doubleClick
{

}

@end
