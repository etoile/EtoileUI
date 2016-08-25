/** <title>ETHandle</title>
	
	<abstract>An ETLayoutItem subclass whose instances represent control points to 
	manipulate the graphical representation of layout items.</abstract>

	Copyright (C) 2008 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date: November 2008
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileUI/ETGraphicsBackend.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETActionHandler.h>
#import <EtoileUI/ETStyle.h>

@class COObjectGraphContext;
@class ETTool; 

extern NSString *kETMediatedToolProperty; /** mediatedTool property */
extern NSString *kETManipulatedObjectProperty; /** manipulatedObject property */

/** A handle mediates the interaction between an tool (usually a graphical 
tool) and a graphical object.
 
The handle is attached to a graphical object by setting the ETHandle
manipulatedObject property. The graphical object is commonly a layout item, In
future, this might be extended in order to accept other type of objects that
conforms to ETManipulatedObject protocol.

The action of a handle when the user manipulates it is defined by setting the
EtHandle mediatedTool property. */
 @interface ETHandle : ETLayoutItem
 {
 
 }

- (instancetype) initWithActionHandler: (ETActionHandler *)aHandler 
           manipulatedObject: (id)aTarget
          objectGraphContext: (COObjectGraphContext *)aContext NS_DESIGNATED_INITIALIZER;
 
 @property (nonatomic, strong) ETTool *mediatedTool;
 @property (nonatomic, strong) id manipulatedObject;

 
 @end
 
/** Handles are rarely used alone, but in a handle group which organize and 
present the handles in a way that helps to mediate the tool actions. 
For example, four handles can be combined in resizing rectangle and makes 
the resize tool more straightforward to use for the user. */
@interface ETHandleGroup : ETLayoutItemGroup
{
	
}

//- (ETTool *) mediatedTool;
//- (void) setMediatedTool: (ETTool *)anTool;
@property (nonatomic, strong) id manipulatedObject;
- (void) setNeedsDisplay: (BOOL)flag;
@property (nonatomic, readonly) BOOL acceptsActionsForItemsOutsideOfFrame;

@end

@interface ETResizeRectangle : ETHandleGroup
{

}

- (instancetype) initWithManipulatedObject: (id)aTarget
              objectGraphContext: (COObjectGraphContext *)aContext NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) ETHandle *topLeftHandle;
@property (nonatomic, readonly) ETHandle *topRightHandle;
@property (nonatomic, readonly) ETHandle *bottomRightHandle;
@property (nonatomic, readonly) ETHandle *bottomLeftHandle;
@property (nonatomic, readonly) ETHandle *leftHandle;
@property (nonatomic, readonly) ETHandle *rightHandle;
@property (nonatomic, readonly) ETHandle *topHandle;
@property (nonatomic, readonly) ETHandle *bottomHandle;

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

@interface ETLeftHandleActionHandler : ETHandleActionHandler
- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta;
@end

@interface ETRightHandleActionHandler : ETHandleActionHandler
- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta;
@end

@interface ETTopHandleActionHandler : ETHandleActionHandler
- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta;
@end

@interface ETBottomHandleActionHandler : ETHandleActionHandler
- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta;
@end

@interface ETBasicHandleStyle : ETStyle
- (void) drawHandleInRect: (NSRect)rect;
- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect;
@end
