//
//  Services.swift
//  baraka_assignment
//
//  Created by Muhammad Saud Anwar on 01/10/2025.
//

import Foundation
import RxSwift

// MARK: - Network Service

protocol Networking {
    func fetchPortfolio() -> Observable<Portfolio>
}

class NetworkService: Networking {
    
    private let apiURL = URL(string: "https://dummyjson.com/c/60b7-70a6-4ee3-bae8")!
    
    func fetchPortfolio() -> Observable<Portfolio> {
        let backgroundScheduler = ConcurrentDispatchQueueScheduler(qos: .default)
        
        return Observable<Portfolio>.create { observer in
            let task = URLSession.shared.dataTask(with: self.apiURL) { data, response, error in
                
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                guard let data = data else {
                    observer.onError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                    return
                }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(PortfolioResponse.self, from: data)
                    let portfolio = decodedResponse.portfolio
                    observer.onNext(portfolio)
                    observer.onCompleted()
                } catch {
                    print("Decoding Error: \(error)")
                    observer.onError(error)
                }
            }
            
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
        .subscribe(on: backgroundScheduler)
    }
}

// MARK: - Market Data Service

protocol MarketDataProviding {
    func streamLivePrices(initialPositions: [Position]) -> Observable<[Position]>
}

class MarketDataService: MarketDataProviding {
    
    func streamLivePrices(initialPositions: [Position]) -> Observable<[Position]> {
        return Observable<Int>
            .interval(.seconds(1), scheduler: MainScheduler.instance)
            .startWith(0)
            .scan(initialPositions) { currentPositions, _ in
                return currentPositions.map { position in
                    var updatedPosition = position
                    
                    // Generate random delta
                    let delta = Double.random(in: -0.10...0.10)
                    let originalPrice = updatedPosition.instrument.lastTradedPrice
                    let newPrice = max(0.01, originalPrice * (1.0 + delta))
                    
                    // Update the instrument price
                    var updatedInstrument = updatedPosition.instrument
                    updatedInstrument.lastTradedPrice = newPrice
                    updatedPosition = Position(
                        instrument: updatedInstrument,
                        quantity: updatedPosition.quantity,
                        averagePrice: updatedPosition.averagePrice,
                        cost: updatedPosition.cost,
                        marketValue: updatedPosition.marketValue,
                        pnl: updatedPosition.pnl,
                        pnlPercentage: updatedPosition.pnlPercentage
                    )
                    
                    return updatedPosition
                }
            }
    }
}
