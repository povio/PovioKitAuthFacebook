//
//  FacebookAuthenticator+Models.swift
//  PovioKitAuth
//
//  Created by Borut Tomazin on 30/11/2022.
//  Copyright © 2025 Povio Inc. All rights reserved.
//

import Foundation
import FacebookLogin

public extension FacebookAuthenticator {
  /// A re-export of `FacebookLogin.Permission` so callers do not need to
  /// `import FacebookLogin` just to specify custom permissions.
  typealias FacebookPermission = FacebookLogin.Permission
  
  /// The permissions requested by `signIn` when the caller does not provide their own.
  ///
  /// Exposed as a public constant so consumers can build "defaults + extras"
  /// without depending on the literal default in the function signature.
  static var defaultPermissions: [FacebookPermission] { [.email, .publicProfile] }
  
  struct Response: Sendable, Equatable {
    public let userId: String
    /// Facebook access token (OAuth) string. This is **not** an ID token.
    public let token: String
    public let nameComponents: PersonNameComponents?
    public let email: String?
    public let pictureURL: URL?
    public let expiresAt: Date
    
    public init(
      userId: String,
      token: String,
      nameComponents: PersonNameComponents?,
      email: String?,
      pictureURL: URL?,
      expiresAt: Date
    ) {
      self.userId = userId
      self.token = token
      self.nameComponents = nameComponents
      self.email = email
      self.pictureURL = pictureURL
      self.expiresAt = expiresAt
    }
    
    /// User full name represented by `givenName` and `familyName`
    public var name: String? {
      nameComponents?.name
    }
  }
}

extension FacebookAuthenticator {
  struct GraphResponse: Decodable {
    let id: String
    let email: String?
    let firstName: String?
    let lastName: String?
    let picture: PictureData?

    struct PictureData: Decodable {
      let data: PictureURL
    }

    struct PictureURL: Decodable {
      let isSilhouette: Bool
      let width: Int
      let url: String
      let height: Int
    }
  }
}
