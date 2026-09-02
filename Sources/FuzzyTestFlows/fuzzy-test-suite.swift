import TestFlows

enum FuzzyFlowSuite: TestFlowRegistry {
    static let title = "Fuzzy flow tests"

    static let flows: [TestFlow] = [
        indexEquivalenceFlow,
    ]
}
