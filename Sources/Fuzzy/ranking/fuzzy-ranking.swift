import Matching
import Ranking

enum FuzzyRanking {
    static func ranked<ID: Hashable & Sendable>(
        _ result: MatchResult<ID>,
        sourceOrder: Int
    ) -> Ranked<MatchResult<ID>> {
        Ranked(
            value: result,
            score: rankingScore(
                from: result.score
            ),
            sourceOrder: sourceOrder
        )
    }

    static func select<ID: Hashable & Sendable>(
        _ ranked: [Ranked<MatchResult<ID>>],
        options: RankingSelectionOptions
    ) -> [Ranked<MatchResult<ID>>] {
        Ranking.select(
            ranked,
            options: options,
            tieBreak: { lhs, rhs in
                tieBreak(
                    lhs,
                    rhs
                )
            }
        )
    }
}

private extension FuzzyRanking {
    static func rankingScore(
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

    static func tieBreak<ID: Hashable & Sendable>(
        _ lhs: Ranked<MatchResult<ID>>,
        _ rhs: Ranked<MatchResult<ID>>
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
