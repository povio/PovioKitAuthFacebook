import Foundation
import XCTest
@testable import PovioKitAuthFacebook

/// Exercises every branch of the pure helpers extracted from the
/// SDK-bound `signIn` / `fetchUserDetails` flows so we get real coverage
/// of the login-callback and Graph-payload mapping logic without needing
/// to construct or mock Facebook SDK types.
final class FacebookAuthenticatorHelpersTests: XCTestCase {

  // MARK: - mapLoginResult

  func testMapLoginResultSucceedsWhenTokenIsPresent() {
    let expiry = Date(timeIntervalSince1970: 1_700_000_000)
    let outcome = FacebookAuthenticator.mapLoginResult(
      resultPresent: true,
      isCancelled: false,
      tokenString: "abc",
      expirationDate: expiry,
      error: nil
    )

    guard case .success(let (token, expiresAt)) = outcome else {
      return XCTFail("Expected success, got \(outcome)")
    }
    XCTAssertEqual(token, "abc")
    XCTAssertEqual(expiresAt, expiry)
  }

  func testMapLoginResultReturnsCancelledWhenResultIsCancelled() {
    let outcome = FacebookAuthenticator.mapLoginResult(
      resultPresent: true,
      isCancelled: true,
      tokenString: "abc",
      expirationDate: Date(),
      error: nil
    )

    if case .failure(.cancelled) = outcome { return }
    XCTFail("Expected .cancelled, got \(outcome)")
  }

  func testMapLoginResultReturnsInvalidIdentityTokenWhenTokenStringMissing() {
    let outcome = FacebookAuthenticator.mapLoginResult(
      resultPresent: true,
      isCancelled: false,
      tokenString: nil,
      expirationDate: Date(),
      error: nil
    )

    if case .failure(.invalidIdentityToken) = outcome { return }
    XCTFail("Expected .invalidIdentityToken, got \(outcome)")
  }

  func testMapLoginResultReturnsInvalidIdentityTokenWhenExpirationMissing() {
    let outcome = FacebookAuthenticator.mapLoginResult(
      resultPresent: true,
      isCancelled: false,
      tokenString: "abc",
      expirationDate: nil,
      error: nil
    )

    if case .failure(.invalidIdentityToken) = outcome { return }
    XCTFail("Expected .invalidIdentityToken, got \(outcome)")
  }

  func testMapLoginResultWrapsSDKErrorWhenResultIsAbsent() {
    let underlying = NSError(domain: "com.facebook.sdk", code: 7, userInfo: nil)
    let outcome = FacebookAuthenticator.mapLoginResult(
      resultPresent: false,
      isCancelled: false,
      tokenString: nil,
      expirationDate: nil,
      error: underlying
    )

    guard case .failure(.system(let mapped)) = outcome else {
      return XCTFail("Expected .system, got \(outcome)")
    }
    XCTAssertEqual((mapped as NSError).code, 7)
    XCTAssertEqual((mapped as NSError).domain, "com.facebook.sdk")
  }

  func testMapLoginResultFallsBackToSystemErrorWhenBothNil() {
    let outcome = FacebookAuthenticator.mapLoginResult(
      resultPresent: false,
      isCancelled: false,
      tokenString: nil,
      expirationDate: nil,
      error: nil
    )

    guard case .failure(.system(let err)) = outcome else {
      return XCTFail("Expected .system fallback, got \(outcome)")
    }
    XCTAssertEqual((err as NSError).domain, "com.povio.facebook.error")
    XCTAssertEqual((err as NSError).code, -1)
  }

  func testMapLoginResultFallsBackToSystemErrorWhenBothPresent() {
    let underlying = NSError(domain: "com.facebook.sdk", code: 8, userInfo: nil)
    let outcome = FacebookAuthenticator.mapLoginResult(
      resultPresent: true,
      isCancelled: false,
      tokenString: "abc",
      expirationDate: Date(),
      error: underlying
    )

    guard case .failure(.system(let err)) = outcome else {
      return XCTFail("Expected .system fallback, got \(outcome)")
    }
    XCTAssertEqual((err as NSError).domain, "com.povio.facebook.error")
  }

  // MARK: - makeResponse

  private let fakeToken = "fb-access-token"
  private let fakeExpiry = Date(timeIntervalSince1970: 1_800_000_000)

  func testMakeResponseWrapsErrorAsSystem() {
    let underlying = NSError(domain: "graph", code: 99)
    let outcome = FacebookAuthenticator.makeResponse(
      from: nil,
      error: underlying,
      tokenString: fakeToken,
      expiresAt: fakeExpiry
    )

    guard case .failure(.system(let mapped)) = outcome else {
      return XCTFail("Expected .system, got \(outcome)")
    }
    XCTAssertEqual((mapped as NSError).code, 99)
  }

  func testMakeResponseReturnsMissingUserDataWhenPayloadIsNil() {
    let outcome = FacebookAuthenticator.makeResponse(
      from: nil,
      error: nil,
      tokenString: fakeToken,
      expiresAt: fakeExpiry
    )

    if case .failure(.missingUserData) = outcome { return }
    XCTFail("Expected .missingUserData, got \(outcome)")
  }

  func testMakeResponseReturnsInvalidUserDataWhenPayloadIsNotDictionary() {
    let outcome = FacebookAuthenticator.makeResponse(
      from: ["unexpected", "array"],
      error: nil,
      tokenString: fakeToken,
      expiresAt: fakeExpiry
    )

    if case .failure(.invalidUserData) = outcome { return }
    XCTFail("Expected .invalidUserData, got \(outcome)")
  }

  func testMakeResponseReturnsUserDataDecodeWhenIdIsWrongType() {
    let payload: [String: Any] = ["id": 42]
    let outcome = FacebookAuthenticator.makeResponse(
      from: payload,
      error: nil,
      tokenString: fakeToken,
      expiresAt: fakeExpiry
    )

    if case .failure(.userDataDecode) = outcome { return }
    XCTFail("Expected .userDataDecode, got \(outcome)")
  }

  func testMakeResponseReturnsUserDataDecodeWhenIdIsMissing() {
    let payload: [String: Any] = ["email": "j@d.com"]
    let outcome = FacebookAuthenticator.makeResponse(
      from: payload,
      error: nil,
      tokenString: fakeToken,
      expiresAt: fakeExpiry
    )

    if case .failure(.userDataDecode) = outcome { return }
    XCTFail("Expected .userDataDecode, got \(outcome)")
  }

  func testMakeResponseReturnsInvalidUserDataWhenIdIsEmpty() {
    let payload: [String: Any] = ["id": ""]
    let outcome = FacebookAuthenticator.makeResponse(
      from: payload,
      error: nil,
      tokenString: fakeToken,
      expiresAt: fakeExpiry
    )

    if case .failure(.invalidUserData) = outcome { return }
    XCTFail("Expected .invalidUserData, got \(outcome)")
  }

  func testMakeResponseSucceedsWithFullPayload() {
    let payload: [String: Any] = [
      "id": "user-123",
      "email": "jane.doe@example.com",
      "first_name": "Jane",
      "last_name": "Doe",
      "picture": [
        "data": [
          "is_silhouette": false,
          "width": 200,
          "url": "https://example.com/avatar.png",
          "height": 200
        ]
      ]
    ]
    let outcome = FacebookAuthenticator.makeResponse(
      from: payload,
      error: nil,
      tokenString: fakeToken,
      expiresAt: fakeExpiry
    )

    guard case .success(let response) = outcome else {
      return XCTFail("Expected success, got \(outcome)")
    }
    XCTAssertEqual(response.userId, "user-123")
    XCTAssertEqual(response.token, fakeToken)
    XCTAssertEqual(response.email, "jane.doe@example.com")
    XCTAssertEqual(response.name, "Jane Doe")
    XCTAssertEqual(response.pictureURL, URL(string: "https://example.com/avatar.png"))
    XCTAssertEqual(response.expiresAt, fakeExpiry)
  }

  func testMakeResponseSucceedsWithMinimalPayloadAndNoPicture() {
    let payload: [String: Any] = ["id": "user-123"]
    let outcome = FacebookAuthenticator.makeResponse(
      from: payload,
      error: nil,
      tokenString: fakeToken,
      expiresAt: fakeExpiry
    )

    guard case .success(let response) = outcome else {
      return XCTFail("Expected success, got \(outcome)")
    }
    XCTAssertEqual(response.userId, "user-123")
    XCTAssertNil(response.email)
    XCTAssertNil(response.pictureURL)
    XCTAssertNil(response.name)
  }

  func testMakeResponseReturnsUserDataDecodeWhenPictureStructureIsWrong() {
    // The Graph API's picture wrapper is `picture.data.{url, width, ...}`.
    // Sending a string where the inner dictionary is expected makes JSON decode fail.
    let payload: [String: Any] = [
      "id": "user-123",
      "picture": [
        "data": "this should be an object, not a string"
      ]
    ]
    let outcome = FacebookAuthenticator.makeResponse(
      from: payload,
      error: nil,
      tokenString: fakeToken,
      expiresAt: fakeExpiry
    )

    if case .failure(.userDataDecode) = outcome { return }
    XCTFail("Expected .userDataDecode, got \(outcome)")
  }
}
