/** <title>ETEvent</title>
	
	<abstract>EtoileUI-native event class that represents events to be 
	dispatched and handled in the layout item tree.</abstract>
 
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/NSEvent.h>

// FIXME: Don't expose NSDraggingInfo, NSEvent and NSWindow in the public API.
@protocol NSDraggingInfo;
@class NSWindow;
@class ETLayoutItem, ETUIItem, ETWindowItem;

// WARNING: API a bit unstable.

/** Shorcut to convert a backend event into a native EtoileUI event. */
#define ETEVENT(evt, drag, pick) [ETEvent eventWithBackendEvent: (void *)evt type: [evt type] pickingMask: pick draggingInfo: drag layoutItem: nil]

@protocol ETKeyInputAction
@property (nonatomic, readonly) NSString *characters;
@property (nonatomic, readonly) unsigned int modifierFlags;
@end

/** Represents an arbitrary touch action. The input device can be a mouse, a 
stylus, one or multiple fingers etc. */
@protocol ETTouchAction
/** Returns the hit item set by the active tool. */
@property (nonatomic, readonly) ETLayoutItem *layoutItem;
/** See -[ETEvent locationInLayoutItem]. */
@property (nonatomic, readonly) NSPoint locationInLayoutItem;
// TODO: Support the methods below.
/*- (NSPoint) tilt;
- (CGFloat) pressure;
- (CGFloat) rotation;
- (CGFloat) tangentialPressure;
- (NSArray *) touchedLayoutItems;*/
@end

/** These constants allows to encode the pick and drop combinations that 
characterize drag/drop vs copy/cut/paste in EtoileUI. Read -setPickingMask: for 
the details. */
enum : NSUInteger {
	ETNonePickingMask = 0,
	ETPickPickingMask = 2,
	ETCopyPickingMask = 4,
	ETCutPickingMask = 8,
	ETDragPickingMask = 16,
	ETDropPickingMask = 32,
	ETPastePickingMask = 64
// NOTE: May be we should have distinct picking and dropping mask.
};

/** EtoileUI uses ETEvent objects to represent events to be dispatched and 
handled in the layout item tree. These events usually represent device events 
(mouse, keyboard etc.). When they get dispatched, they can be refined into more 
specialized actions such as cut/copy/paste with the pickingMask property, as 
explained below.
 
With EtoileUI event handling model, layout items don't receive ETEvent objects, 
but those events are passed to the active tool or tool which turns them 
into actions. Only actions rather than raw events are delivered to the targeted 
layout items. See ETTool and ETActionHandler. A layout item can also be 
attached to the event. For example, this can be used to easily keep track of 
the item initially targeted by the event. -[ETTool hitTestWithEvent:] does 
that: the layout item on which the dispatch is expected, is attached to the 
event.

Every EtoileUI events are created by processing the events emitted by the widget 
backend, and wrapping them into a native ETEvent instance. The wrapped event 
can be retrieved through -backendEvent. 

For now, only AppKit is supported as a backend, so -backendEvent will always 
return an NSEvent. Moreover the event types are the same than NSEventType enum, 
this is expected to change though. */
@interface ETEvent : NSObject <ETKeyInputAction, ETTouchAction>
{
	@private
	NSEvent *_backendEvent; // TODO: Move that in a subclass specific to each backend
	ETLayoutItem *_layoutItem;
	id <NSDraggingInfo> _draggingInfo; // TODO: Should be backend-agnostic, may be move in a subclass...

	NSPoint _locationInLayoutItem;
	NSEventType _type; // TODO: Should be backend-agnostic, probably ETEventType with our own enum...
	unsigned int _pickingMask;
	BOOL _isUIEvent;
	BOOL _wasDelivered;
}

+ (ETEvent *) eventWithBackendEvent: (void *)evt 
                               type: (NSEventType)type
                        pickingMask: (unsigned int)pickMask 
                       draggingInfo: (id)drag
                         layoutItem: (ETLayoutItem *)item;         
+ (ETEvent *) enterEventWithEvent: (ETEvent *)anEvent;
+ (ETEvent *) exitEventWithEvent: (ETEvent *)anEvent 
					  layoutItem: (ETLayoutItem *)exitedItem;

@property (nonatomic, getter=isUIEvent, readonly) BOOL UIEvent;
@property (nonatomic, readonly) NSEventType type;

/* Event Dispatch Status */

@property (nonatomic, readonly) BOOL wasDelivered;
- (void) markAsDelivered;
@property (nonatomic, strong) id layoutItem;
@property (nonatomic) NSPoint locationInLayoutItem;
@property (nonatomic) unsigned int pickingMask;

/* Input Device Data */

@property (nonatomic, readonly) int clickCount;
@property (nonatomic, readonly) NSString *characters;
@property (nonatomic, readonly) unsigned int modifierFlags;

/* Event Location */

@property (nonatomic, readonly) ETUIItem *contentItem;
@property (nonatomic, readonly) ETWindowItem *windowItem;
@property (nonatomic, readonly) NSPoint locationInWindowItem;
@property (nonatomic, readonly) NSPoint locationInWindowContentItem;
@property (nonatomic, readonly) NSPoint location;

/* Widget Backend Integration */

@property (nonatomic, getter=isWindowDecorationEvent, readonly) BOOL windowDecorationEvent;
@property (nonatomic, readonly) void *backendEvent;
@property (nonatomic, readonly) int windowNumber;
@property (nonatomic, readonly) id contentView;

/* Deprecated */

// FIXME: Remove by not relying on it in our code... it exposes a class that 
// is only valid for the AppKit backend.
@property (nonatomic, readonly) NSWindow *window;
@property (nonatomic, readonly, strong) id draggingInfo;
@property (nonatomic, readonly) NSPoint draggingLocation;
@property (nonatomic, readonly) NSPoint locationInWindow;

@end
