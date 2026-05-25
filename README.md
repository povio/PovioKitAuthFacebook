<p align="center">
    <img src="Resources/PovioKit.png" width="400" max-width="90%" alt="PovioKit" />
</p>

<p align="center">
    <a href="https://swiftpackageregistry.com/poviolabs/PovioKitAuth" alt="Package">
        <img src="https://img.shields.io/badge/SPM-Swift-lightgrey.svg" />
    </a>
    <a href="https://www.swift.org" alt="Swift">
        <img src="https://img.shields.io/badge/Swift-5-orange.svg" />
    </a>
    <a href="./LICENSE" alt="License">
        <img src="https://img.shields.io/badge/License-MIT-red.svg" />
    </a>
</p>

<p align="center">
    Welcome to <b>PovioKitAuthFacebook</b>.
    <br />An auth provider for social login with Facebook.
</p>

## Requirements

- iOS 16.0+
- Swift 5.9+
- Xcode 15+
- A Facebook App ID and Client Token (configured in the [Meta for Developers](https://developers.facebook.com) console)

## Installation

### Swift Package Manager
- In Xcode, click `File` -> `Add Packages...`  
- Insert `https://github.com/poviolabs/PovioKitAuthFacebook` in the Search field.
- Select a desired `Dependency Rule`. Usually "Up to Next Major Version" with "1.0.0".
- Select "Add Package" button and check `PovioKitAuthFacebook`.
- Select "Add Package" again and you are done.

## Setup

For the full picture, read the [official Facebook documentation](https://developers.facebook.com/docs/facebook-login/ios). The minimum required steps are summarised below.

### 1. Configure `Info.plist`

Add the following keys (replace `<APP_ID>`, `<CLIENT_TOKEN>`, and `<APP_NAME>` with your values):

```xml
<key>FacebookAppID</key>
<string><APP_ID></string>
<key>FacebookClientToken</key>
<string><CLIENT_TOKEN></string>
<key>FacebookDisplayName</key>
<string><APP_NAME></string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fb<APP_ID></string>
        </array>
    </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>fbapi</string>
    <string>fb-messenger-share-api</string>
</array>
```

### 2. Initialise the Facebook SDK at launch

#### UIKit (`AppDelegate`)

```swift
import FBSDKCoreKit

func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
  ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
  return true
}
```

#### SwiftUI app lifecycle

```swift
import SwiftUI
import FBSDKCoreKit

@main
struct MyApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  
  var body: some Scene {
    WindowGroup { ContentView() }
  }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
    return true
  }
}
```

## Usage

```swift
// initialization
let authenticator = FacebookAuthenticator()

// signIn user with default permissions ([.email, .publicProfile])
let result = try await authenticator
  .signIn(from: <view-controller-instance>)

// signIn user with custom permissions
let result = try await authenticator
  .signIn(from: <view-controller-instance>, with: [.email, .userBirthday])

// build "defaults + extras" without hard-coding them
let permissions = FacebookAuthenticator.defaultPermissions + [.userFriends]
let result = try await authenticator
  .signIn(from: <view-controller-instance>, with: permissions)

// refresh the access token (and re-fetch user details)
let refreshed = try await authenticator.refreshTokenIfNeeded()

// get authentication status
let state = authenticator.isAuthenticated

// signOut user (local only — does NOT revoke server-side permissions)
authenticator.signOut()

// fully revoke permissions on Facebook's servers, then signOut locally
try await authenticator.revokePermissions()
```

> The `FacebookPermission` typealias is exposed by this package so you don't need to `import FacebookLogin` to use `.email`, `.publicProfile`, `.userBirthday`, etc.

### Handling the OAuth return URL

#### UIKit (`UIApplicationDelegate`)

```swift
func application(
  _ application: UIApplication,
  open url: URL,
  options: [UIApplication.OpenURLOptionsKey: Any] = [:]
) -> Bool {
  authenticator.canOpenUrl(url, application: application, options: options)
}
```

#### SwiftUI (`.onOpenURL`)

```swift
ContentView()
  .onOpenURL { url in
    _ = authenticator.canOpenUrl(url, application: .shared, options: [:])
  }
```

#### UIKit Scene-based apps (`UISceneDelegate`)

```swift
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
  guard let context = URLContexts.first else { return }
  _ = authenticator.canOpenUrl(
    context.url,
    application: .shared,
    options: [.sourceApplication: context.options.sourceApplication as Any]
  )
}
```

## License

PovioKitAuthFacebook is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
