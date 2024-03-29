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


class MemoryCollectionViewController: NMViewController {
    
    var dataSource = MemoryCollectionViewDataSource.dataSource()
    
    lazy var collectionView: NMCollectionView = {
        let layout = getLayout()
        let view = NMCollectionView(frame: .zero, collectionViewLayout: layout)
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
        navigationItem.title = "Previous memories"
        view.addSubview(collectionView)
        setupCollectionView()
        bindViewModel()
        
        setupSearchButton()
        setupAddButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.inputs.viewWillAppear.accept(())
    }
    
    private func bindViewModel() {
        viewModel
            .outputs
            .items
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
    }
    
    // MARK: Private methods
    private func setupCollectionView() {
        
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    private func setupSearchButton() {
        let button = NMButton()
        button.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        
        navigationItem.rightBarButtonItem = .init(customView: button)
        
        button
            .rx.tap
            .bind(to: viewModel.inputs.searchButtonTap)
            .disposed(by: disposeBag)
    }
    
    private func setupAddButton() {
        let button = NMButton()
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        
        navigationItem.leftBarButtonItem = .init(customView: button)
        
        button
            .rx.tap
            .bind(to: viewModel.inputs.addButtonTap)
            .disposed(by: disposeBag)
    }
    
    fileprivate func getLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = .init(top: 7, leading: 14, bottom: 7, trailing: 14)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(120))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        
        return layout
    }
}

