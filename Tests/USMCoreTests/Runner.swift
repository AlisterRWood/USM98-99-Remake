import Foundation
// A dependency-free test harness so verification also works with Command Line Tools.
var failures=0
func XCTAssertTrue(_ value:Bool,file:StaticString=#filePath,line:UInt=#line) { if !value { failures += 1;print("FAIL \(file):\(line): expected true") } }
func XCTAssertFalse(_ value:Bool,file:StaticString=#filePath,line:UInt=#line) { XCTAssertTrue(!value,file:file,line:line) }
func XCTAssertEqual<T:Equatable>(_ a:T,_ b:T,file:StaticString=#filePath,line:UInt=#line) { if a != b { failures += 1;print("FAIL \(file):\(line): values differ") } }
func XCTAssertNotEqual<T:Equatable>(_ a:T,_ b:T,file:StaticString=#filePath,line:UInt=#line) { XCTAssertTrue(a != b,file:file,line:line) }
func XCTAssertNil<T>(_ a:T?,file:StaticString=#filePath,line:UInt=#line) { XCTAssertTrue(a==nil,file:file,line:line) }
struct MissingValue:Error {}
func XCTUnwrap<T>(_ value:T?) throws -> T { guard let value=value else { throw MissingValue() };return value }
func XCTAssertThrowsError<T>(_ expression:@autoclosure () throws -> T,file:StaticString=#filePath,line:UInt=#line) { do { _=try expression();failures += 1;print("FAIL \(file):\(line): expected error") } catch {} }
@main struct Runner {
    static func main() {
        let t=CareerTests()
        let tests:[(String,() throws -> Void)]=[
            ("Defensive shape responds to formation and tactics",t.testDefensiveShapeRespondsToFormationAndTactics),
            ("Offside requires clear line margin",t.testOffsideRequiresClearLineMargin),
            ("Offside rate calibration",t.testOffsideRateCalibration),
            ("Goal-kick formation setup",t.testGoalKickSetupReturnsBothSidesToFormation),
            ("Configured set-piece takers",t.testConfiguredSetPieceTakersSurviveAndFallback),
            ("Scoring calibration",t.testScoringCalibration),
            ("Keeper and discipline regression",t.testKeeperAndDisciplineRegression),
            ("Negotiation reply completion without calendar",t.testNegotiationRepliesWithoutCalendar),
            ("Negotiation expiry, patience and loan exchange guards",t.testNegotiationExpiryPatienceAndBorrowedExchangeGuards),
            ("Closed negotiations clear the following week",t.testClosedNegotiationsAreClearedTheFollowingWeek),
            ("Stand tier appearance and roof changes",t.testStandAppearanceAndRoofPreviewRules),
            ("Teletext scorers and form",t.testTeletextScorersAndForm),
            ("Named formation library",t.testNamedFormationLibrary),
            ("Own player market controls",t.testOwnPlayerMarketControls),
            ("Competitor alerts, loan shares and AI market",t.testCompetitorAlertsLoanSharesAndAIMarket),
            ("Validated training assignments",t.testValidatedTrainingAssignments),
            ("Player ages, retirement and youth rollover",t.testPlayerAgesAndYouthRollover),
            ("Commentary pacing and duplicate names",t.testCommentaryPacingAndNames),
            ("Visible free kicks and corners",t.testVisibleSetPieceRestarts),
            ("Visible pace and shooting quality",t.testVisiblePaceAndShootingQuality),
            ("Fluid movement and contested corners",t.testFluidMovementAndContestedCorners),
            ("Legacy birth date recovery",t.testLegacyBirthDateRecovery),
            ("Potential and match experience",t.testPotentialAndExperience),
            ("Complete domestic cup career",t.testCompleteCupCareer),
            ("Legacy training migration and discipline",t.testLegacyTrainingMigrationAndDiscipline),
            ("Transfer clauses and finance",t.testTransferClausesAndFinance),
            ("New state validation and legacy saves",t.testNewStateSaveValidation),
            ("Cup calendar and trophies",t.testCupCalendarAndTrophies),
            ("Replay and queued substitutions",t.testReplayCardsAndQueuedChanges),
            ("Stand closure and specification",t.testStandClosureAndSpecification),
            ("Custom tactics and migration",t.testCustomTacticsAndMigration),
            ("Negotiation stages and final veto",t.testNegotiationStagesAndFinalVeto),
            ("Staff, training, scouting and commerce",t.testStaffTrainingScoutingAndCommercial),
            ("Advertising board capacity and expiry",t.testAdvertisingBoardCapacityAndExpiry),
            ("Squad swaps and selected bench",t.testSquadSwapAndBenchPersistence),
            ("Live commit barrier and tactical changes",t.testUnfinishedMatchCannotCommitAndMidMatchChangesMatter),
            ("Ground construction, movement and save",t.testGroundConstructionPlacementAndPersistence),
            ("Stand upgrades and demolition",t.testStandUpgradeAndDemolition),
            ("Live spatial match and half-time",t.testLiveMatchPossessionAndHalfTime),
            ("Goalkeeper distribution and delayed offside",t.testGoalkeeperDistributionAndDelayedOffside),
            ("Event popups pause and scale with match speed",t.testMatchPopupsPauseAndScaleWithSpeed),
            ("Fast popup batches and manual pause",t.testMatchPopupStopsFastBatchAndRespectsManualPause),
            ("Ball boundaries, restart ownership and keeper rebounds",t.testBallBoundariesAndRestartOwnership),
            ("Ball runoff, restart spot and reload",t.testBallRunoffAndRestartSpotSurviveReload),
            ("Close-range misses clear the goalmouth",t.testCloseRangeMissesClearGoalmouth),
            ("Live substitutions and tactics",t.testLiveSubstitutionsAndTactics),
            ("Advanced tactical instructions and set-piece aliases",t.testAdvancedTacticalInstructionsAndSetPieceAliases),
            ("Live save and speed parity",t.testLiveSaveResumeAndSpeedParity),
            ("Scoring roles and instant engine parity",t.testScoringRolesAndInstantEngineParity),
            ("Recovered records",t.testRecoveredDatabase),
            ("Double round robin",t.testScheduleEveryPairHomeAndAway),
            ("Odd league byes",t.testOddSizedLeagueHasByesWithoutDuplicateMatches),
            ("Injured players excluded",t.testLineupExcludesInjuredAndHasKeeper),
            ("Determinism and accounting",t.testDeterministicSimulationAndAccounting),
            ("Delayed transfer",t.testTransferIsDelayedAndConservesPlayers),
            ("Rejected transfer",t.testLowOfferRejected),
            ("Construction timeline",t.testConstructionAndLoanFreeAccounting),
            ("Save and RNG round trip",t.testSaveRoundTripPreservesRNGAndPendingOffer),
            ("Invalid save rejected",t.testInvalidSaveRejected),
            ("Full season and promotion",t.testFullSeasonAndPromotion),
            ("Tactics affect simulation",t.testTacticsInfluenceResults)
        ]
        var ran=0
        for (name,test) in tests {
            if let filter=ProcessInfo.processInfo.environment["USM_TEST_FILTER"],!name.localizedCaseInsensitiveContains(filter){continue}
            ran+=1
            let before=failures
            do { try test() } catch { failures += 1;print("FAIL \(name): \(error)") }
            print("\(failures==before ? "PASS":"FAIL") \(name)")
        }
        print("\(ran) scenarios, \(failures) failures")
        exit(failures==0 ? 0:1)
    }
}
