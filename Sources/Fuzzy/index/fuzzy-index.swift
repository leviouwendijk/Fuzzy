import Matching
import Ranking
import Tokens

public struct FuzzyIndex<Candidate: MatchCandidate>:
    Sendable
{
    public let normalization: TokenNormalizationOptions
    public let options: FuzzyOptions

    private let candidates: [Candidate]
    private let preparedCandidates:
        [FuzzyPreparedCandidate<Candidate>]
    private let characterPostings:
        [String: Set<Int>]

    public init<S: Sequence>(
        candidates: S,
        normalization: TokenNormalizationOptions = .defaults,
        options: FuzzyOptions = .defaults
    ) where S.Element == Candidate {
        let candidates = Array(
            candidates
        )
        let preparedCandidates = candidates.map {
            FuzzyAlgorithm.prepare(
                $0,
                normalization: normalization
            )
        }

        self.normalization = normalization
        self.options = options
        self.candidates = candidates
        self.preparedCandidates = preparedCandidates
        self.characterPostings = Self.characterPostings(
            for: preparedCandidates,
            normalization: normalization
        )
    }

    public var count: Int {
        candidates.count
    }

    public var isEmpty: Bool {
        candidates.isEmpty
    }

    public func rank(
        _ rawQuery: String,
        selection: RankingSelectionOptions = .defaults
    ) -> [
        Ranked<
            MatchResult<Candidate.MatchID>
        >
    ] {
        rank(
            query: MatchQuery(
                rawQuery,
                options: normalization
            ),
            selection: selection
        )
    }

    public func rank(
        query: MatchQuery,
        selection: RankingSelectionOptions = .defaults
    ) -> [
        Ranked<
            MatchResult<Candidate.MatchID>
        >
    ] {
        guard !query.isEmpty else {
            return []
        }

        let ranked: [
            Ranked<
                MatchResult<Candidate.MatchID>
            >
        ]

        if query.options == normalization {
            ranked = frontierIndices(
                for: query
            )
            .compactMap { index in
                let result = FuzzyAlgorithm.match(
                    query: query,
                    against: preparedCandidates[index],
                    options: options
                )

                guard result.didMatch else {
                    return nil
                }

                return FuzzyRanking.ranked(
                    result,
                    sourceOrder: index
                )
            }
        } else {
            ranked = candidates.enumerated().compactMap {
                index,
                candidate in

                let prepared = FuzzyAlgorithm.prepare(
                    candidate,
                    normalization: query.options
                )
                let result = FuzzyAlgorithm.match(
                    query: query,
                    against: prepared,
                    options: options
                )

                guard result.didMatch else {
                    return nil
                }

                return FuzzyRanking.ranked(
                    result,
                    sourceOrder: index
                )
            }
        }

        return FuzzyRanking.select(
            ranked,
            options: selection
        )
    }

    public func results(
        _ rawQuery: String,
        selection: RankingSelectionOptions = .defaults
    ) -> [MatchResult<Candidate.MatchID>] {
        rank(
            rawQuery,
            selection: selection
        )
        .map(\.value)
    }

    public func results(
        query: MatchQuery,
        selection: RankingSelectionOptions = .defaults
    ) -> [MatchResult<Candidate.MatchID>] {
        rank(
            query: query,
            selection: selection
        )
        .map(\.value)
    }
}

private extension FuzzyIndex {
    func frontierIndices(
        for query: MatchQuery
    ) -> [Int] {
        guard options.constraints.allquerytokens else {
            return Array(
                preparedCandidates.indices
            )
        }

        let keys = queryCharacterKeys(
            query
        )

        guard !keys.isEmpty else {
            return []
        }

        var frontier: Set<Int>?

        for key in keys {
            guard let postings = characterPostings[key] else {
                return []
            }

            if let current = frontier {
                let intersection = current.intersection(
                    postings
                )

                guard !intersection.isEmpty else {
                    return []
                }

                frontier = intersection
            } else {
                frontier = postings
            }
        }

        return (
            frontier
            ?? Set(
                preparedCandidates.indices
            )
        )
        .sorted()
    }

    func queryCharacterKeys(
        _ query: MatchQuery
    ) -> Set<String> {
        let sensitivity =
            query.options.case.sensitivity
        var keys = Set<String>()

        for token in query.tokens
        where !token.normalizedValue.isEmpty {
            let text: String

            switch sensitivity {
            case .sensitive:
                text = token.rawValue

            case .insensitive:
                text = token.normalizedValue
            }

            for character in text {
                keys.insert(
                    Self.characterKey(
                        character,
                        sensitivity: sensitivity
                    )
                )
            }
        }

        return keys
    }

    static func characterPostings(
        for candidates:
            [FuzzyPreparedCandidate<Candidate>],
        normalization: TokenNormalizationOptions
    ) -> [String: Set<Int>] {
        let sensitivity =
            normalization.case.sensitivity
        var postings: [String: Set<Int>] = [:]

        for (
            index,
            candidate
        ) in candidates.enumerated() {
            var candidateKeys = Set<String>()

            for field in candidate.fields {
                for token in field.tokens {
                    for character in token.rawValue {
                        candidateKeys.insert(
                            characterKey(
                                character,
                                sensitivity: sensitivity
                            )
                        )
                    }
                }
            }

            for key in candidateKeys {
                postings[
                    key,
                    default: []
                ].insert(
                    index
                )
            }
        }

        return postings
    }

    static func characterKey(
        _ character: Character,
        sensitivity: TokenCaseSensitivity
    ) -> String {
        switch sensitivity {
        case .sensitive:
            return String(
                character
            )

        case .insensitive:
            return String(
                character
            )
            .lowercased()
        }
    }
}
