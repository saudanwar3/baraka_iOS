//
//  PortfolioUIComponents.swift
//  baraka_assignment
//
//  Created by Muhammad Saud Anwar on 01/10/2025.
//

import UIKit
import RxSwift
import RxCocoa

// MARK: - Position Cell

class PortfolioCell: UICollectionViewCell {
    static let reuseIdentifier = "PortfolioCell"
    
    private let tickerLabel = UILabel()
    private let nameLabel = UILabel()
    private let quantityLabel = UILabel()
    private let priceLabel = UILabel()
    private let marketValueLabel = UILabel()
    private let pnlLabel = UILabel()
    private let pnlLabelColor = UIColor()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true

        tickerLabel.font = .systemFont(ofSize: 18, weight: .bold)
        nameLabel.font = .systemFont(ofSize: 16, weight: .regular)
        nameLabel.textColor = .secondaryLabel

        quantityLabel.font = .systemFont(ofSize: 14, weight: .regular)
        priceLabel.font = .systemFont(ofSize: 14, weight: .regular)
        priceLabel.textColor = .systemBlue

        marketValueLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        marketValueLabel.textAlignment = .right
        pnlLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        pnlLabel.textAlignment = .right
        pnlLabel.adjustsFontSizeToFitWidth = true
        pnlLabel.minimumScaleFactor = 0.5
        pnlLabel.lineBreakMode = .byTruncatingTail

        let infoStack = UIStackView(arrangedSubviews: [tickerLabel, nameLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 2
        infoStack.alignment = .leading

        let detailStack = UIStackView(arrangedSubviews: [quantityLabel, priceLabel])
        detailStack.axis = .vertical
        detailStack.spacing = 2
        detailStack.alignment = .leading

        let pnlStack = UIStackView(arrangedSubviews: [marketValueLabel, pnlLabel])
        pnlStack.axis = .vertical
        pnlStack.spacing = 2
        pnlStack.alignment = .trailing

        let leftStack = UIStackView(arrangedSubviews: [infoStack, detailStack])
        leftStack.axis = .vertical
        leftStack.spacing = 8
        leftStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

        pnlStack.setContentHuggingPriority(.required, for: .horizontal) // Ensures full label width
        pnlStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        let hStack = UIStackView(arrangedSubviews: [leftStack, pnlStack])
        hStack.axis = .horizontal
        hStack.spacing = 16
        hStack.distribution = .fill

        contentView.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    
    /// Configures the cell with the ViewModel data.
    func configure(with viewModel: PositionViewModel, pnlColor: UIColor) {
        tickerLabel.text = viewModel.ticker
        nameLabel.text = viewModel.name
        quantityLabel.text = viewModel.quantityText
        
        // The last traded price will flash as it updates due to the stream
        priceLabel.text = viewModel.lastTradedPriceText
        pnlLabel.textColor = pnlColor
        marketValueLabel.text = viewModel.marketValueText
        pnlLabel.text = "\(viewModel.pnlText) (\(viewModel.pnlPercentageText))"
        
    }
}

// MARK: - Balance Header View

class PortfolioHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "PortfolioHeaderView"
    
    private let titleLabel = UILabel()
    private let netValueLabel = UILabel()
    private let pnlLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .systemGroupedBackground
        
        titleLabel.text = "Total Portfolio Value"
        titleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        
        netValueLabel.font = .systemFont(ofSize: 40, weight: .bold)
        
        pnlLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, netValueLabel, pnlLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(16, after: netValueLabel)
        
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20)
        ])
    }
    
    /// Configures the header with the Balance ViewModel data.
    func configure(with viewModel: BalanceViewModel) {
        netValueLabel.text = viewModel.netValueText
        pnlLabel.text = "\(viewModel.pnlText) (\(viewModel.pnlPercentageText))"
        pnlLabel.textColor = viewModel.pnlColor
        
        // Simple animation to draw attention to live updates on the overall balance
        Animate.pulse(view: self, withColor: viewModel.pnlColor, duration: 0.1)
    }
}

// MARK: - Animation Utility
struct Animate {
    static func pulse(view: UIView, withColor color: UIColor, duration: Double = 0.2) {
        let originalColor = view.backgroundColor
        
        UIView.animate(withDuration: duration, animations: {
            view.backgroundColor = color.withAlphaComponent(0.1)
        }) { _ in
            UIView.animate(withDuration: duration) {
                view.backgroundColor = originalColor
            }
        }
    }
}
