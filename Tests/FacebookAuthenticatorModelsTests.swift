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
      expiresAt: Date()
    )

    XCTAssertEqual(response.name, "Jane Doe")
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
  }

}
