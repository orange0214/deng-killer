import DengKillerCore
import SwiftUI

struct ReviewView: View {
    let claims: [ClaimAssessment]

    var body: some View {
        List {
            if claims.isEmpty {
                ContentUnavailableView("暂无会后复盘", systemImage: "checkmark.shield", description: Text("中等分主张或证据不足结果会出现在这里。"))
                    .accessibilityIdentifier("emptyReview")
            }

            ForEach(claims) { claim in
                VStack(alignment: .leading, spacing: 8) {
                    Text(claim.claim)
                        .font(.headline)
                    Text(claim.reason)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if let result = claim.result {
                        Text(result.correction)
                            .font(.subheadline)
                    }
                }
                .accessibilityIdentifier("reviewClaimCard")
            }
        }
        .navigationTitle("会后复盘")
        .accessibilityIdentifier("reviewScreen")
    }
}
