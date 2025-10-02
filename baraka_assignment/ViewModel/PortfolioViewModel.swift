//
//  PortfolioViewModel.swift
//  baraka_assignment
//
//  Created by Muhammad Saud Anwar on 01/10/2025.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit

// MARK: - Portfolio View Model

class PortfolioViewModel {
    
    private let disposeBag = DisposeBag()
    private let networkService: Networking
    private let marketDataService: MarketDataProviding
        
    /// Driver for the overall balance data (header view).
    let balanceDriver: Driver<BalanceViewModel>
    
    /// Driver for the list of investment positions (collection view cells).
    let positionsDriver: Driver<[PositionViewModel]>
    
    /// Driver for showing loading/error states.
    let isLoadingDriver: Driver<Bool>

    // Private Relays (Used for internal data flow and initialization)
    private let isLoadingRelay = BehaviorRelay<Bool>(value: true)
    // Using PublishRelay to bridge the reactive chain outputs
    private let balanceRelay = PublishRelay<BalanceViewModel>()
    private let positionsRelay = PublishRelay<[PositionViewModel]>()
    
    init(networkService: Networking = NetworkService(),
         marketDataService: MarketDataProviding = MarketDataService()) {
        
        self.networkService = networkService
        self.marketDataService = marketDataService
        
        // Initialize public Drivers immediately from their corresponding Relays
        self.isLoadingDriver = isLoadingRelay.asDriver()
        self.balanceDriver = balanceRelay.asDriver(onErrorJustReturn: PortfolioViewModel.placeholderBalanceViewModel())
        self.positionsDriver = positionsRelay.asDriver(onErrorJustReturn: [])
        
        // Setup reactive chain which feeds the Relays
        let initialPortfolioObservable = networkService.fetchPortfolio()
            .do(onNext: { [weak self] _ in
                self?.isLoadingRelay.accept(false) // Stop loading on successful fetch
            }, onError: { [weak self] error in
                self?.isLoadingRelay.accept(false)
                print("Error fetching portfolio: \(error)")
            })
            .share(replay: 1, scope: .forever)
        
        let initialPositionsObservable = initialPortfolioObservable
            .map { $0.positions }
        
        // Start the MarketDataService stream with initial positions
        let livePositionsObservable = initialPositionsObservable
            .flatMapLatest { [weak self] initialPositions in
                guard let self = self else { return Observable<[Position]>.empty() }
                // This ensures the market stream only starts once data is available
                return self.marketDataService.streamLivePrices(initialPositions: initialPositions)
            }
            .share(replay: 1, scope: .forever) // Share the single live stream

        // Transform live positions into PositionViewModels (for the list)
        livePositionsObservable
            .map { (positions: [Position]) in
                // Recalculate derived metrics for EACH position
                return positions.map { self.calculatePositionViewModel(from: $0) }
            }
            .bind(to: positionsRelay) // Bind result to the new Relay
            .disposed(by: disposeBag)
        
        // Transform live positions into BalanceViewModel (for the header)
        livePositionsObservable
            .map { (positions: [Position]) in
                // Get the total cost for percentage calculation
                let totalCost = positions.reduce(0.0) { $0 + $1.cost }
                
                // Aggregate all position metrics to calculate portfolio balance metrics
                // NOTE: We MUST recalculate marketValue and pnl inside calculatePositionViewModel first.
                // For aggregation, we must use the calculated values, not the old ones from the model.
                let calculatedMetrics = positions.map { self.calculateMarketValueAndPNL(from: $0) }
                
                let totalMarketValue = calculatedMetrics.reduce(0.0) { $0 + $1.marketValue }
                let totalPNL = calculatedMetrics.reduce(0.0) { $0 + $1.pnl }
                
                // Final balance calculations as per assignment rules
                let netValue = totalMarketValue
                let pnl = totalPNL
                let pnlPercentage = totalCost > 0 ? (pnl * 100.0) / totalCost : 0.0
                
                // Create the final BalanceViewModel
                return self.calculateBalanceViewModel(netValue: netValue, pnl: pnl, pnlPercentage: pnlPercentage)
            }
            .bind(to: balanceRelay) // Bind result to the new Relay
            .disposed(by: disposeBag)
    }
    
    // MARK: - Private Calculation/Formatting Helpers
    // MARK: - Market Value + PNL Calculation
    private func calculateMarketValueAndPNL(from position: Position) -> (marketValue: Double, pnl: Double) {
        let marketValue = position.quantity * position.instrument.lastTradedPrice
        let pnl = marketValue - position.cost
        return (marketValue, pnl)
    }

    // MARK: - Position ViewModel
    private func calculatePositionViewModel(from position: Position) -> PositionViewModel {
        let metrics = calculateMarketValueAndPNL(from: position)
        let marketValue = metrics.marketValue
        let pnl = metrics.pnl
        let pnlPercentage = position.cost > 0 ? (pnl * 100.0) / position.cost : 0.0

        let isProfit = pnl >= 0
        let pnlColor: UIColor = isProfit ? .systemGreen : .systemRed

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = position.instrument.currency
        formatter.maximumFractionDigits = 2

        let marketValueText = formatter.string(from: NSNumber(value: marketValue)) ?? "\(marketValue)"
        let priceText = formatter.string(from: NSNumber(value: position.instrument.lastTradedPrice)) ?? "\(position.instrument.lastTradedPrice)"

        let pnlFormatter = NumberFormatter()
        pnlFormatter.numberStyle = .currency
        pnlFormatter.currencyCode = position.instrument.currency
        pnlFormatter.positivePrefix = "+" + (pnlFormatter.currencySymbol ?? "$")
        pnlFormatter.negativePrefix = "-" + (pnlFormatter.currencySymbol ?? "$")
        pnlFormatter.maximumFractionDigits = 2

        let percentageFormatter = NumberFormatter()
        percentageFormatter.numberStyle = .percent
        percentageFormatter.maximumFractionDigits = 2
        percentageFormatter.positivePrefix = "+"

        return PositionViewModel(
            ticker: position.instrument.ticker,
            name: position.instrument.name,
            quantityText: "Qty: \(String(format: "%.2f", position.quantity))",
            lastTradedPriceText: "Price: \(priceText)",
            marketValueText: marketValueText,
            pnlText: pnlFormatter.string(from: NSNumber(value: pnl)) ?? "\(pnl)",
            pnlPercentageText: percentageFormatter.string(from: NSNumber(value: pnlPercentage / 100.0)) ?? "\(pnlPercentage)%", pnlColor: pnlColor
        )
    }

    /// Helper function to perform the required balance formatting.
    private func calculateBalanceViewModel(netValue: Double, pnl: Double, pnlPercentage: Double) -> BalanceViewModel {
        let isProfit = pnl >= 0
        let pnlColor: UIColor = isProfit ? .systemGreen : .systemRed
        
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.currencyCode = "USD" // Assuming the entire portfolio is in USD for display
        currencyFormatter.maximumFractionDigits = 2

        let pnlFormatter = NumberFormatter()
        pnlFormatter.numberStyle = .currency
        pnlFormatter.currencyCode = "USD"
        pnlFormatter.positivePrefix = "+" + (pnlFormatter.currencySymbol ?? "$")
        pnlFormatter.negativePrefix = "-" + (pnlFormatter.currencySymbol ?? "$")
        pnlFormatter.maximumFractionDigits = 2

        let percentageFormatter = NumberFormatter()
        percentageFormatter.numberStyle = .percent
        percentageFormatter.maximumFractionDigits = 2
        percentageFormatter.positivePrefix = "+"
        
        return BalanceViewModel(
            netValueText: currencyFormatter.string(from: NSNumber(value: netValue)) ?? "\(netValue)",
            pnlText: pnlFormatter.string(from: NSNumber(value: pnl)) ?? "\(pnl)",
            pnlPercentageText: percentageFormatter.string(from: NSNumber(value: pnlPercentage / 100.0)) ?? "\(pnlPercentage)%",
            pnlColor: pnlColor
        )
    }
    
    /// Placeholder for initial or error state.
    private static func placeholderBalanceViewModel() -> BalanceViewModel {
        return BalanceViewModel(netValueText: "–", pnlText: "–", pnlPercentageText: "–", pnlColor: .label)
    }
    
    func calculatePositionColor(for pnlText: String) -> UIColor {
            // Example logic: assumes pnlText is like "+5.23%" or "-2.11%"
            if pnlText.contains("-") {
                return .systemRed
            } else if pnlText.contains("+") {
                return .systemGreen
            } else {
                return .label
            }
        }
}
