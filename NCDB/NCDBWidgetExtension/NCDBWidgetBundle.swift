//
//  NCDBWidgetBundle.swift
//  NCDBWidgetExtension
//
//  Created by Claude Code on 2025-12-25.
//

import WidgetKit
import SwiftUI

@main
struct NCDBWidgetBundle: WidgetBundle {
    var body: some Widget {
        StatsWidget()
        RankingsWidget()
        UpNextWidget()
        AchievementWidget()

        // Control Centre, Lock Screen and Action Button
        LogWatchControl()
        CompletionControl()
    }
}
