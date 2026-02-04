import XCTest
@testable import PositiveVoice

final class ViewModelTests: XCTestCase {

    // MARK: - PostViewModel Tests

    func testPostViewModelInitialState() {
        let viewModel = PostViewModel()

        XCTAssertEqual(viewModel.content, "")
        XCTAssertEqual(viewModel.selectedType, .goodThing)
        XCTAssertFalse(viewModel.isSubmitting)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isSubmitSuccessful)
    }

    func testPostViewModelCharactersRemaining() {
        let viewModel = PostViewModel()

        XCTAssertEqual(viewModel.charactersRemaining, 300)

        viewModel.content = "テスト"
        XCTAssertEqual(viewModel.charactersRemaining, 297)

        viewModel.content = String(repeating: "あ", count: 300)
        XCTAssertEqual(viewModel.charactersRemaining, 0)

        viewModel.content = String(repeating: "あ", count: 310)
        XCTAssertEqual(viewModel.charactersRemaining, -10)
    }

    func testPostViewModelIsValid() {
        let viewModel = PostViewModel()

        // 空の場合は無効
        XCTAssertFalse(viewModel.isValid)

        // 空白のみの場合は無効
        viewModel.content = "   "
        XCTAssertFalse(viewModel.isValid)

        // 内容がある場合は有効
        viewModel.content = "今日は良い日だった"
        XCTAssertTrue(viewModel.isValid)

        // 300文字以上の場合は無効
        viewModel.content = String(repeating: "あ", count: 301)
        XCTAssertFalse(viewModel.isValid)
    }

    func testPostViewModelResetForm() {
        let viewModel = PostViewModel()

        viewModel.content = "テスト内容"
        viewModel.selectedType = .idealWorld

        viewModel.resetForm()

        XCTAssertEqual(viewModel.content, "")
        XCTAssertEqual(viewModel.selectedType, .goodThing)
    }

    // MARK: - HomeViewModel Tests

    func testHomeViewModelInitialState() {
        let viewModel = HomeViewModel()

        XCTAssertEqual(viewModel.selectedPostType, .goodThing)
        XCTAssertEqual(viewModel.sortOrder, .newest)
    }

    func testHomeViewModelSortOrderDisplayName() {
        XCTAssertEqual(HomeViewModel.SortOrder.newest.displayName, "新着順")
        XCTAssertEqual(HomeViewModel.SortOrder.recommended.displayName, "おすすめ順")
    }

    // MARK: - SearchViewModel Tests

    func testSearchViewModelInitialState() {
        let viewModel = SearchViewModel()

        XCTAssertEqual(viewModel.searchText, "")
        XCTAssertEqual(viewModel.selectedPostType, .goodThing)
        XCTAssertNil(viewModel.selectedCategory)
        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertFalse(viewModel.isSearching)
    }

    func testSearchViewModelCategories() {
        let viewModel = SearchViewModel()

        viewModel.selectedPostType = .goodThing
        let goodCategories = viewModel.categories
        XCTAssertTrue(goodCategories.contains(.school))

        viewModel.selectedPostType = .idealWorld
        let idealCategories = viewModel.categories
        XCTAssertTrue(idealCategories.contains(.environment))
    }

    func testSearchViewModelClearCategory() {
        let viewModel = SearchViewModel()

        viewModel.selectedCategory = .school
        viewModel.searchResults = Post.mockGoodThings

        viewModel.clearCategory()

        XCTAssertNil(viewModel.selectedCategory)
        XCTAssertTrue(viewModel.searchResults.isEmpty)
    }
}
