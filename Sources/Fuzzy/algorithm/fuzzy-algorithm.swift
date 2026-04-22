import Matching
import Ranking
import Tokens

private struct FuzzyTokenMatch {
    let score: RankingScore
    let spans: [MatchSpan]
}

private struct FuzzyIndexedTokenMatch {
    let tokenIndex: Int
    let score: RankingScore
    let spans: [MatchSpan]
}

enum FuzzyAlgorithm {
    static func fieldResult(
        field: MatchField,
        query: MatchQuery,
        options: FuzzyOptions
    ) -> MatchedFieldResult? {
        let queryTokens = query.tokens.filter {
            !$0.normalizedValue.isEmpty
        }

        guard !queryTokens.isEmpty else {
            return nil
        }

        let candidateTokens = candidateTokens(
            for: field.text,
            normalization: query.options
        )

        guard !candidateTokens.isEmpty else {
            return nil
        }

        var usedTokenIndices: Set<Int> = []
        var collectedSpans: [MatchSpan] = []
        var totalScore = RankingScore.zero
        var matchedQueryTokenCount = 0

        for queryToken in queryTokens {
            guard let bestMatch = bestTokenMatch(
                queryToken: queryToken,
                candidateTokens: candidateTokens,
                fieldName: field.name,
                case: query.options.case,
                options: options,
                usedTokenIndices: usedTokenIndices
            ) else {
                if options.constraints.allquerytokens {
                    return nil
                }

                continue
            }

            usedTokenIndices.insert(bestMatch.tokenIndex)
            totalScore = totalScore + bestMatch.score
            collectedSpans.append(contentsOf: bestMatch.spans)
            matchedQueryTokenCount += 1
        }

        guard !collectedSpans.isEmpty else {
            return nil
        }

        totalScore = totalScore.adding(
            value: field.weight * options.bonus.fieldweight,
            name: "fieldWeight",
            detail: field.name
        )

        if matchedQueryTokenCount == queryTokens.count && queryTokens.count > 1 {
            totalScore = totalScore.adding(
                value: options.bonus.allquerytokens,
                name: "allQueryTokens"
            )
        }

        return MatchedFieldResult(
            field: field,
            score: matchScore(from: totalScore),
            spans: mergedSpans(collectedSpans),
            diagnostics: []
        )
    }
}

private extension FuzzyAlgorithm {
    static func candidateTokens(
        for text: String,
        normalization: TokenNormalizationOptions
    ) -> [TextToken] {
        var tokens = IdentifierTokenizer.tokenize(
            text,
            options: .init(
                normalization: normalization,
                namespace: nil
            )
        )

        if tokens.isEmpty {
            tokens = TextTokenizer.tokenize(
                text,
                options: .init(
                    normalization: normalization,
                    emission: .init(
                        separators: false,
                        whitespace: false
                    ),
                    coalesceAdjacentSeparators: true,
                    classifyNumbers: true,
                    namespace: nil
                )
            )
        }

        if tokens.count > 1,
           let acronymToken = AcronymExtractor.token(
                from: tokens,
                namespace: nil
           ) {
            tokens.append(acronymToken)
        }

        return tokens
    }

    static func bestTokenMatch(
        queryToken: TextToken,
        candidateTokens: [TextToken],
        fieldName: String,
        case caseOptions: TokenCaseOptions,
        options: FuzzyOptions,
        usedTokenIndices: Set<Int>
    ) -> FuzzyIndexedTokenMatch? {
        var bestMatch: FuzzyIndexedTokenMatch?

        for (index, candidateToken) in candidateTokens.enumerated() {
            guard !usedTokenIndices.contains(index) else {
                continue
            }

            guard let tokenMatch = tokenMatch(
                queryToken: queryToken,
                candidateToken: candidateToken,
                fieldName: fieldName,
                case: caseOptions,
                options: options
            ) else {
                continue
            }

            let indexedMatch = FuzzyIndexedTokenMatch(
                tokenIndex: index,
                score: tokenMatch.score,
                spans: tokenMatch.spans
            )

            if isBetter(
                indexedMatch,
                than: bestMatch,
                candidateTokens: candidateTokens
            ) {
                bestMatch = indexedMatch
            }
        }

        return bestMatch
    }

    static func isBetter(
        _ candidate: FuzzyIndexedTokenMatch,
        than current: FuzzyIndexedTokenMatch?,
        candidateTokens: [TextToken]
    ) -> Bool {
        guard let current else {
            return true
        }

        if candidate.score.value != current.score.value {
            return candidate.score.value > current.score.value
        }

        let candidateToken = candidateTokens[candidate.tokenIndex]
        let currentToken = candidateTokens[current.tokenIndex]

        let candidateIsAcronym = candidateToken.kind == .acronym
        let currentIsAcronym = currentToken.kind == .acronym

        if candidateIsAcronym != currentIsAcronym {
            return !candidateIsAcronym
        }

        if candidate.spans.count != current.spans.count {
            return candidate.spans.count < current.spans.count
        }

        if candidateToken.offsetRange.startoffset != currentToken.offsetRange.startoffset {
            return candidateToken.offsetRange.startoffset < currentToken.offsetRange.startoffset
        }

        if candidateToken.offsetRange.length != currentToken.offsetRange.length {
            return candidateToken.offsetRange.length < currentToken.offsetRange.length
        }

        return candidate.tokenIndex < current.tokenIndex
    }

    static func tokenMatch(
        queryToken: TextToken,
        candidateToken: TextToken,
        fieldName: String,
        case caseOptions: TokenCaseOptions,
        options: FuzzyOptions
    ) -> FuzzyTokenMatch? {
        let queryText = switch caseOptions.sensitivity {
        case .sensitive:
            queryToken.rawValue

        case .insensitive:
            queryToken.normalizedValue
        }

        let queryCharacters = Array(queryText)
        let candidateCharacters = Array(candidateToken.rawValue)

        guard !queryCharacters.isEmpty, !candidateCharacters.isEmpty else {
            return nil
        }

        guard let matchedOffsets = subsequenceOffsets(
            query: queryCharacters,
            candidate: candidateCharacters,
            caseSensitivity: caseOptions.sensitivity
        ) else {
            return nil
        }

        let localRanges = groupedRanges(
            from: matchedOffsets
        )

        guard let firstRange = localRanges.first else {
            return nil
        }

        let isExact =
            queryCharacters.count == candidateCharacters.count
            && localRanges.count == 1
            && firstRange.startOffset == 0
            && firstRange.endOffset == candidateCharacters.count

        let isPrefix =
            localRanges.count == 1
            && firstRange.startOffset == 0
            && !isExact

        let isContiguous =
            localRanges.count == 1
            && !isExact
            && !isPrefix

        var score = RankingScore.zero

        if isExact {
            score = score.adding(
                value: options.bonus.exacttoken,
                name: "exactToken",
                detail: candidateToken.rawValue
            )
        } else if isPrefix {
            score = score.adding(
                value: options.bonus.prefix,
                name: "prefix",
                detail: candidateToken.rawValue
            )
        } else if isContiguous {
            score = score.adding(
                value: options.bonus.contiguous,
                name: "contiguous",
                detail: candidateToken.rawValue
            )
        } else {
            score = score.adding(
                value: options.bonus.subsequencebase,
                name: "subsequence",
                detail: candidateToken.rawValue
            )
        }

        score = score.adding(
            value: queryCharacters.count * options.bonus.matchedchar,
            name: "matchedCharacters"
        )

        let fragmentationPenalty =
            max(0, localRanges.count - 1) * options.penalty.fragmentation

        if fragmentationPenalty > 0 {
            score = score.adding(
                value: 0 - fragmentationPenalty,
                name: "fragmentationPenalty"
            )
        }

        let leadingPenalty =
            firstRange.startOffset * options.penalty.leadinggap

        if leadingPenalty > 0 {
            score = score.adding(
                value: 0 - leadingPenalty,
                name: "leadingGapPenalty"
            )
        }

        let unmatchedCharacters = max(
            0,
            candidateCharacters.count - queryCharacters.count
        )

        let unmatchedPenalty =
            unmatchedCharacters * options.penalty.unmatchedchar

        if unmatchedPenalty > 0 {
            score = score.adding(
                value: 0 - unmatchedPenalty,
                name: "unmatchedCharacterPenalty"
            )
        }

        let spans = localRanges.map { localRange in
            MatchSpan(
                fieldName: fieldName,
                range: MatchRange(
                    uncheckedStart: candidateToken.offsetRange.startoffset + localRange.startOffset,
                    uncheckedEnd: candidateToken.offsetRange.startoffset + localRange.endOffset
                )
            )
        }

        return FuzzyTokenMatch(
            score: score,
            spans: spans
        )
    }

    static func subsequenceOffsets(
        query: [Character],
        candidate: [Character],
        caseSensitivity: TokenCaseSensitivity
    ) -> [Int]? {
        var offsets: [Int] = []
        offsets.reserveCapacity(query.count)

        var candidateIndex = 0

        for queryCharacter in query {
            var foundIndex: Int?

            while candidateIndex < candidate.count {
                let currentIndex = candidateIndex
                let candidateCharacter = candidate[currentIndex]

                candidateIndex += 1

                if charactersEqual(
                    queryCharacter,
                    candidateCharacter,
                    caseSensitivity: caseSensitivity
                ) {
                    foundIndex = currentIndex
                    break
                }
            }

            guard let foundIndex else {
                return nil
            }

            offsets.append(foundIndex)
        }

        return offsets
    }

    static func groupedRanges(
        from offsets: [Int]
    ) -> [MatchRange] {
        guard let first = offsets.first else {
            return []
        }

        var ranges: [MatchRange] = []
        var start = first
        var previous = first

        for offset in offsets.dropFirst() {
            if offset == previous + 1 {
                previous = offset
                continue
            }

            ranges.append(
                MatchRange(
                    uncheckedStart: start,
                    uncheckedEnd: previous + 1
                )
            )

            start = offset
            previous = offset
        }

        ranges.append(
            MatchRange(
                uncheckedStart: start,
                uncheckedEnd: previous + 1
            )
        )

        return ranges
    }

    static func mergedSpans(
        _ spans: [MatchSpan]
    ) -> [MatchSpan] {
        guard !spans.isEmpty else {
            return []
        }

        let sorted = spans.sorted { lhs, rhs in
            if lhs.range.startOffset != rhs.range.startOffset {
                return lhs.range.startOffset < rhs.range.startOffset
            }

            return lhs.range.endOffset < rhs.range.endOffset
        }

        var merged: [MatchSpan] = [sorted[0]]

        for span in sorted.dropFirst() {
            let lastIndex = merged.index(before: merged.endIndex)
            let last = merged[lastIndex]

            guard last.fieldName == span.fieldName else {
                merged.append(span)
                continue
            }

            if span.range.startOffset <= last.range.endOffset {
                merged[lastIndex] = MatchSpan(
                    fieldName: last.fieldName,
                    range: MatchRange(
                        uncheckedStart: last.range.startOffset,
                        uncheckedEnd: max(
                            last.range.endOffset,
                            span.range.endOffset
                        )
                    )
                )
            } else {
                merged.append(span)
            }
        }

        return merged
    }

    static func matchScore(
        from rankingScore: RankingScore
    ) -> MatchScore {
        MatchScore(
            value: rankingScore.value,
            components: rankingScore.components.map { component in
                MatchScoreComponent(
                    name: component.name,
                    value: component.value,
                    detail: component.detail
                )
            }
        )
    }

    static func charactersEqual(
        _ lhs: Character,
        _ rhs: Character,
        caseSensitivity: TokenCaseSensitivity
    ) -> Bool {
        switch caseSensitivity {
        case .sensitive:
            return lhs == rhs

        case .insensitive:
            return String(lhs).lowercased() == String(rhs).lowercased()
        }
    }
}
