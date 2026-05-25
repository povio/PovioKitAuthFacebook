//
//  FacebookAuthenticator.swift
//  PovioKitAuth
//
//  Created by Borut Tomazin on 29/11/2022.
//  Copyright © 2025 Povio Inc. All rights reserved.
//

import Foundation
import UIKit
import FacebookLogin
import PovioKitAuthCore

public final class FacebookAuthenticator {
  private let provider: LoginManager
  
  public init() {
    self.provider = .init()
  }
}

// MARK: - Public Methods
extension FacebookAuthenticator: Authenticator {
  /// Signs the user in.
  ///
  /// Must be called from the main actor because it presents the Facebook login UI.
  ///
  /// - Parameters:
  ///   - presentingViewController: The view controller used to present the Facebook login UI.
  ///   - permissions: The permissions to request. Defaults to ``FacebookAuthenticator/defaultPermissions``.
  /// - Returns: A populated ``Response`` on success.
  /// - Throws: ``Error`` on cancellation, decoding failure, or any underlying SDK error.
  @MainActor
  public func signIn(
    from presentingViewController: UIViewController,
    with permissions: [FacebookPermission] = FacebookAuthenticator.defaultPermissions
  ) async throws -> Response {
    let permissionNames: [String] = permissions.map { $0.name }
    let token = try await signIn(with: permissionNames, on: presentingViewController)
    return try await fetchUserDetails(with: token)
  }
  
  /// Clears the local sign-in footprint and logs the user out immediately.
  ///
  /// - Important: This only clears the locally cached access token and profile.
  ///   It does **not** revoke the user's permissions on Facebook's servers. To do
  ///   a full server-side revocation, call ``revokePermissions()``.
  public func signOut() {
    provider.logOut()
  }
  
  /// Returns the current authentication state.
  public var isAuthenticated: Authenticated {
    guard let token = AccessToken.current else { return false }
    return !token.isExpired
  }
  
  /// Boolean if given `url` should be handled.
  ///
  /// Call this from `UIApplicationDelegate`'s `application(_:open:options:)` or
  /// from SwiftUI's `.onOpenURL`. The Facebook SDK performs its own URL-scheme
  /// check internally, so it is safe to forward any URL here.
  public func canOpenUrl(
    _ url: URL,
    application: UIApplication,
    options: [UIApplication.OpenURLOptionsKey : Any]
  ) -> Bool {
    ApplicationDelegate.shared.application(application, open: url, options: options)
  }
}

// MARK: - Additional Public API
public extension FacebookAuthenticator {
  /// Refreshes the current Facebook access token (if any) and returns updated user details.
  ///
  /// Useful for keeping long-lived sessions valid.
  ///
  /// - Throws: ``Error/invalidIdentityToken`` when there is no current access token to refresh.
  @MainActor
  func refreshTokenIfNeeded() async throws -> Response {
    guard AccessToken.current != nil else {
      throw Error.invalidIdentityToken
    }
    let refreshed = try await refreshCurrentAccessToken()
    return try await fetchUserDetails(with: refreshed)
  }
  
  /// Revokes the user's permissions on Facebook's servers and then signs the user out locally.
  ///
  /// Useful for "Disconnect Facebook" and account-deletion flows
  /// (App Store guideline 5.1.1(v) compliance).
  ///
  /// - Throws: ``Error/invalidIdentityToken`` when there is no current access token,
  ///   or ``Error/system(_:)`` if the Graph request fails.
  @MainActor
  func revokePermissions() async throws {
    guard let token = AccessToken.current else {
      throw Error.invalidIdentityToken
    }
    try await deletePermissions(with: token)
    signOut()
  }
}

// MARK: - Error
public extension FacebookAuthenticator {
  enum Error: Swift.Error, Sendable {
    case system(_ error: Swift.Error)
    case cancelled
    case invalidIdentityToken
    case invalidUserData
    case missingUserData
    case userDataDecode
  }
}

extension FacebookAuthenticator.Error: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .system(let error):
      return error.localizedDescription
    case .cancelled:
      return "Facebook sign-in was cancelled by the user."
    case .invalidIdentityToken:
      return "Facebook returned an invalid or missing access token."
    case .invalidUserData:
      return "Facebook returned user data in an unexpected shape."
    case .missingUserData:
      return "Facebook returned no user data."
    case .userDataDecode:
      return "Failed to decode user data returned by Facebook."
    }
  }
}

// MARK: - Internal Pure Helpers
//
// These helpers contain the conditional logic that would otherwise be welded
// to the FB SDK callbacks. Extracting them lets us unit-test every branch
// (success, cancelled, decode failures, picture URL parsing, etc.) without
// needing to mock `LoginManager` or `GraphRequest`.
extension FacebookAuthenticator {
  /// Maps the outcome of a Facebook login callback to either an access token
  /// (string + expiration) or an ``Error``.
  static func mapLoginResult(
    resultPresent: Bool,
    isCancelled: Bool,
    tokenString: String?,
    expirationDate: Date?,
    error: Swift.Error?
  ) -> Result<(tokenString: String, expiresAt: Date), Error> {
    switch (resultPresent, error) {
    case (true, nil):
      if isCancelled {
        return .failure(.cancelled)
      }
      if let tokenString, let expirationDate {
        return .success((tokenString, expirationDate))
      }
      return .failure(.invalidIdentityToken)
    case (false, let error?):
      return .failure(.system(error))
    default:
      return .failure(
        .system(NSError(domain: "com.povio.facebook.error", code: -1, userInfo: nil))
      )
    }
  }
  
  /// Maps the outcome of a `me` Graph request callback to a ``Response`` or an ``Error``.
  static func makeResponse(
    from payload: Any?,
    error: Swift.Error?,
    tokenString: String,
    expiresAt: Date
  ) -> Result<Response, Error> {
    if let error {
      return .failure(.system(error))
    }
    guard let payload else {
      return .failure(.missingUserData)
    }
    guard let dict = payload as? [String: Any] else {
      return .failure(.invalidUserData)
    }
    
    let object: GraphResponse
    do {
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      let data = try JSONSerialization.data(withJSONObject: dict, options: [])
      object = try decoder.decode(GraphResponse.self, from: data)
    } catch {
      return .failure(.userDataDecode)
    }
    
    guard !object.id.isEmpty else {
      return .failure(.invalidUserData)
    }
    
    var nameComponents = PersonNameComponents()
    nameComponents.givenName = object.firstName
    nameComponents.familyName = object.lastName
    
    let pictureURL: URL? = (object.picture?.data.url).flatMap(URL.init(string:))
    
    return .success(
      Response(
        userId: object.id,
        token: tokenString,
        nameComponents: nameComponents,
        email: object.email,
        pictureURL: pictureURL,
        expiresAt: expiresAt
      )
    )
  }
}

// MARK: - Private Methods
private extension FacebookAuthenticator {
  func signIn(with permissions: [String], on presentingViewController: UIViewController) async throws -> AccessToken {
    try await withCheckedThrowingContinuation { continuation in
      provider.logIn(permissions: permissions, from: presentingViewController) { result, error in
        let outcome = Self.mapLoginResult(
          resultPresent: result != nil,
          isCancelled: result?.isCancelled ?? false,
          tokenString: result?.token?.tokenString,
          expirationDate: result?.token?.expirationDate,
          error: error
        )
        switch outcome {
        case .success:
          if let token = result?.token {
            continuation.resume(returning: token)
          } else {
            continuation.resume(throwing: Error.invalidIdentityToken)
          }
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }
  }
  
  func fetchUserDetails(with token: AccessToken) async throws -> Response {
    try await withCheckedThrowingContinuation { continuation in
      let request = GraphRequest(
        graphPath: "me",
        parameters: ["fields": "id, email, first_name, last_name, picture.width(200).height(200)"],
        tokenString: token.tokenString,
        httpMethod: nil,
        flags: .doNotInvalidateTokenOnError
      )

      request.start { _, result, error in
        let outcome = Self.makeResponse(
          from: result,
          error: error,
          tokenString: token.tokenString,
          expiresAt: token.expirationDate
        )
        switch outcome {
        case .success(let response):
          continuation.resume(returning: response)
        case .failure(let error):
          continuation.resume(throwing: error)
        }
      }
    }
  }
  
  func refreshCurrentAccessToken() async throws -> AccessToken {
    try await withCheckedThrowingContinuation { continuation in
      AccessToken.refreshCurrentAccessToken { _, _, error in
        if let error {
          continuation.resume(throwing: Error.system(error))
          return
        }
        guard let token = AccessToken.current else {
          continuation.resume(throwing: Error.invalidIdentityToken)
          return
        }
        continuation.resume(returning: token)
      }
    }
  }
  
  func deletePermissions(with token: AccessToken) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Swift.Error>) in
      let request = GraphRequest(
        graphPath: "me/permissions",
        parameters: [:],
        tokenString: token.tokenString,
        httpMethod: "DELETE",
        flags: .doNotInvalidateTokenOnError
      )
      request.start { _, _, error in
        if let error {
          continuation.resume(throwing: Error.system(error))
          return
        }
        continuation.resume()
      }
    }
  }
}
