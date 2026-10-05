import Foundation

struct WorthWatchingAssessment: Equatable {
    let percentage: Int?
    let headline: String
    let detail: String
    let isAvailable: Bool
}

enum WorthWatchingCalculator {
    /// Turns a published 0–10 audience average into a 0–100 display.
    /// The percentage is the audience average itself, not a separate critic score.
    /// Low vote counts suppress the score instead of inventing one.
    static func assess(average: Double, voteCount: Int) -> WorthWatchingAssessment {
        guard average > 0, voteCount >= 40 else {
            return WorthWatchingAssessment(
                percentage: nil,
                headline: "Not enough ratings",
                detail: "A score appears only after enough audience votes are published. Lumen does not estimate a rating beyond that.",
                isAvailable: false
            )
        }

        let percentage = Int((average * 10).rounded())
        let clamped = min(100, max(0, percentage))
        let votes = Formatters.count(voteCount)

        let detail = "Based on audience rating of \(Formatters.rating(average))/10 from \(votes) ratings."

        return WorthWatchingAssessment(
            percentage: clamped,
            headline: "Worth Watching",
            detail: detail,
            isAvailable: true
        )
    }
}
