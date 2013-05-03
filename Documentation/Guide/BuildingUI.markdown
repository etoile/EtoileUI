Building UI
===========

For creating UI, EtoileUI includes a dedicated class ETLayoutItemFactory that provide various reusable items. By using it, you don't have to worry about picking the right aspects and gluing them together onto an item in a way that respects EtoileUI best practices.


Separators
----------

You can create a separator item that is flexible but won't fill the remaining space in a layout. To do so, just set the separator autoresizing to ETAutoresizingFlexibleWidth (for ETLineLayout or ETFlowLayout) or ETAutoresizingFlexibleHeight (for ETColumnLayout).

For a resizing, the remaining space is split equally among all flexible separator times, in other words the flexible separator growth is the same than other flexible items. For example, if you have a 20px button and 30px separator, for a 50px resize, the button is resized to 45px and the separator to 55px.

On the other hand, for a flexible separator time that just fills all the remaining space in a layout, you can use -flexibleSeparatorItem. If there are multiple flexible fill separator items, the remaining space is simply divided between them equally.

Flexible fill separators are the last resized items in a layout, so this lets a resize opportunity for other flexible items that don't attempt to fill the space.


Autoresizing
------------

For reacting to resizing in the item tree, EtoileUI provides basic autoresizing constraints that layouts can interpret in their own way. 
Autoresizing constraints are set using -[ETLayoutItem setAutoresizingMask:] and encodes how the receiver reacts to its parent item content bounds resizing. If a decorator item such as ETScrollableAreaItem is used, remember that resizing the parent item frame doesn't result in a content bounds change.

ETFixedLayout and its subclasses such as ETFreeLayout interpret all the autoresizing constraints unlike other ETLayout classes, that usually interpret just a constraint subset or even none. For example, ETColumnLayout and ETLineLayout take in account ETAutoresizingFlexibleHeight and ETAutoresizingFlexibleWidth but ignores all the other autoresizing values.

Note: a layout subclass can implement its own autoresizing strategy by overriding -[ETLayout resizeItems:forNewLayoutSize:oldSize:].

If you set a view on a layout item using -[ETLayoutItem setView:], this doesn't change the item autoresizing mask. If you want to reuse the view autoresizing mask, you can use -[ETLayoutItemFactory itemWithView:] that ensures the item autoresizing mask matches the given view. 

Note: When converting AppKit UI into EtoileUI item tree using ETLayoutItemBuilder, AppKit autoresizing mask are transparently converted into EtoileUI autoresizing mask by using -[ETLayoutItemFactory itemWithView:].

When resizing a layout item, autoresizing result isn't visible until the parent item layout is updated. Automatic layout updates are executed once the current event has been handled. This means that autoresizing works transparently in response to user resizing actions, but won't bother when building the UI. For example, the three code pieces produce to the same resizing results, the method invocation order don't matter:

	[item setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[itemGroup addItem: item];
	[itemGroup setWidth: 500];

	[item setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[itemGroup setWidth: 500];
	[itemGroup addItem: item];

	[itemGroup setWidth: 500];
	[itemGroup addItem: item];
	[item setAutoresizingMask: ETAutoresizingFlexibleWidth];

For creating new item group, it's important to pass it the right size at initialization time, because calling -setSize: later is going to autoresize the child items. The size passed to methods such as -[ETLayoutItemFactory itemGroupWithFrame:] become the old layout size that is going to be passed to -[ETLayout resizeItems:forNewLayoutSize:oldSize:] the next time the layout is updated.

If you want to force autoresizing computation at some point, because it's easier to build the UI at some size then resize it to get the UI that is presented to the user, you can use -[ETLayoutItem updateLayout] or -[ETLayoutItem updateLayoutRecursively:]. For example, the two code pieces below don't result in the same resizing and UI arrangement:

	[item setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[itemGroup setWidth: 500];
	[itemGroup addItem: item];

	[item setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[itemGroup setWidth: 500];
	// Update the itemGroup layout size width to 500 rather remaining at the initialization time value
	[itemGroup updateLayout];
	// Mark the receiver as needing a layout update, but won't cause a new autoresizing computation 
	// because the layout size has already been updated just before
	[itemGroup addItem: item];

Forcing layout updates is also used in action handlers to update the layout continuously and smoothly during a live resize. To support smooth live resizing of windows, EtoileUI invokes -updateLayout on the item tree bound to the window on every resize step.
