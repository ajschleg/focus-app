import XCTest
@testable import FocusSlice

/// The CLASSES.md §12 suite: synthetic Chronicle in, title out, assert.
/// `ClassEngine` is pure, so there's no simulator, no HealthKit, and no
/// clock-mocking beyond the `asOf` parameter.
final class ClassEngineTests: XCTestCase {

    private let cal = Calendar.current
    /// A fixed anchor day so tests are reproducible.
    private var day0: Date { cal.startOfDay(for: Date(timeIntervalSinceReferenceDate: 700_000_000)) }

    private func date(day: Int, hour: Int = 12) -> Date {
        let day = cal.date(byAdding: .day, value: day, to: day0)!
        return cal.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
    }

    private func daily(_ kind: ActivityKind, days: ClosedRange<Int>, hour: Int = 12, perDay: Int = 1) -> [ChronicleEntry] {
        days.flatMap { d in
            (0..<perDay).map { i in
                ChronicleEntry(kind: kind, date: date(day: d, hour: hour).addingTimeInterval(Double(i) * 600))
            }
        }
    }

    private func className(_ entries: [ChronicleEntry], day: Int, hour: Int = 20, level: Int = 3) -> String {
        ClassEngine.adoptedClass(entries: entries, asOf: date(day: day, hour: hour), levelNumber: level).focusClass.name
    }

    // MARK: - Identity paths

    func testEmptyChronicleIsWanderer() {
        let result = ClassEngine.adoptedClass(entries: [], asOf: date(day: 0), levelNumber: 1)
        XCTAssertEqual(result.verdict, .wanderer)
        XCTAssertEqual(result.focusClass.name, "Wanderer")
    }

    func testPureFocuserBecomesAsceticWithinAWeek() {
        let blocks = daily(.focusBlock, days: 0...6)
        // Too early: two days of blocks haven't woken Mind yet.
        XCTAssertEqual(className(blocks, day: 2), "Wanderer")
        // By the end of the week the epithet has landed (instantly — the
        // first class needs no hold), and it's Ascetic, not Scholar.
        XCTAssertEqual(className(blocks, day: 6), "Ascetic")
        XCTAssertEqual(ClassEngine.adoptedVerdict(entries: blocks, asOf: date(day: 6, hour: 20)),
                       .base(.mind, ascetic: true))
    }

    /// Body 3 marks/day (verified workout + a stretch) beside Mind 2/day
    /// (two blocks): a steady 0.67 ratio — hybrid territory with Body
    /// clearly dominant. Reused by the gate tests below.
    private func monkChronicle() -> [ChronicleEntry] {
        daily(.focusBlock, days: 0...13, perDay: 2)
            + daily(.questExercise, days: 0...13, hour: 18)
            + daily(.stretched, days: 0...13, hour: 19)
    }

    func testFocuserWhoTrainsIsMonk() {
        XCTAssertEqual(className(monkChronicle(), day: 13), "Monk")
    }

    func testDailyTrainingDominatesIntoWarrior() {
        // Exercise every day doubles Body past the hybrid ratio — Body wins
        // outright and the focuser is a Warrior, not a Monk.
        let entries = daily(.focusBlock, days: 0...13) + daily(.questExercise, days: 0...13, hour: 18)
        XCTAssertEqual(className(entries, day: 13), "Warrior")
    }

    func testHydratingFocuserReachesAlchemist() {
        let entries = daily(.focusBlock, days: 0...13) + daily(.questHydrate, days: 0...13, hour: 11)
        XCTAssertEqual(className(entries, day: 13), "Alchemist")
    }

    func testLateBloomerShiftsOnlyAfterCrossoverAndHold() {
        var entries = daily(.focusBlock, days: 0...40)
        entries.append(contentsOf: daily(.questExercise, days: 30...40, hour: 18))
        // Mid-shift: Body is rising but hasn't crossed + held yet.
        XCTAssertEqual(className(entries, day: 33), "Ascetic")
        // After the decay crossover plus three active days, the Monk lands.
        XCTAssertEqual(className(entries, day: 40), "Monk")
    }

    func testEpithetDissolvesIntoScholarWhenStudyArrives() {
        var entries = daily(.focusBlock, days: 0...25)
        entries.append(contentsOf: daily(.read, days: 14...25, hour: 21, perDay: 2))
        XCTAssertEqual(className(entries, day: 15), "Ascetic")
        // Reading erodes the focus share below 60%; the flip obeys the hold.
        XCTAssertEqual(className(entries, day: 25), "Scholar")
    }

    // MARK: - Gate × ladder interplay

    func testHybridCollapsesBelowJourneymanAndRestores() {
        let entries = monkChronicle()
        // Same chronicle, same verdict — only the rendering gate moves.
        XCTAssertEqual(className(entries, day: 13, level: 2), "Warrior") // dominant base
        XCTAssertEqual(className(entries, day: 13, level: 3), "Monk")
        XCTAssertEqual(className(entries, day: 13, level: 2), "Warrior") // demotion collapses again
    }

    func testLevelAloneNeverChangesTheVerdict() {
        let entries = daily(.focusBlock, days: 0...9)
        let verdicts = (1...10).map { _ in
            ClassEngine.adoptedVerdict(entries: entries, asOf: date(day: 9, hour: 20))
        }
        XCTAssertTrue(verdicts.allSatisfy { $0 == verdicts[0] })
    }

    func testEpithetNeverTouchesHybrids() {
        // Mind is 100% focus-dominated, but the awake Body makes it a Monk —
        // never "Ascetic-something".
        XCTAssertEqual(className(monkChronicle(), day: 13), "Monk")
    }

    // MARK: - Math & clock edges

    func testHalfLifeBoundariesDecayExactly() {
        // Raw interval arithmetic: calendar days can be 23/25 hours across
        // DST, and the decay clock is continuous time, not calendar days.
        let asOf = date(day: 14)
        let oneWeekOld = [ChronicleEntry(kind: .read, date: asOf.addingTimeInterval(-7 * 86_400))]
        let twoWeeksOld = [ChronicleEntry(kind: .read, date: asOf.addingTimeInterval(-14 * 86_400))]
        XCTAssertEqual(ClassEngine.contributions(entries: oneWeekOld, asOf: asOf).axes[.mind] ?? 0,
                       0.5, accuracy: 0.001)
        XCTAssertEqual(ClassEngine.contributions(entries: twoWeeksOld, asOf: asOf).axes[.mind] ?? 0,
                       0.25, accuracy: 0.001)
    }

    func testDailySoftCapHoldsAtFourMarks() {
        // Ten Body bubbles in one afternoon land at most four mark units.
        let entries = (0..<10).map {
            ChronicleEntry(kind: .stretched, date: date(day: 0, hour: 10).addingTimeInterval(Double($0) * 1800))
        }
        let body = ClassEngine.contributions(entries: entries, asOf: date(day: 0, hour: 20)).axes[.body] ?? 0
        XCTAssertLessThanOrEqual(body, 4.0)
        // The cap was reached, not undershot (4 units, minus a few hours of
        // same-day decay).
        XCTAssertGreaterThan(body, 3.7)
    }

    func testExactTiesKeepTheIncumbentDominant() {
        // Mind and Hearth perfectly tied; the incumbent decides dominance,
        // which shows at the below-gate collapse (Scholar vs Keeper).
        let entries = daily(.read, days: 0...9, hour: 9) + daily(.chores, days: 0...9, hour: 9)
        let asOf = date(day: 9, hour: 20)
        let mindFirst = ClassEngine.instantVerdict(entries: entries, asOf: asOf,
                                                   incumbent: .base(.mind, ascetic: false))
        let hearthFirst = ClassEngine.instantVerdict(entries: entries, asOf: asOf,
                                                     incumbent: .base(.hearth, ascetic: false))
        XCTAssertEqual(mindFirst, .hybrid(dominant: .mind, partner: .hearth))
        XCTAssertEqual(hearthFirst, .hybrid(dominant: .hearth, partner: .mind))
        // Both render Alchemist at the gate; dominance shows below it.
        XCTAssertEqual(ClassRoster.render(mindFirst, levelNumber: 2).name, "Scholar")
        XCTAssertEqual(ClassRoster.render(hearthFirst, levelNumber: 2).name, "Keeper")
    }

    func testWandererReentryNeedsFiveActiveDays() {
        // A Warrior fades through three weeks of silence; honesty bubbles
        // are active days with no marks, so the slide eventually completes —
        // but only after the longer Wanderer hold.
        var entries = daily(.exercised, days: 0...9)
        entries.append(contentsOf: daily(.scrolledPhone, days: 31...35, hour: 19))
        XCTAssertEqual(className(entries, day: 34), "Warrior") // four active days: still held
        XCTAssertEqual(className(entries, day: 35), "Wanderer") // the fifth completes the slide
    }

    // MARK: - Absence (the active-days clock)

    func testNineDayAbsenceHoldsTheTitle() {
        var entries = daily(.exercised, days: 0...9)
        entries.append(contentsOf: daily(.exercised, days: 19...25))
        for d in 19...25 {
            XCTAssertEqual(className(entries, day: d), "Warrior", "day \(d) should hold")
        }
    }

    func testLongAbsenceSameLifeNeverStripsTheTitle() {
        var entries = daily(.exercised, days: 0...9)
        entries.append(contentsOf: daily(.exercised, days: 100...110))
        for d in 100...110 {
            XCTAssertEqual(className(entries, day: d), "Warrior", "day \(d) should hold")
        }
    }

    func testLongAbsenceDifferentLifeShiftsOnEvidence() {
        var entries = daily(.exercised, days: 0...9)
        entries.append(contentsOf: daily(.read, days: 100...110, perDay: 2))
        // The new life takes over once Mind wakes and holds — never because
        // of the silence itself.
        XCTAssertEqual(className(entries, day: 101), "Warrior")
        XCTAssertEqual(className(entries, day: 110), "Scholar")
    }

    // MARK: - Receipts

    func testReceiptsLeadWithTheHeaviestActivity() {
        let entries = daily(.exercised, days: 0...4) + daily(.walked, days: 0...2)
        let receipts = ClassEngine.receipts(entries: entries, asOf: date(day: 4, hour: 20),
                                            verdict: .base(.body, ascetic: false))
        XCTAssertEqual(receipts.first, "exercised ×5")
        XCTAssertEqual(receipts.count, 2)
    }
}
