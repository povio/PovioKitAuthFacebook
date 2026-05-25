import Foundation
import XCTest
@testable import PovioKitAuthFacebook

final class FacebookAuthenticatorModelsTests: XCTestCase {
  func testResponseNameReturnsCombinedName() {
    var components = PersonNameComponents()
    components.givenName = "Jane"
    components.familyName = "Doe"

    let response = FacebookAuthenticator.Response(
      userId: "123",
      token: "token",
      nameComponents: components,
      email: "jane.doe@example.com",
      pictureURL: nil,
      expiresAt: Date()
    )

    XCTAssertEqual(response.name, "Jane Doe")
  }

  func testResponseNameReturnsNilWhenNameComponentsMissing() {
    let response = FacebookAuthenticator.Response(
      userId: "123",
      token: "token",
      nameComponents: nil,
      email: nil,
      pictureURL: nil,
      expiresAt: Date()
    )

    XCTAssertNil(response.name)
  }

  func testResponseNameWithOnlyGivenName() {
    var components = PersonNameComponents()
    components.givenName = "Jane"

    let response = FacebookAuthenticator.Response(
      userId: "123",
      token: "token",
      nameComponents: components,
      email: nil,
      pictureURL: nil,
      expiresAt: Date()
    )

    XCTAssertEqual(response.name, "Jane")
  }

  func testResponseNameWithOnlyFamilyName() {
    var components = PersonNameComponents()
    components.familyName = "Doe"

    let response = FacebookAuthenticator.Response(
      userId: "123",
      token: "token",
      nameComponents: components,
      email: nil,
      pictureURL: nil,
      expiresAt: Date()
    )

    XCTAssertEqual(response.name, "Doe")
  }

  func testResponseEquatableConformance() {
    let expiresAt = Date()
    let a = FacebookAuthenticator.Response(
      userId: "123",
      token: "token",
      nameComponents: nil,
      email: nil,
      pictureURL: URL(string: "https://example.com/a.png"),
      expiresAt: expiresAt
    )
    let b = FacebookAuthenticator.Response(
      userId: "123",
      token: "token",
      nameComponents: nil,
      email: nil,
      pictureURL: URL(string: "https://example.com/a.png"),
      expiresAt: expiresAt
    )
    let c = FacebookAuthenticator.Response(
      userId: "456",
      token: "token",
      nameComponents: nil,
      email: nil,
      pictureURL: nil,
      expiresAt: expiresAt
    )

    XCTAssertEqual(a, b)
    XCTAssertNotEqual(a, c)
  }

  func testResponseExposesPictureURL() {
    let url = URL(string: "https://example.com/avatar.png")
    let response = FacebookAuthenticator.Response(
      userId: "123",
      token: "token",
      nameComponents: nil,
      email: nil,
      pictureURL: url,
      expiresAt: Date()
    )

    XCTAssertEqual(response.pictureURL, url)
  }

  func testGraphResponseDecodingWithOptionalPicture() throws {
    let json = """
    {
      "id": "123",
      "email": "jane.doe@example.com",
      "first_name": "Jane",
      "last_name": "Doe",
      "picture": {
        "data": {
          "is_silhouette": false,
          "width": 100,
          "url": "https://example.com/avatar.png",
          "height": 100
        }
      }
    }
    """

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let response = try decoder.decode(FacebookAuthenticator.GraphResponse.self, from: Data(json.utf8))

    XCTAssertEqual(response.id, "123")
    XCTAssertEqual(response.email, "jane.doe@example.com")
    XCTAssertEqual(response.firstName, "Jane")
    XCTAssertEqual(response.lastName, "Doe")
    XCTAssertEqual(response.picture?.data.url, "https://example.com/avatar.png")
    XCTAssertEqual(response.picture?.data.isSilhouette, false)
    XCTAssertEqual(response.picture?.data.width, 100)
    XCTAssertEqual(response.picture?.data.height, 100)
  }

  func testGraphResponseDecodingWithOnlyRequiredFields() throws {
    let json = """
    {
      "id": "123"
    }
    """

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let response = try decoder.decode(FacebookAuthenticator.GraphResponse.self, from: Data(json.utf8))

    XCTAssertEqual(response.id, "123")
    XCTAssertNil(response.email)
    XCTAssertNil(response.firstName)
    XCTAssertNil(response.lastName)
    XCTAssertNil(response.picture)
  }

  func testGraphResponseDecodingFailsWhenIdIsMissing() {
    let json = """
    {
      "email": "jane.doe@example.com"
    }
    """

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    XCTAssertThrowsError(
      try decoder.decode(FacebookAuthenticator.GraphResponse.self, from: Data(json.utf8))
    )
  }

  func testDefaultPermissionsIncludeEmailAndPublicProfile() {
    let names = FacebookAuthenticator.defaultPermissions.map { $0.name }
    XCTAssertTrue(names.contains("email"))
    XCTAssertTrue(names.contains("public_profile"))
  }

  func testErrorLocalizedDescriptionsAreNonEmpty() {
    let cases: [FacebookAuthenticator.Error] = [
      .cancelled,
      .invalidIdentityToken,
      .invalidUserData,
      .missingUserData,
      .userDataDecode,
      .system(NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "boom"]))
    ]
    for error in cases {
      XCTAssertFalse(error.localizedDescription.isEmpty, "Expected description for \(error)")
    }
  }
}
