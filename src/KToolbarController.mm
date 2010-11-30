#import "KToolbarController.h"

#import "KAutocompleteTextField.h"
#import "KAutocompleteTextFieldEditor.h"
#import "KLocationBarController.h"

#import "common.h"

@implementation KToolbarController

@synthesize locationBarTextField = locationBarTextField_;


// Called after the view is done loading and the outlets have been hooked up.
- (void)awakeFromNib {
  assert(locationBarController_ == nil);
  locationBarController_ = [[KLocationBarController alloc]
      initWithAutocompleteTextField:locationBarTextField_];
  // Needed so that editing doesn't lose the styling.
  [locationBarTextField_ setAllowsEditingTextAttributes:YES];
}


- (void)dealloc {
  [autocompleteTextFieldEditor_ release];
  [locationBarController_ release];
  [super dealloc];
}


#pragma mark -
#pragma mark Updating state (switching active tab)

- (void)updateURLFromCurrentContents {
  // TODO: differ between a file URL and a remote URL
  NSURL *url = currentContents_.fileURL;
  if (!url) {
    [locationBarTextField_ setStringValue:@""];
  } else if ([url isFileURL]) {
    NSString *path = [url path];
    NSString *homePath = NSHomeDirectory();
    NSRange prefixRange = NSMakeRange(0, homePath.length);
    path = [path stringByReplacingOccurrencesOfString:homePath
                                           withString:@"~"
                                              options:NSLiteralSearch
                                                range:prefixRange];
    [locationBarTextField_ setStringValue:path];
  } else {
    [locationBarTextField_ setStringValue:[url description]];
  }
}


- (void)setCurrentContents:(CTTabContents*)contents {
  static NSString * const keys[] = {@"fileURL", nil};
  if (contents == currentContents_) return;
  NSString *key;
  for (int i=0; (key = keys[i++]); ) {
    if (contents)
      [contents addObserver:self forKeyPath:key options:0 context:NULL];
    if (currentContents_)
      [currentContents_ removeObserver:self forKeyPath:key];
  }
  currentContents_ = contents;
  [self updateURLFromCurrentContents];
  [locationBarController_ contentsDidChange:contents];
}


// Updates the toolbar with the states of the specified |contents|.
// If |shouldRestore| is true, we're switching (back?) to this tab and should
// restore any previous state (such as user editing a text field) as well.
// Call is delegated from KBrowserWindowController
- (void)updateToolbarWithContents:(CTTabContents*)contents
               shouldRestoreState:(BOOL)shouldRestore {
  DLOG("updateToolbarWithContents:%@ shouldRestoreState:%@", contents,
       shouldRestore?@"YES":@"NO");
  [self setCurrentContents:contents];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context {
  DLOG(">>>>>>>> observeValueForKeyPath:%@ --> %@", keyPath, change);
  if ([keyPath isEqual:@"fileURL"]) {
    [self updateURLFromCurrentContents];
  } else if ([keyPath isEqual:@"title"]) {
    DLOG("received change of title %@", change);
  }
  // be sure to call the super implementation
  // if the superclass implements it
  /*[super observeValueForKeyPath:keyPath
                       ofObject:object
                         change:change
                        context:context];*/
}


#pragma mark -
#pragma mark Misc

- (id)customFieldEditorForObject:(id)obj {
  if (obj == locationBarTextField_) {
    // Lazilly construct Field editor, Cocoa UI code always runs on the
    // same thread, so there shoudn't be a race condition here.
    if (!autocompleteTextFieldEditor_) {
      autocompleteTextFieldEditor_ =
          [[KAutocompleteTextFieldEditor alloc] init];
    }

    // This needs to be called every time, otherwise notifications
    // aren't sent correctly.
    DCHECK(autocompleteTextFieldEditor_);
    [autocompleteTextFieldEditor_ setFieldEditor:YES];
    return autocompleteTextFieldEditor_;
  }
  return nil;
}


#pragma mark -
#pragma mark URLDropTargetController protocol impl

- (void)dropURLs:(NSArray*)urls inView:(NSView*)view at:(NSPoint)point {
  // TODO: implementation
  NOTIMPLEMENTED();
}


@end
