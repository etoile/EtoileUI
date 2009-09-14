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
