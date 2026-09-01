import Matching

public struct FuzzyMatcher<Candidate: MatchCandidate>: Matcher {
    public let strategy: MatchStrategy = .fuzzy
    public var options: FuzzyOptions

    public init(
        options: FuzzyOptions = .defaults
    ) {
        self.options = options
    }

    public func match(
        query: MatchQuery,
        against candidate: Candidate
    ) -> MatchResult<Candidate.MatchID> {
        guard !query.isEmpty else {
            return .noMatch(
                candidateID: candidate.matchID
            )
        }

        return FuzzyAlgorithm.match(
            query: query,
            against: FuzzyAlgorithm.prepare(
                candidate,
                normalization: query.options
            ),
            options: options
        )
    }
}
