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
        <img src="https://img.shields.io/badge/Licence-MIT-red.svg" />
    </a>
</p>

<p align="center">
    Welcome to <b>PovioKitAuthFacebook</b>.
    <br />An auth provider for social login with Facebook.
</p>

## Installation

### Swift Package Manager
- In Xcode, click `File` -> `Add Packages...`  
- Insert `https://github.com/poviolabs/PovioKitAuthFacebook` in the Search field.
- Select a desired `Dependency Rule`. Usually "Up to Next Major Version" with "1.0.0".
- Select "Add Package" button and check `PovioKitAuthFacebook`.
- Select "Add Package" again and you are done.

## Usage

```swift
// initialization
let authenticator = FacebookAuthenticator()

// signIn user with default permissions
let result = try await authenticator
  .signIn(from: <view-controller-instance>)

// signIn user with custom permissions  
let result = try await authenticator
  .signIn(from: <view-controller-instance>, with: [<array-of-custom-permissions>])

// get authentication status
let state = authenticator.isAuthenticated

// signOut user
authenticator.signOut() // all provider data regarding the use auth is cleared at this point

// handle url
authenticator.canOpenUrl(_: application: options:) // call this from `application:openURL:options:` in UIApplicationDelegate
```


## License

PovioKitAuth is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
