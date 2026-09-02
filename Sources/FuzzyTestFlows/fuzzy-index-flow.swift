import Fuzzy
import Matching
import Ranking
import TestFlows
import Tokens

extension FuzzyFlowSuite {
    static var indexEquivalenceFlow: TestFlow {
        TestFlow(
            "fuzzy-index-equivalence",
            tags: [
                "fuzzy",
                "index",
                "ranking",
                "regression",
            ]
        ) {
            Step(
                "prepared index matches the ranker across fuzzy query shapes"
            ) {
                let candidates = standardCandidates
                let ranker =
                    FuzzyRanker<
                        BasicMatchCandidate<String>
                    >()
                let index = FuzzyIndex(
                    candidates: candidates
                )

                for rawQuery in [
                    "terminal",
                    "term",
                    "trmnl",
                    "terminal shell",
                    "tui",
                ] {
                    let baseline = ranker.rank(
                        query: MatchQuery(
                            rawQuery
                        ),
                        candidates: candidates
                    )
                    let indexed = index.rank(
                        rawQuery
                    )

                    try Expect.equal(
                        signatures(
                            indexed
                        ),
                        signatures(
                            baseline
                        ),
                        "fuzzy.index.equivalence.\(rawQuery)"
                    )
                }
            }

            Step(
                "query normalization mismatch falls back without changing results"
            ) {
                let candidates = standardCandidates
                let ranker =
                    FuzzyRanker<
                        BasicMatchCandidate<String>
                    >()
                let index = FuzzyIndex(
                    candidates: candidates
                )
                let sensitive = TokenNormalizationOptions(
                    case: TokenCaseOptions(
                        sensitivity: .sensitive
                    )
                )
                let query = MatchQuery(
                    "Terminal",
                    options: sensitive
                )

                let baseline = ranker.rank(
                    query: query,
                    candidates: candidates
                )
                let indexed = index.rank(
                    query: query
                )

                try Expect.equal(
                    signatures(
                        indexed
                    ),
                    signatures(
                        baseline
                    ),
                    "fuzzy.index.normalization-mismatch-equivalence"
                )
                try Expect.equal(
                    indexed.map(
                        \.value.candidateID
                    ),
                    [
                        "terminal",
                    ],
                    "fuzzy.index.normalization-mismatch-exercised"
                )
            }

            Step(
                "relaxed token constraints bypass recall-unsafe character pruning"
            ) {
                let candidates = standardCandidates
                let options = FuzzyOptions(
                    constraints: .init(
                        allquerytokens: false
                    )
                )
                let ranker =
                    FuzzyRanker<
                        BasicMatchCandidate<String>
                    >(
                        options: options
                    )
                let index = FuzzyIndex(
                    candidates: candidates,
                    options: options
                )
                let query = MatchQuery(
                    "terminal zzz"
                )

                let baseline = ranker.rank(
                    query: query,
                    candidates: candidates
                )
                let indexed = index.rank(
                    query: query
                )

                try Expect.equal(
                    signatures(
                        indexed
                    ),
                    signatures(
                        baseline
                    ),
                    "fuzzy.index.relaxed-token-equivalence"
                )
                try Expect.equal(
                    indexed.map(
                        \.value.candidateID
                    ),
                    [
                        "terminal",
                    ],
                    "fuzzy.index.relaxed-token-path-exercised"
                )
            }

            Step(
                "selection limits preserve baseline source-order ties"
            ) {
                let candidates = tiedCandidates
                let selection = RankingSelectionOptions(
                    limit: 2
                )
                let ranker =
                    FuzzyRanker<
                        BasicMatchCandidate<String>
                    >(
                        selection: selection
                    )
                let index = FuzzyIndex(
                    candidates: candidates
                )
                let query = MatchQuery(
                    "alpha"
                )

                let baseline = ranker.rank(
                    query: query,
                    candidates: candidates
                )
                let indexed = index.rank(
                    query: query,
                    selection: selection
                )

                try Expect.equal(
                    signatures(
                        indexed
                    ),
                    signatures(
                        baseline
                    ),
                    "fuzzy.index.selection-equivalence"
                )
                try Expect.equal(
                    indexed.map(
                        \.value.candidateID
                    ),
                    [
                        "first",
                        "second",
                    ],
                    "fuzzy.index.source-order-limit"
                )
            }
        }
    }
}

private extension FuzzyFlowSuite {
    struct RankedSignature: Equatable {
        let candidateID: String
        let rankingScore: Int
        let matchScore: Int
        let sourceOrder: Int?
        let fields: [FieldSignature]
    }

    struct FieldSignature: Equatable {
        let name: String
        let score: Int
        let ranges: [Range<Int>]
    }

    static var standardCandidates:
        [BasicMatchCandidate<String>]
    {
        [
            candidate(
                id: "terminal",
                title: "Terminal User Interface",
                content: "terminal shell interface interactive browser"
            ),
            candidate(
                id: "search",
                title: "Search Frontier",
                content: "fuzzy candidate ranking and retrieval"
            ),
            candidate(
                id: "matching",
                title: "Matching Primitives",
                content: "token comparison and normalized query matching"
            ),
        ]
    }

    static var tiedCandidates:
        [BasicMatchCandidate<String>]
    {
        [
            candidate(
                id: "first",
                title: "alpha",
                content: ""
            ),
            candidate(
                id: "second",
                title: "alpha",
                content: ""
            ),
            candidate(
                id: "third",
                title: "alpha",
                content: ""
            ),
        ]
    }

    static func candidate(
        id: String,
        title: String,
        content: String
    ) -> BasicMatchCandidate<String> {
        BasicMatchCandidate(
            matchID: id,
            primaryField: MatchField(
                name: "title",
                text: title,
                role: .primary,
                weight: 8
            ),
            secondaryFields: [
                MatchField(
                    name: "content",
                    text: content,
                    role: .body,
                    weight: 1
                ),
            ]
        )
    }

    static func signatures(
        _ ranked:
            [
                Ranked<
                    MatchResult<String>
                >
            ]
    ) -> [RankedSignature] {
        ranked.map { rankedResult in
            RankedSignature(
                candidateID:
                    rankedResult.value.candidateID,
                rankingScore:
                    rankedResult.score.value,
                matchScore:
                    rankedResult.value.score.value,
                sourceOrder:
                    rankedResult.sourceOrder,
                fields:
                    rankedResult.value.fieldResults.map {
                        fieldResult in

                        FieldSignature(
                            name: fieldResult.field.name,
                            score: fieldResult.score.value,
                            ranges: fieldResult.spans.map {
                                $0.range.offsetRange
                            }
                        )
                    }
            )
        }
    }
}
