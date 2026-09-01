import Matching
import Ranking

public struct FuzzyRanker<Candidate: MatchCandidate>: Sendable {
    public var matcher: FuzzyMatcher<Candidate>
    public var selection: RankingSelectionOptions

    public init(
        options: FuzzyOptions = .defaults,
        selection: RankingSelectionOptions = .defaults
    ) {
        self.matcher = .init(
            options: options
        )
        self.selection = selection
    }

    public func rank<S: Sequence>(
        query: MatchQuery,
        candidates: S
    ) -> [Ranked<MatchResult<Candidate.MatchID>>]
    where S.Element == Candidate {
        let ranked: [Ranked<MatchResult<Candidate.MatchID>>] = candidates.enumerated().compactMap { element in
            let (index, candidate) = element
            let result = matcher.match(
                query: query,
                against: candidate
            )

            guard result.didMatch else {
                return nil
            }

            return FuzzyRanking.ranked(
                result,
                sourceOrder: index
            )
        }

        return FuzzyRanking.select(
            ranked,
            options: selection
        )
    }

    public func results<S: Sequence>(
        query: MatchQuery,
        candidates: S
    ) -> [MatchResult<Candidate.MatchID>]
    where S.Element == Candidate {
        rank(
            query: query,
            candidates: candidates
        )
        .map(\.value)
    }
}

