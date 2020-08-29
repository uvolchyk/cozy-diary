//
//  MemoryCollectionViewController.swift
//  Cozy
//
//  Created by Uladzislau Volchyk on 8/15/20.
//  Copyright © 2020 Uladzislau Volchyk. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxDataSources


// MARK: Data Source Configuration


enum MemoryCollectionViewItem {
    case CommonItem(viewModel: MemoryCollectionCommonItemViewModelType)
}

struct MemoryCollectionViewSection {
    var items: [MemoryCollectionViewItem]
}

extension MemoryCollectionViewSection: SectionModelType {
    typealias Item = MemoryCollectionViewItem
    
    init(original: Self, items: [Self.Item]) {
        self = original
    }
}

struct MemoryCollectionViewDataSource {
    typealias DataSource = RxCollectionViewSectionedReloadDataSource
    
    static func dataSource() -> DataSource<MemoryCollectionViewSection> {
        return .init(configureCell: { (dataSource, collectionView, indexPath, item) -> UICollectionViewCell in
            switch dataSource[indexPath] {
            case let .CommonItem(viewModel):
                if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MemoryCollectionViewCell.reuseIdentifier, for: indexPath) as? MemoryCollectionViewCell {
                    cell.viewModel = viewModel
                    return cell
                }
                return UICollectionViewCell()
            }
        })
    }
}


// MARK: Controller


class MemoryCollectionViewController: BaseViewController {
    
    var dataSource = MemoryCollectionViewDataSource.dataSource()
    
    lazy var collectionView: UICollectionView = {
        let layout = getLayout()
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.register(MemoryCollectionViewCell.self, forCellWithReuseIdentifier: MemoryCollectionViewCell.reuseIdentifier)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.showsHorizontalScrollIndicator = false

        return view
    }()
    
    lazy var searchController: UISearchController = {
        let item = UISearchController(searchResultsController: nil)
        item.searchBar.placeholder = "Type something here to search"
        return item
    }()
    
    let viewModel: MemoryCollectionViewModelType
    private let disposeBag = DisposeBag()
    
    init(viewModel: MemoryCollectionViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init?(coder: NSCoder) not implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.title = "Lolkek cheburek"
        view.addSubview(collectionView)
        setupCollectionView()
        bindViewModel()
        setupView()
        
        setupSearchButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.inputs.viewWillAppear.accept(())
    }
    
    // MARK: Private methods
    private func bindViewModel() {
        viewModel.outputs.items
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    private func setupView() {
        collectionView.backgroundColor = .init(red: 240/255, green: 240/255, blue: 240/255, alpha: 1.0)
    }
    
    private func setupCollectionView() {
        
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        collectionView.backgroundColor = .white
    }
    
    private func setupSearchButton() {
        let button = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"), style: .plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = button
        
        button.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.viewModel.inputs.searchRequest()
            }).disposed(by: disposeBag)
    }
    
    fileprivate func getLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .init(top: 7, leading: 14, bottom: 7, trailing: 14)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(0.3))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }
}
