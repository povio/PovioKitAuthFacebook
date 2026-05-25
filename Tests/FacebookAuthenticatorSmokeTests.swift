import Foundation
import UIKit
import XCTest
import FacebookLogin
@testable import PovioKitAuthFacebook

@MainActor
final class FacebookAuthenticatorSmokeTests: XCTestCase {
  override func tearDown() {
    AccessToken.current = nil
    super.tearDown()
  }
  
  func testIsAuthenticatedIsFalseWithoutToken() {
    AccessToken.current = nil
    let authenticator = FacebookAuthenticator()
    XCTAssertFalse(authenticator.isAuthenticated)
  }
  
  func testIsAuthenticatedIsTrueWhenCurrentTokenIsFresh() {
    AccessToken.current = makeAccessToken(expiresIn: 3600)
    let authenticator = FacebookAuthenticator()
    XCTAssertTrue(authenticator.isAuthenticated)
  }
  
  func testIsAuthenticatedIsFalseWhenCurrentTokenIsExpired() {
    AccessToken.current = makeAccessToken(expiresIn: -60)
    let authenticator = FacebookAuthenticator()
    XCTAssertFalse(authenticator.isAuthenticated)
  }

  func testSignOutDoesNotCrashWithoutSession() {
    let authenticator = FacebookAuthenticator()
    authenticator.signOut()
    XCTAssertFalse(authenticator.isAuthenticated)
  }

  func testCanOpenUrlReturnsFalseForUnrelatedScheme() {
    let authenticator = FacebookAuthenticator()
    let url = URL(string: "https://example.com/unrelated")!
    let handled = authenticator.canOpenUrl(url, application: .shared, options: [:])
    XCTAssertFalse(handled)
  }

  func testRefreshTokenIfNeededThrowsInvalidIdentityTokenWithoutSession() async {
    let authenticator = FacebookAuthenticator()
    authenticator.signOut()

    do {
      _ = try await authenticator.refreshTokenIfNeeded()
      XCTFail("Expected refreshTokenIfNeeded to throw without a current token")
    } catch let error as FacebookAuthenticator.Error {
      guard case .invalidIdentityToken = error else {
        return XCTFail("Expected .invalidIdentityToken, got \(error)")
      }
    } catch {
      XCTFail("Expected FacebookAuthenticator.Error, got \(error)")
    }
  }

  func testRevokePermissionsThrowsInvalidIdentityTokenWithoutSession() async {
    let authenticator = FacebookAuthenticator()
    authenticator.signOut()

    do {
      try await authenticator.revokePermissions()
      XCTFail("Expected revokePermissions to throw without a current token")
    } catch let error as FacebookAuthenticator.Error {
      guard case .invalidIdentityToken = error else {
        return XCTFail("Expected .invalidIdentityToken, got \(error)")
      }
    } catch {
      XCTFail("Expected FacebookAuthenticator.Error, got \(error)")
    }
  }
  
  private func makeAccessToken(expiresIn seconds: TimeInterval) -> AccessToken {
    AccessToken(
      tokenString: "test-token",
      permissions: ["email", "public_profile"],
      declinedPermissions: [],
      expiredPermissions: [],
      appID: "0",
      userID: "test-user",
      expirationDate: Date(timeIntervalSinceNow: seconds),
      refreshDate: Date(),
      dataAccessExpirationDate: Date(timeIntervalSinceNow: max(seconds, 3600))
    )
  }
}
