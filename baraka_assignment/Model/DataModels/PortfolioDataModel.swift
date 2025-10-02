//
//  PortfolioDataModel.swift
//  baraka_assignment
//
//  Created by Muhammad Saud Anwar on 01/10/2025.
//

import Foundation
import UIKit

// MARK: - API Data Models
struct PortfolioResponse: Decodable {
    let portfolio: Portfolio
}

// MARK: - Portfolio
struct Portfolio: Decodable {
    let balance: Balance
    let positions: [Position]
}

// MARK: - Balance
struct Balance: Decodable {
    let netValue: Double
    let pnl: Double
    let pnlPercentage: Double
}

// MARK: - Position
struct Position: Decodable {
    let instrument: Instrument
    let quantity: Double
    let averagePrice: Double
    let cost: Double
    let marketValue: Double
    let pnl: Double
    let pnlPercentage: Double
}

// MARK: - Instrument
struct Instrument: Decodable {
    let ticker: String
    let name: String
    let exchange: String
    let currency: String
    var lastTradedPrice: Double
}
/// Data structure for the Portfolio Header (Balance) UI.
struct BalanceViewModel: Hashable {
    let netValueText: String
    let pnlText: String
    let pnlPercentageText: String
    let pnlColor: UIColor // Used to indicate profit/loss (green/red)
}

/// Data structure for a single Position UI cell.
nonisolated(unsafe) struct PositionViewModel: Hashable {
    let ticker: String
    let name: String
    let quantityText: String
    let lastTradedPriceText: String
    let marketValueText: String
    let pnlText: String
    let pnlPercentageText: String
    let pnlColor: UIColor
    
    // Custom Hashable implementation to ensure Diffable DataSource updates only on real data changes.
    func hash(into hasher: inout Hasher) {
        hasher.combine(ticker)
        hasher.combine(marketValueText)
        hasher.combine(pnlText)
    }
    
    static func == (lhs: PositionViewModel, rhs: PositionViewModel) -> Bool {
        return lhs.ticker == rhs.ticker &&
               lhs.marketValueText == rhs.marketValueText &&
               lhs.pnlText == rhs.pnlText
    }
}


nonisolated(unsafe) enum Section: CaseIterable, Hashable {
    case main
}
