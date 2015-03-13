OneSound
========

iOS app

Changelog
===
* 1.1.3
 * Fixed two songs playing at once in parties
 * Fixed entire playlist getting skipped

* 1.1.2
  * iOS 7.1 support is back 
    * The "NSClassFromString" method has a bug where it doesn't work in optimized versions of Swift, so the objective C version is now used, making iOS 7.1 work again
  * Removed all Swift and LLVM compiler optimizations
  * Messages showing party host control change now show when joining a party
  * Song interactions such as deleting and voting are disabled when the playlist is refreshing
  * Profile page looks nicer for guests; they now also have a user icon instead of only a colored rectangle
  * Fixed the app sometimes crashing when loading more users in the "Members" screen
  
* 1.01
  * Dropped iOS 7.1 support
  * Fixed the app crashing when selecting a user's color and a parties strictness
  * Profile page looks nicer for guests
    * Their color is shown instead of nothing for their user image
  * Made it clear that signing in with Facebook is needed to create a party
    * User is prompted to sign in with Facebook when creating a party, instead of just having the button disabled 
  
* 1.0
  * Initial app store release
