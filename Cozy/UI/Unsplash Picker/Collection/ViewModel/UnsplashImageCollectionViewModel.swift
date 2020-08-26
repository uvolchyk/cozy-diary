//
//  UnsplashImageCollectionViewModel.swift
//  Cozy
//
//  Created by Uladzislau Volchyk on 8/26/20.
//  Copyright © 2020 Uladzislau Volchyk. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol UnsplashImageCollectionViewModelOutput {
    var items: Driver<[UnsplashCollectionSection]> { get }
    
    var detailImageRequest: Signal<UnsplashPhoto> { get }
}

protocol UnsplashImageCollectionViewModelInput {
    var didScrollToEnd: PublishRelay<Void> { get }
}

protocol UnsplashImageCollectionViewModelType {
    var outputs: UnsplashImageCollectionViewModelOutput { get }
    var inputs: UnsplashImageCollectionViewModelInput { get }
}

class UnsplashImageCollectionViewModel: UnsplashImageCollectionViewModelType, UnsplashImageCollectionViewModelOutput, UnsplashImageCollectionViewModelInput {
    
    var outputs: UnsplashImageCollectionViewModelOutput { return self }
    var inputs: UnsplashImageCollectionViewModelInput { return self }
    
    // MARK: Outputs
    var items: Driver<[UnsplashCollectionSection]> {
        itemsPublisher.asDriver()
    }
    
    var detailImageRequest: Signal<UnsplashPhoto> {
        detailObserver.asSignal()
    }
    
    // MARK: Inputs
    let didScrollToEnd = PublishRelay<Void>()
    
    // MARK: Private
    private let pageCounter = BehaviorRelay<Int>(value: 0)
    
    private let service: UnsplashServiceType
    private let disposeBag = DisposeBag()
    private let cache: PhotoCacheType
    
    private var loadedPhotos = BehaviorRelay<[UnsplashPhoto]>(value: [])
    
    private let itemsPublisher = BehaviorRelay<[UnsplashCollectionSection]>(value: [])
    private let detailObserver = PublishRelay<UnsplashPhoto>()
    
    // MARK: Init
    init(service: UnsplashServiceType, cache: PhotoCacheType) {
        self.service = service
        self.cache = cache
        
        
        didScrollToEnd.subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            self.pageCounter.accept(self.pageCounter.value + 1)
        })
        .disposed(by: disposeBag)
        
        pageCounter.subscribe(onNext: { [weak self] (page) in
            guard let self = self else { return }
            self.loadData(page: page)
        })
        .disposed(by: disposeBag)
    }
    
    
    // MARK: Private methods
    private func loadData(page: Int) {
        service.fetch(request: .photos(page: pageCounter.value, limit: 10))
            .flatMap({ [unowned self] (unsplashPhotos) -> Observable<[UnsplashPhoto]> in
                var photos: [UnsplashPhoto] = []
                let existingPhotos = self.loadedPhotos.value
                
                if !existingPhotos.isEmpty {
                    photos.append(contentsOf: existingPhotos)
                }
                photos.append(contentsOf: unsplashPhotos)
                self.loadedPhotos.accept(photos)
                return .from([photos])
            })
            .map { $0.map { [unowned self] photo -> UnsplashImageCollectionCommonItemViewModel in
                let viewModel = UnsplashImageCollectionCommonItemViewModel(item: photo, cache: self.cache)
                viewModel.outputs.detailRequest
                    .asObservable()
                    .subscribe(onNext: { () in
                        self.detailObserver.accept(photo)
                    })
                    .disposed(by: self.disposeBag)
                return viewModel
                }}
            .map{ $0.map { viewModel -> UnsplashCollectionItem in
                .common(viewModel: viewModel)
            }}
            .flatMap({ (items) -> Observable<[UnsplashCollectionSection]> in
                .just([.init(items: items)])
            })
        .bind(to: itemsPublisher)
        .disposed(by: disposeBag)
    }
}


// MARK: Common Item


protocol UnsplashImageCollectionCommonItemViewModelOutput {
    var image: Driver<Data?> { get }
    var detailRequest: Signal<Void> { get }
}

protocol UnsplashImageCollectionCommonItemViewModelInput {
    var tapRequest: PublishRelay<Void> { get }
}

protocol UnsplashImageCollectionCommonItemViewModelType {
    var outputs: UnsplashImageCollectionCommonItemViewModelOutput { get }
    var inputs: UnsplashImageCollectionCommonItemViewModelInput { get }
}

class UnsplashImageCollectionCommonItemViewModel: UnsplashImageCollectionCommonItemViewModelType, UnsplashImageCollectionCommonItemViewModelOutput, UnsplashImageCollectionCommonItemViewModelInput {
    
    var outputs: UnsplashImageCollectionCommonItemViewModelOutput { return self }
    var inputs: UnsplashImageCollectionCommonItemViewModelInput { return self }
    
    // MARK: Outputs
    var image: Driver<Data?> {
        imageObserver.asDriver()
    }
    
    var detailRequest: Signal<Void> {
        tapRequest.asSignal()
    }
    
    // MARK: Inputs
    let tapRequest = PublishRelay<Void>()
    
    // MARK: Private
    private let item: UnsplashPhoto
    private let cache: PhotoCacheType
    private let disposeBag = DisposeBag()
    
    private let imageObserver = BehaviorRelay<Data?>(value: nil)
    
    // MARK: Init
    init(item: UnsplashPhoto, cache: PhotoCacheType) {
        self.item = item
        self.cache = cache
        
        cache.fetchPhotoFor(url: URL(string: item.urls.small)!)
            .subscribe(onNext: { [weak self] (data) in
                self?.imageObserver.accept(data)
            })
        .disposed(by: disposeBag)
    }
}