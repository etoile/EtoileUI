/** <title>ETNibOwner</title>

	<abstract>A mixin class to turn any class into a Nib owner that manages the 
	nib loading and releasing the nib resources once it is not in use.</abstract>

	Copyright (C) 2004-2006 M. Uli Kusterer, all rights reserved.

	Authors:  M. Uli Kusterer
	          Guenther Noack
	          Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2004
	Licenses:  GPL, Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/** You can use ETNibOwner or a subclass instance to easily load a nib, the 
instance will be set as the File's Owner proxy, and when released it will 
automatically release the Nib resources (e.g. the Nib top-level objects).

When writing an EtoileUI application, the best choice is usually to use 
[ETController] (or a subclass) to manage a Nib rather than ETNibOwner directly.

To finish the Nib loading, e.g. render the AppKit view hierarchy into a layout 
item tree, retrieve items or views, override some aspects or reorganize the 
view hierarchy or the item tree, don't override -awakeFromNib but -didLoadNib 
which will be called once every objects in the Nib has received -awakeFromNib.
When a layout item tree is built in this way, both views and windows become 
owned by the items in the resulting tree. Previously the view/window ownership 
was in relationships such as top-level objects, subviews or content views.

To render an AppKit view hierarchy packaged in a Nib into a layout item tree, 
-rebuildTopLevelObjectsWithBuilder: can be used.<br />
For example, ETController overrides -didLoadNib in a vein similar to:

<example>
- (void) didLoadNib
{
	[self rebuildTopLevelObjectsWithBuilder: [ETEtoileUIBuilder builder]];
}
</example>

For every top-level object, when -render: on the builder returns a new object, 
-rebuildTopLevelObjectsWithBuilder: substitutes the initial object with the new 
one in the top-level object array (see -topLevelObjects).<br />
When the AppKit view hierarchy to render is in the main Nib, see 
[ETApplication-rebuildMainNib]. 

On instantiation with a nil Nib name, an object which inherits from ETNibOwner 
automatically loads the Nib file which is named just like the concrete 
ETNibOwner subclass it is an instance of.<br />
For example, a direct instance of the ETNibOwner subclass "PreferencesPanel"
would try to load the Nib file named "PreferencesPanel.nib". */
@interface ETNibOwner : NSObject //<NSCopying>
{
	@private
	NSString *_nibName;
	NSBundle *_nibBundle;
	NSMutableArray *_topLevelObjects;
}

- (id) initWithNibName: (NSString *)aNibName bundle: (NSBundle *)aBundle;
- (id) init;

- (NSString *) nibName;
- (NSBundle *) nibBundle;

- (BOOL) loadNib;
- (BOOL) loadNibWithOwner: (id)anOwner;
- (void) didLoadNib;

- (NSMutableArray *) topLevelObjects;
- (NSArray *) topLevelItems;

- (void) rebuildTopLevelObjectsWithBuilder: (id)aBuilder;
- (id) rebuiltObjectForObject: (id)anObject builder: (id)aBuilder;

@end

/** ETNibOwner requires a builder that implements this protocol. For example, 
see ETEtoileUIBuilder.<br />
ETNibOwner subclasses that overrides -rebuildTopLevelObjectsWithBuilder: or 
-rebuiltObjectForObject:builder: might have other requirements.

See also ETTransform in EtoileFoundation. */
@interface NSObject (ETNibOwnerBuilder)
/** Takes an object in argument and returns a new representation or the same 
object. */
- (id) render: (id)anObject;
@end
