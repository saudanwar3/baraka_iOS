//
//  PortfolioViewController.swift
//  baraka_assignment
//
//  Created by Muhammad Saud Anwar on 01/10/2025.
//

import UIKit
import RxSwift
import RxCocoa

class PortfolioViewController: UIViewController {
    
    // MARK: Properties
    private let viewModel = PortfolioViewModel()
    private let disposeBag = DisposeBag()
    
    private var collectionView: UICollectionView!
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, PositionViewModel>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, PositionViewModel>
    
    private var dataSource: DataSource!
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupNavigationBar()
        configureCollectionView()
        configureDataSource()
        bindViewModel()
    }
    
    // MARK: Setup
    
    private func setupNavigationBar() {
        navigationItem.title = "My Portfolio"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    /// Sets up the UICollectionView with programmatic constraints and the Compositional Layout.
    private func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemGroupedBackground
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        collectionView.register(PortfolioCell.self, forCellWithReuseIdentifier: PortfolioCell.reuseIdentifier)
        collectionView.register(
            PortfolioHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: PortfolioHeaderView.reuseIdentifier
        )
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(100))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10 // Space between cells
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 20, trailing: 16)
        
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(120))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        section.boundarySupplementaryItems = [header]
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    private func configureDataSource() {
        // Cell Provider
        dataSource = DataSource(collectionView: collectionView) { [weak self] (collectionView, indexPath, position) -> UICollectionViewCell? in
            guard let self = self,
                  let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PortfolioCell.reuseIdentifier, for: indexPath) as? PortfolioCell else {
                return UICollectionViewCell()
            }
            
            let pnlColor = self.viewModel.calculatePositionColor(for: position.pnlText)
            cell.configure(with: position, pnlColor: pnlColor)
            return cell
        }
        
        // Supplementary View Provider (Header)
        dataSource.supplementaryViewProvider = { [weak self] (collectionView, kind, indexPath) -> UICollectionReusableView? in
            guard kind == UICollectionView.elementKindSectionHeader,
                  let self = self,
                  let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PortfolioHeaderView.reuseIdentifier, for: indexPath) as? PortfolioHeaderView else {
                return nil
            }
            
            // Manually bind the Balance Driver to the Header View lifecycle
            self.viewModel.balanceDriver
                .drive(onNext: { balanceViewModel in
                    header.configure(with: balanceViewModel)
                })
                .disposed(by: self.disposeBag)
            
            return header
        }
        
        // Apply initial snapshot
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    // MARK: Binding
    
    private func bindViewModel() {
        // Bind Positions (main data source updates)
        viewModel.positionsDriver
            .drive(onNext: { [weak self] positions in
                guard let self = self else { return }
                var snapshot = Snapshot()
                snapshot.appendSections([.main])
                snapshot.appendItems(positions, toSection: .main)
                // Use animatingDifferences: true for smooth visual updates from live data
                self.dataSource.apply(snapshot, animatingDifferences: true)
            })
            .disposed(by: disposeBag)
        
        // Bind Loading State (Basic indicator)
        viewModel.isLoadingDriver
            .drive(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.showLoadingIndicator()
                } else {
                    self?.hideLoadingIndicator()
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: UI Helpers (Loading)
    
    private func showLoadingIndicator() {
        // Simple activity indicator for initial loading
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.tag = 99 
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        if let indicator = view.viewWithTag(99) as? UIActivityIndicatorView {
            indicator.stopAnimating()
            indicator.removeFromSuperview()
        }
    }
}
