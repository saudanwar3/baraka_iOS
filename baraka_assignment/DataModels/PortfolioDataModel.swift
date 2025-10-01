//
//  PortfolioDataModel.swift
//  baraka_assignment
//
//  Created by Muhammad Saud Anwar on 01/10/2025.
//

import Foundation

// MARK: - API Data Models

/// Represents the overall portfolio data structure returned by the API.
struct Portfolio: Decodable {
    let balance: Balance
    let positions: [Position]
}

/// Represents the calculated metrics for the entire portfolio.
struct Balance: Decodable {
    // Note: netValue, pnl, and pnlPercentage are initialized to 0.0 in the API response,
    // but the final calculation is performed reactively in the ViewModel based on positions.
    let netValue: Double
    let pnl: Double
    let pnlPercentage: Double
    
    // Custom initializers for the calculation
    init(netValue: Double, pnl: Double, pnlPercentage: Double) {
        self.netValue = netValue
        self.pnl = pnl
        self.pnlPercentage = pnlPercentage
    }
}

/// Data model that represents a single investment position.
struct Position: Decodable {
    let ticker: String
    let name: String
    let exchange: String
    let currency: String
    // This value is live-updated by MarketDataService
    var lastTradedPrice: Double
    let quantity: Double
    let averagePrice: Double
    let cost: Double
    
    // These values are derived and recalculated reactively
    var marketValue: Double
    var pnl: Double
    var pnlPercentage: Double

    // Custom initializer for calculation
    init(ticker: String, name: String, exchange: String, currency: String, lastTradedPrice: Double, quantity: Double, averagePrice: Double, cost: Double, marketValue: Double, pnl: Double, pnlPercentage: Double) {
        self.ticker = ticker
        self.name = name
        self.exchange = exchange
        self.currency = currency
        self.lastTradedPrice = lastTradedPrice
        self.quantity = quantity
        self.averagePrice = averagePrice
        self.cost = cost
        self.marketValue = marketValue
        self.pnl = pnl
        self.pnlPercentage = pnlPercentage
    }
}
