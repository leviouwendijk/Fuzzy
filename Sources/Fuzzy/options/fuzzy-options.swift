public struct FuzzyOptions: Sendable, Codable, Hashable {
    public struct BonusOptions: Sendable, Codable, Hashable {
        public var fieldweight: Int
        public var exacttoken: Int
        public var prefix: Int
        public var contiguous: Int
        public var subsequencebase: Int
        public var matchedchar: Int
        public var allquerytokens: Int

        public init(
            fieldweight: Int = 100,
            exacttoken: Int = 400,
            prefix: Int = 250,
            contiguous: Int = 180,
            subsequencebase: Int = 100,
            matchedchar: Int = 12,
            allquerytokens: Int = 120
        ) {
            self.fieldweight = fieldweight
            self.exacttoken = exacttoken
            self.prefix = prefix
            self.contiguous = contiguous
            self.subsequencebase = subsequencebase
            self.matchedchar = matchedchar
            self.allquerytokens = allquerytokens
        }
    }

    public struct PenaltyOptions: Sendable, Codable, Hashable {
        public var fragmentation: Int
        public var leadinggap: Int
        public var unmatchedchar: Int

        public init(
            fragmentation: Int = 20,
            leadinggap: Int = 2,
            unmatchedchar: Int = 1
        ) {
            self.fragmentation = fragmentation
            self.leadinggap = leadinggap
            self.unmatchedchar = unmatchedchar
        }
    }

    public struct ConstraintOptions: Sendable, Codable, Hashable {
        public var allquerytokens: Bool

        public init(
            allquerytokens: Bool = true
        ) {
            self.allquerytokens = allquerytokens
        }
    }

    public var bonus: BonusOptions
    public var penalty: PenaltyOptions
    public var constraints: ConstraintOptions

    public init(
        bonus: BonusOptions = .init(),
        penalty: PenaltyOptions = .init(),
        constraints: ConstraintOptions = .init()
    ) {
        self.bonus = bonus
        self.penalty = penalty
        self.constraints = constraints
    }

    public init(
        bonus_fieldweight: Int = 100,
        bonus_exacttoken: Int = 400,
        bonus_prefix: Int = 250,
        bonus_contiguous: Int = 180,
        bonus_subsequencebase: Int = 100,
        bonus_matchedchar: Int = 12,
        bonus_allquerytokens: Int = 120,
        penalty_fragmentation: Int = 20,
        penalty_leadinggap: Int = 2,
        penalty_unmatchedchar: Int = 1,
        constraints_allquerytokens: Bool = true
    ) {
        self.init(
            bonus: .init(
                fieldweight: bonus_fieldweight,
                exacttoken: bonus_exacttoken,
                prefix: bonus_prefix,
                contiguous: bonus_contiguous,
                subsequencebase: bonus_subsequencebase,
                matchedchar: bonus_matchedchar,
                allquerytokens: bonus_allquerytokens
            ),
            penalty: .init(
                fragmentation: penalty_fragmentation,
                leadinggap: penalty_leadinggap,
                unmatchedchar: penalty_unmatchedchar
            ),
            constraints: .init(
                allquerytokens: constraints_allquerytokens
            )
        )
    }

    public static let defaults: Self = .init()
}
