//
//  NCDBDeepLink.swift
//  NCDB
//
//  Deep link URLs, shared by the app and the widget extension.
//  Deliberately dependency-free so the widget target can use it.
//

import Foundation

enum NCDBDeepLink {

    static let scheme = "ncdb"

    /// A film's page: `ncdb://film/<uuid>`
    static func film(id: UUID) -> URL? {
        URL(string: "\(scheme)://film/\(id.uuidString)")
    }

    /// A section: `ncdb://rankings`, `ncdb://achievements`, `ncdb://stats`…
    static func section(_ name: String) -> URL? {
        URL(string: "\(scheme)://\(name)")
    }

    static var rankings: URL? { section("rankings") }
    static var achievements: URL? { section("achievements") }
    static var news: URL? { section("news") }
    static var stats: URL? { section("stats") }
    static var watchlist: URL? { section("watchlist") }
}
