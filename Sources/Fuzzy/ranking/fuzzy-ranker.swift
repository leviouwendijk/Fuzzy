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

            return Ranked(
                value: result,
                score: rankingScore(
                    from: result.score
                ),
                sourceOrder: index
            )
        }

        return Ranking.select(
            ranked,
            options: selection,
            tieBreak: { lhs, rhs in
                tieBreak(
                    lhs,
                    rhs
                )
            }
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

private extension FuzzyRanker {
    func rankingScore(
        from matchScore: MatchScore
    ) -> RankingScore {
        RankingScore(
            value: matchScore.value,
            components: matchScore.components.map { component in
                RankingScoreComponent(
                    name: component.name,
                    value: component.value,
                    detail: component.detail
                )
            }
        )
    }

    func tieBreak(
        _ lhs: Ranked<MatchResult<Candidate.MatchID>>,
        _ rhs: Ranked<MatchResult<Candidate.MatchID>>
    ) -> Bool {
        let lhsPrimary = lhs.value.fieldResults.contains {
            $0.field.role == .primary
        }

        let rhsPrimary = rhs.value.fieldResults.contains {
            $0.field.role == .primary
        }

        if lhsPrimary != rhsPrimary {
            return lhsPrimary
        }

        return false
    }
}
