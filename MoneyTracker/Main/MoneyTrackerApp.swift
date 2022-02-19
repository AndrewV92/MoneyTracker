//
//  MoneyTrackerApp.swift
//  MoneyTracker
//
//  Created by Андрей Воробьев on 14.02.2022.
//

import SwiftUI

@main
struct MoneyTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
