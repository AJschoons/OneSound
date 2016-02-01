![onesound banner](https://cloud.githubusercontent.com/assets/7013639/12734371/09e6ac7c-c90e-11e5-8056-d2afd78a5a5a.png)

Welcome to the repository for the OneSound iOS app. OneSound is an app that lets everyone at a party or event be the DJ.<br />
Website: www.onesoundapp.com<br />
iOS: https://itunes.apple.com/us/app/onesound/id954878250<br />

How it works:<br />
When you're hosting a party, you create a Party in our app, and you and your friends join that Party. Within that Party, you add the songs you want to hear, you vote up/down on the songs your friends add, and our app creates a live, updated playlist based on what everyone wants to hear. The music plays through the Party host's device, and guests do the voting and song submission through their personal phones. 

My roles in the project include:<br />
•Implementing the complete native iOS application in Swift to interface with the OneSound API, Facebook iOS SDK, and SoundCloud API<br />
•Collaborating in the development of OneSound's iOS, Android, web, and backend implementations<br />
•Designing the logo, colors, IOS mobile user experience/interface<br />


It was developed by Phil Prescher, Ryan Casler, Tanay Salpekar, and myself. Phil did our server-side programming with primarily Sinatra in Ruby, Ryan did our Android App in Java, I developed our iOS app in Swift, and Tanay helped with all the different apps. 

OneSound launched in early 2015.

<img src="https://cloud.githubusercontent.com/assets/7013639/12734567/6e4461c2-c90f-11e5-936a-6d8e754bbb7c.jpg" width="23%"></img> <img src="https://cloud.githubusercontent.com/assets/7013639/12734569/71505f2e-c90f-11e5-953f-f4b40174713d.jpg" width="23%"></img> <img src="https://cloud.githubusercontent.com/assets/7013639/12734571/73632512-c90f-11e5-8390-c3bfbac2fc70.jpg" width="23%"></img> <img src="https://cloud.githubusercontent.com/assets/7013639/12734574/75d4f2f8-c90f-11e5-8a3f-54bfea303b8c.jpg" width="23%"></img> 

## Changelog
===
* 1.2
 * Save favorite songs
 * Add to party playlist from favorite songs
 * Parties have location
 * Searching for parties by nearest location
 * Hosts can delete any song in a party playlist
 * Party searches by name update while typing
 * Google Analytics
 * Stability improvements

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
