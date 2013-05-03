Responder Chain
===============

EtoileUI has a responder object concept. A responder is an object that adopts ETResponder protocol and can handle actions sent by tools or widgets. Responders are chained in the layout item tree through -[ETResponder nextResponder]. In addition, a responder can also catch notification-like messages sent upwards in the item tree through the responder chain.

Various object types are responders in the layout item tree:

- ETUIItem (this includes subclasses such as ETDecorator, ETLayoutItem and ETLayoutItemGroup)
- ETController
- ETActionHandler


Reacting to Actions
-------------------

Actions are handled at two levels: action handlers and controllers.

Action handlers handles actions that concerns a single item or children items that share the same parent.  Among these 

Actions targeting multiple items at the same time are usually selection-based actions through a selection tool. ETSelectTool is the built-in selection tool, and in response to an event, it can send the same action message to every selected item. By default, action handlers don't implement actions that takes multiple items or indexes in argument. 


Implementing Actions in Action Handlers

All action methods in the action handler must declare their signature using a precise pattern. The first argument must be the sender and the second argument the item targeted by the action. In addition, the method keyword for the second argument must be <em>onItem:</em>. Here are some valid action methods:


	- (void) insertRectangle: (id)sender onItem: (ETLayoutItem *)item;
	- (void) sendBackward: (id)sender onItem: (ETLayoutItem *)item;

For dispatching actions based on the focused item and propagating notifications to enclosing objects in the layout item tree


Implementing Batch Actions in Action Handlers
---------------------------------------------

Not yet supported… Still under evaluation.



Implementing Actions in Controllers
-----------------------------------


First Responder and Focused Item
--------------------------------

EtoileUI has a focused item concept that represents the item receiving the editing actions from the user viewpoint. For actions using a nil target, the first responder on the other hand represents the object that internally first receives the editing actions. For each action, the first responder handles the action directly or hands it to its next responder.

The focused item is always a responder located upwards in the responder chain and a ETLayoutItem object.

Any object that conforms to ETResponder protocol is a responder and can become the first responder (if it returns YES to -[ETResponder acceptsFirstResponder] and -[ETResponder becomeFirstReponder]). Usually a responder will be an object among these types or some subtypes:

- ETLayoutItem
- ETDecoratorItem
- ETTool
- ETController
- Widget types (for the AppKit backend, this means objects such as NSWindow, NSTextField etc.)


Reacting to Focus Changes
-------------------------

Tracking focus changes using the first responder is tricky. For example, the active tool can be the first responder rather than the item to which it is attached to. To give another example, a text field when asked to become first responder hands  the first responder status to a field editor. So in a case like this, you can easily determine where the focus is by sending -focusedItem to the active tool (see -[ETTool activeTool]). 

The focused item belongs to the key responder chain, it is either identical to -keyResponderItem or among the next responders of -keyResponderItem.

Focused item changes can be detected by implementing ETEditionCoordinator protocol in a ETController subclass. Your controller will then be notified through -didBecomeFocusedItem: and -didResignFocusedItem: every time the focused item changes among the descendant items bound to its content. Focused item changes occurring elsewhere in the item tree won't result in any notifications.


