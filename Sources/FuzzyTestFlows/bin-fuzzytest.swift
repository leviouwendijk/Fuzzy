import TestFlows

@main
enum FuzzyFlowMain {
    static func main() async {
        await TestFlowCLI.run(
            suite: FuzzyFlowSuite.self
        )
    }
}
