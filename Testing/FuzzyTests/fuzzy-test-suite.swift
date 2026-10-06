import Testing

enum FuzzyTestSuite {
    static let suite = TestSuite(
        "fuzzy",
        title: "Fuzzy tests"
    ) {
        indexEquivalenceSuite
    }
}
