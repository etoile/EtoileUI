/** <title>EtoileUI Property Constants</title>
	
	<abstract>Property names widely used through EtoileUI as string constants.
	</abstract>

	Copyright (C) 2009 Quentin Mathe

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  August 2009
	License: Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>

extern NSString * const kETAcceptsActionsProperty; /** acceptsActions property name */
extern NSString * const kETActionHandlerProperty; /** actionHandler property name */
extern NSString * const kETActionProperty; /** actionHandler property name */
extern NSString * const kETAnchorPointProperty; /** anchorPoint property name */
extern NSString * const kETAutoresizingMaskProperty; /** autoresizingMask property name */
extern NSString * const kETBaseItemProperty; /** baseItem property name */
extern NSString * const kETBoundingBoxProperty; /** boudingBox property name */
extern NSString * const kETContentAspectProperty; /** contentAspect property name */
extern NSString * const kETContentBoundsProperty; /** contentBounds property name */
extern NSString * const kETControllerProperty; /** controller property name */
extern NSString * const kETControllerItemProperty; /** controllerItem property name */
extern NSString * const kETCoverStyleProperty; /** coverStyle property name */
extern NSString * const kETDecoratedItemProperty; /** decoratedItem property name */
extern NSString * const kETDecoratorItemProperty; /** decoratorItem property name */
extern NSString * const kETDefaultFrameProperty; /** defaultFrame property name */
extern NSString * const kETDelegateProperty; /** delegate property name */
extern NSString * const kETDisplayNameProperty; /** displayName property name */
extern NSString * const kETDoubleClickedItemProperty; /** doubleClickedItem property name */
extern NSString * const kETFlippedProperty; /** flipped property name */
extern NSString * const kETFrameProperty; /** frame property name */  
extern NSString * const kETHeightProperty; /** height property name */
extern NSString * const kETIconProperty; /** icon property name */
extern NSString * const kETIdentifierProperty; /** identifier property name */
extern NSString * const kETImageProperty; /** image property name */
extern NSString * const kETIsBaseItemProperty; /** isBaseItem property name */
extern NSString * const kETIsMetaItemProperty; /** isMetaItem property name */
extern NSString * const kETItemScaleFactorProperty; /** itemScaleFactor property name */
extern NSString * const kETLayoutProperty; /** layout property name */
extern NSString * const kETNameProperty; /** name property name */
extern NSString * const kETNeedsDisplayProperty; /** needsDisplay property name */
extern NSString * const kETNextResponderProperty; /** nextResponder property name */
extern NSString * const kETParentItemProperty; /** parentItem property name */
extern NSString * const kETPersistentFrameProperty; /** persistentFrame property name */
extern NSString * const kETPositionProperty; /** position property name */
extern NSString * const kETRepresentedObjectProperty; /** representedObject property name */
extern NSString * const kETRootItemProperty; /** rootItem property name */
extern NSString * const kETSelectedProperty; /** selected property name */
extern NSString * const kETSelectableProperty; /** selectable property name */
extern NSString * const kETSourceProperty; /** source property name */
extern NSString * const kETStyleGroupProperty; /** styleGroup property name */
extern NSString * const kETStyleProperty; /** style property name */
extern NSString * const kETSubjectProperty; /** subject property name */
extern NSString * const kETSubtypeProperty; /** subtype property name */
extern NSString * const kETTargetProperty; /** actionHandler property name */
extern NSString * const kETTransformProperty; /** transform property name */
extern NSString * const kETUTIProperty; /** UTI property name */
extern NSString * const kETValueProperty; /** value property name */
extern NSString * const kETValueKeyProperty; /** valueKey property name */
extern NSString * const kETViewProperty; /** view property name */
extern NSString * const kETVisibleProperty; /** visible property name */
extern NSString * const kETWidthProperty; /** width property name */
extern NSString * const kETXProperty; /** x property name */
extern NSString * const kETYProperty; /** y property name */


/* Pickboard Item Metadata */

extern NSString * const kETPickMetadataWasUsedAsRepresentedObject; /** Boolean metadata property (optional).

If YES, a dropped item will be inserted as a represented object (being boxed 
by -[ETLayoutItemGroup insertObject:atIndex:hint:box:]). */
extern NSString * const kETPickMetadataPickIndex; /** Number metadata property (required).

For the item on which the pick occured, the index in the parent item it 
belonged to.  */
extern NSString * const kETPickMetadataDraggedItems; /** Array metadata property (optional).

When the pick operation is a drag, tracks the picked items.<br />
For custom objects put on the pickboard, allows to retrieve the original items 
on drop. If both the drag source and drop target uses the same base item, the 
items can be moved (rather than creating new ones).  */
extern NSString * const kETPickMetadataCurrentDraggedItem; /** ETLayoutItem metadata property (optional).

When enumerating a pick collection, the dragged item that corresponds to the 
dropped object in -[ETActionHandler handleDropObject:hint:metadata:atIndex:coordinator]. */
extern NSString * const  kETPickMetadataWereItemsRemoved; /** Boolean Number metadata property (required).
														   
Indicates whether the dragged items were removed immediately when they were picked.
														   
See also -shouldRemoveItemsAtPickTime in ETTool subclasses that implements it such as ETSelectTool. */

/* Private Pickboard Item Properties */

extern NSString * const kETPickMetadataProperty; /** pickMetadata property name */


/* Commit Descriptor Identifiers */

extern NSString * const kETCommitItemInsert;
extern NSString * const kETCommitRectangleInsert;
extern NSString * const kETCommitItemRemove;
extern NSString * const kETCommitItemDuplicate;

// TODO: Add kETCommitItemMove/ResizeFromInspector
extern NSString * const kETCommitItemMove;
extern NSString * const kETCommitItemResize;
extern NSString * const kETCommitItemReorder;
extern NSString * const kETCommitItemRegroup;
extern NSString * const kETCommitItemUngroup;
extern NSString * const kETCommitItemSendToBack;
extern NSString * const kETCommitItemBringToFront;
extern NSString * const kETCommitItemSendBackward;
extern NSString * const kETCommitItemBringForward;

extern NSString * const kETCommitObjectDrop;
