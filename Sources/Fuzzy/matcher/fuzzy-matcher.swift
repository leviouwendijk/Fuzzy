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
            return .noMatch(candidateID: candidate.matchID)
        }

        let fieldResults = candidate.allFields.compactMap { field in
            FuzzyAlgorithm.fieldResult(
                field: field,
                query: query,
                options: options
            )
        }

        guard !fieldResults.isEmpty else {
            return .noMatch(candidateID: candidate.matchID)
        }

        let totalValue = fieldResults.reduce(into: 0) { partial, fieldResult in
            partial += fieldResult.score.value
        }

        let totalComponents = fieldResults.flatMap(\.score.components)

        return MatchResult(
            candidateID: candidate.matchID,
            didMatch: true,
            score: MatchScore(
                value: totalValue,
                components: totalComponents
            ),
            fieldResults: fieldResults,
            diagnostics: []
        )
    }
}
