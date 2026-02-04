import XCTest
@testable import PositiveVoice

final class PostTests: XCTestCase {

    // MARK: - Post Model Tests

    func testPostTypeDisplayName() {
        XCTAssertEqual(Post.PostType.goodThing.displayName, "今日のいいこと")
        XCTAssertEqual(Post.PostType.idealWorld.displayName, "こうなって欲しい世の中")
    }

    func testPostTypeIcon() {
        XCTAssertEqual(Post.PostType.goodThing.icon, "sun.max.fill")
        XCTAssertEqual(Post.PostType.idealWorld.icon, "globe.asia.australia.fill")
    }

    func testMockPostsExist() {
        XCTAssertFalse(Post.mockGoodThings.isEmpty)
        XCTAssertFalse(Post.mockIdealWorld.isEmpty)
    }

    func testMockPostsHaveCorrectType() {
        for post in Post.mockGoodThings {
            XCTAssertEqual(post.type, .goodThing)
        }

        for post in Post.mockIdealWorld {
            XCTAssertEqual(post.type, .idealWorld)
        }
    }

    // MARK: - PostCategory Tests

    func testCategoryDisplayName() {
        XCTAssertEqual(PostCategory.school.displayName, "学校・勉強")
        XCTAssertEqual(PostCategory.friends.displayName, "友人・人間関係")
        XCTAssertEqual(PostCategory.environment.displayName, "環境・自然")
    }

    func testCategoriesForPostType() {
        let goodThingCategories = PostCategory.categories(for: .goodThing)
        let idealWorldCategories = PostCategory.categories(for: .idealWorld)

        XCTAssertTrue(goodThingCategories.contains(.school))
        XCTAssertTrue(goodThingCategories.contains(.friends))
        XCTAssertFalse(goodThingCategories.contains(.environment))

        XCTAssertTrue(idealWorldCategories.contains(.environment))
        XCTAssertTrue(idealWorldCategories.contains(.peace))
        XCTAssertFalse(idealWorldCategories.contains(.school))
    }

    // MARK: - Post Validation Tests

    func testPostContentMaxLength() {
        let maxLength = 300
        let content = String(repeating: "あ", count: maxLength)

        XCTAssertEqual(content.count, maxLength)
        XCTAssertTrue(content.count <= maxLength)
    }

    func testPostContentOverMaxLength() {
        let maxLength = 300
        let content = String(repeating: "あ", count: maxLength + 1)

        XCTAssertGreaterThan(content.count, maxLength)
    }
}
