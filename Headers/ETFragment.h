/** <title>ETFragment</title>

	<abstract>Protocol to represent all visual fragments whether or not they are
	explictly represented in the layout item tree.</abstract>

	Copyright (C) 2009 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  September 2009
	License:  Modified BSD (see COPYING)
 */

/* A fragment can be either:
<list>
<item>explicit, e.g. any layout item</item>
<item>implicit, e.g. any other layout element</item>
</list>

A implicit fragment is typically used to model a spatial grouping, required by 
a layout, but which contradicts the existing layout item tree organization. 
Here are two examples:
<list>
<item>In a flow layout, the line break algorithm divides the layout items into 
line fragments although those continue to belong to the same parent item.</item>
<item>In a table layout, the columns express an alternative viewpoint 
(column-oriented) on the underlying data. Since the data is exposed in the 
row-oriented viewpoint expressed by the layout item tree, the table is divided 
into column fragments and not column items otherwise each property/value pair 
would have to become a layout item and the row wouldn't represent a single 
object anymore but a property/value pair collection. These property/value 
pairs as distinct objects would then be intepreted as multiple rows which is not 
what we want.</item>
</list> 

The viewpoint on the data is initially provided by your model and whether it 
implements ETCollection protocol or not. */
@protocol ETFragment

- (NSPoint) origin;
- (void) setOrigin: (NSPoint)location;
- (float) height;
- (float) width;

@end


/** Layout fragments never interact directly with the items they embed, but 
through a mediator object that must implement the ETLayoutFragmentOwner protocol.

This protocol lets the objects that implements it the possibility to customize 
how the item geometry is exposed (with a NSValueTransformer-like behavior).<br />

Every item inserted into a layout fragment must match the item type expected by 
its owner in the protocol methods.

Any computed layout can be used transparently in this owner role.
See ETLineFragment (layout fragment) and ETComputedLayout (layout fragment owner). */
@protocol ETLayoutFragmentOwner
- (NSRect) rectForItem: (id)anItem;
- (void) setOrigin: (NSPoint)newOrigin forItem: (id)anItem;
@end


/** Represents a column in a layout, and to which corresponds no item in the 
layout item tree. For example, a value list column in a ETTableLayout.

The protocol allows to control the column size and how the size should be 
treated under various circumstances:

<list>
<item>the layout is updated or resized</item>
<item>the user resizes a column</item>
</list>

Warning: this API will probably evolve a bit. */
@protocol ETColumnFragment
/** Sets the column width. */
- (void) setWidth: (float)width;
/** Returns the column width. */
- (float) width;
/** Sets the minimum width allowed and resizes the column if the current width 
is inferior. */
- (void) setMinWidth: (float)width;
/** Returns the minimum width allowed. */
- (float) minWidth; 
/** Sets the maximum allowed width and resizes the column if the current width 
is superior. */
- (void) setMaxWidth: (float)width;
/** Returns the maximum width allowed. */
- (float) maxWidth;
/** Sets the resizing behavior:

<deflist>
<term>NSTableColumnNoResizing</term>
<desc>The column cannot be resize at all</desc>
<term>NSTableColumnAutoresizingMask</term>
<desc>When the layout is resized, it adjusts the column size in its own way</desc>
<term>NSTableColumnUserResizingMask</term>
<desc>The column can be resized by the end-user</desc>
</deflist>

TODO: We should have our own enum rather than the one documented above.*/
- (void) setResizingMask: (NSUInteger)mask;
/** Returns the resizing behavior. See -setResizingMask:. */
- (NSUInteger) resizingMask;
@end
