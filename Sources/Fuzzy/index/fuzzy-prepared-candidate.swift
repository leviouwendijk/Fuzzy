import Matching
import Tokens

struct FuzzyPreparedField: Sendable {
    let field: MatchField
    let tokens: [TextToken]
}

struct FuzzyPreparedCandidate<Candidate: MatchCandidate>:
    Sendable
{
    let candidate: Candidate
    let fields: [FuzzyPreparedField]
}
