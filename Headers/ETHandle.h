/** <title>ETHandle</title>
	
	<abstract>An ETLayoutItem subclass whose instances represent control points to 
	manipulate the graphical representation of layout items.</abstract>

	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date: November 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETActionHandler.h>
#import <EtoileUI/ETStyle.h>

@class ETInstrument; 

extern NSString *kETMediatedInstrumentProperty; /** mediatedInstrument property */
extern NSString *kETManipulatedObjectProperty; /** manipulatedObject property */

/** A handle mediates the interaction between an instrument (usually a graphical 
tool) and a graphical object.
 
The handle is attached to a graphical object by setting the ETHandle
manipulatedObject property. The graphical object is commonly a layout item, In
future, this might be extended in order to accept other type of objects that
conforms to ETManipulatedObject protocol.

The action of a handle when the user manipulates it is defined by setting the
EtHandle mediatedInstrument property. */
 @interface ETHandle : ETLayoutItem
 {
 
 }
 
 - (ETInstrument *) mediatedInstrument;
 - (void) setMediatedInstrument: (ETInstrument *)anInstrument;
 - (id) manipulatedObject;
 - (void) setManipulatedObject: (id)anObject;
 
 @end
 
/** Handles are rarely used alone, but in a handle group which organize and 
present the handles in a way that helps to mediate the instrument actions. 
For example, four handles can be combined in resizing rectangle and makes 
the resize tool more straightforward to use for the user. */
@interface ETHandleGroup : ETLayoutItemGroup
{
	
}

//- (ETInstrument *) mediatedInstrument;
//- (void) setMediatedInstrument: (ETInstrument *)anInstrument;
- (id) manipulatedObject;
- (void) setManipulatedObject: (id)anObject;
- (void) setNeedsDisplay: (BOOL)flag;
- (BOOL) acceptsActionsForItemsOutsideOfFrame;

@end

@interface ETResizeRectangle : ETHandleGroup
{

}

- (id) initWithManipulatedObject: (id)aTarget;

- (ETHandle *) topLeftHandle;
- (ETHandle *) topRightHandle;
- (ETHandle *) bottomRightHandle;
- (ETHandle *) bottomLeftHandle;

- (void) render: (NSMutableDictionary *)inputValues 
	  dirtyRect: (NSRect)dirtyRect
      inContext: (id)ctxt;
- (void) drawOutlineInRect: (NSRect)rect;

@end

/* Action and Style Aspects */

@interface ETHandleActionHandler : ETActionHandler
- (BOOL) canSelect: (ETHandle *)handle;
@end

@interface ETBottomLeftHandleActionHandler : ETHandleActionHandler
- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta;
@end

@interface ETBottomRightHandleActionHandler : ETHandleActionHandler
- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta;
@end

@interface ETTopLeftHandleActionHandler : ETHandleActionHandler
- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta;
@end

@interface ETTopRightHandleActionHandler : ETHandleActionHandler
- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta;
@end

@interface ETBasicHandleStyle : ETStyle
+ (id) sharedInstance;
- (void) drawHandleInRect: (NSRect)rect;
- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect;
@end
