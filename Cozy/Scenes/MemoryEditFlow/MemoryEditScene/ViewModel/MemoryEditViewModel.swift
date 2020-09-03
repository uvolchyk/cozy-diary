//
//  MemoryEditViewModel.swift
//  Cozy
//
//  Created by Uladzislau Volchyk on 8/28/20.
//  Copyright © 2020 Uladzislau Volchyk. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa




class MemoryEditViewModel: MemoryCreateViewModelType, MemoryCreateViewModelOutput, MemoryCreateViewModelInput {
    
    // MARK: Outputs & Inputs
    var outputs: MemoryCreateViewModelOutput { return self }
    var inputs: MemoryCreateViewModelInput { return self }
    
    // MARK: Outputs
    let items = BehaviorRelay<[MemoryCreateCollectionItem]>(value: [])
    
    lazy var title: Driver<String> = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let result = dateFormatter.string(from: memory.value.date)
        return Observable.just(result).asDriver(onErrorJustReturn: "")
    }()
    
    var photoInsertRequestObservable: Observable<Void> { photoChunkAdd.asObservable() }
    var photoDetailRequestObservable: Observable<Data> { photoDetailObserver.asObservable() }
    var photoShareRequestObservable: Observable<Data> { photoShareObserver.asObservable() }
    
    var tagAddRequestObservable: Observable<Memory> {
        tagAdd.flatMap({ [unowned self] (_) -> Observable<Memory> in
            .just(self.memory.value)
        })
    }
    
    var graffitiInsertRequestObservable: Observable<Void> { graffitiChunkAdd.asObservable() }
    
    var shouldClearStack: Observable<Void> { shouldClearStackObserver.asObservable() }
    
    // MARK: Inputs
    let viewWillAppear = PublishRelay<Void>()
    let viewWillDisappear = PublishRelay<Void>()
    
    let textChunkAdd = PublishRelay<Void>()
    let photoChunkAdd = PublishRelay<Void>()
    let graffitiChunkAdd = PublishRelay<Void>()
    let tagAdd = PublishRelay<Void>()
    
    lazy var photoInsertResponse: (ImageMeta) -> () = {
        { meta in
            if let image = meta.originalImage {
                let value = self.memory.value
                value.insertPhoto(image)
                self.memory.accept(value)
            }
        }
    }()
    
    lazy var graffitiInsertResponse: (Data) -> () = {
        { graffiti in
            let value = self.memory.value
            value.insertGraffiti(graffiti)
            self.memory.accept(value)
        }
    }()
    
    // MARK: Private
    private let photoInsertObserver = PublishSubject<Void>()
    private let photoDetailObserver = PublishSubject<Data>()
    private let photoShareObserver = PublishSubject<Data>()
    private let tagAddObserver = PublishSubject<Memory>()
    private let graffitiInsertObserver = PublishSubject<Void>()
    
    private let shouldClearStackObserver = PublishRelay<Void>()
    
    private let memory: BehaviorRelay<Memory>
    private let memoryStore: MemoryStoreType
    
    private let disposeBag = DisposeBag()
    
    // MARK: Init
    init(memory: BehaviorRelay<Memory>, memoryStore: MemoryStoreType) {
        self.memory = memory
        self.memoryStore = memoryStore
        
        bindMemory()
        setupTextChunkAdd()
        
        viewWillAppear.subscribe(onNext: { [weak self] (_) in
            self?.memoryStore.seekFor(memory, key: memory.value.date)
            self?.shouldClearStackObserver.accept(())
        })
        .disposed(by: disposeBag)
        
        viewWillDisappear
            .map { [unowned self] _ -> Date in
                self.memory.value.date
            }
            .subscribe(onNext: { [weak self] (date) in
                self?.memoryStore.leaveAway(key: date)
            })
            .disposed(by: disposeBag)
        
    }
    
    // MARK: Private methods
    private func bindMemory() {
        memory.subscribe(onNext: { [unowned self] memory in
            self.items.accept(
                memory.sortedChunks.map { chunk -> MemoryCreateCollectionItem in

                    if let textChunk = chunk as? TextChunk {
                        return self.textChunkItem(textChunk)
                    } else if let graffitiChunk = chunk as? GraffitiChunk {
                        return self.graffitiCHunkItem(graffitiChunk)
                    } else {
                        let photoChunk = chunk as! PhotoChunk
                        return self.photoChunkItem(photoChunk)
                    }
                }
            )
        }).disposed(by: disposeBag)
    }
    
    private func setupTextChunkAdd() {
        textChunkAdd.subscribe(onNext: { [weak self] (_) in
            guard let self = self else { return }
            let value = self.memory.value
            if (value.sortedChunks.last as? TextChunkable) == nil {
                value.insertTextChunk("")
                self.memory.accept(value)
            }
        })
        .disposed(by: disposeBag)
    }

    private func textChunkItem(_ textChunk: TextChunk) -> MemoryCreateCollectionItem {
        let viewModel = TextChunkViewModel(textChunk)
        viewModel.outputs.removeTextRequest
            .subscribe(onNext: { [weak self] in
                if let value = self?.memory.value {
                    value.removeChunk(textChunk)
                    self?.memory.accept(value)
                }
        }).disposed(by: self.disposeBag)
        return .TextItem(viewModel: viewModel)
    }
    
    private func graffitiCHunkItem(_ graffitiChunk: GraffitiChunk) -> MemoryCreateCollectionItem {
        let viewModel = GraffitiChunkViewModel(graffitiChunk)
        return .GraffitiItem(viewModel: viewModel)
    }
    
    private func photoChunkItem(_ photoChunk: PhotoChunk) -> MemoryCreateCollectionItem {
        let viewModel = PhotoChunkViewModel(photoChunk)
        
        viewModel.outputs
            .detailPhotoRequestObservable
            .subscribe(onNext: { [weak self] in

                self?.photoDetailObserver.onNext(photoChunk.photo)
        }).disposed(by: self.disposeBag)
        
        viewModel.outputs
            .copyPhotoRequest
            .subscribe(onNext: { (_) in
                
                DispatchQueue.global(qos: .utility).async {
                    UIPasteboard.general.image = UIImage(data: photoChunk.photo)
                }
        }).disposed(by: self.disposeBag)
        
        viewModel.outputs
            .sharePhotoRequest
            .subscribe(onNext: { [weak self] in

                self?.photoShareObserver
                    .onNext(photoChunk.photo)
        }).disposed(by: self.disposeBag)
        
        viewModel.outputs
            .removePhotoRequest
            .subscribe(onNext: { [weak self] in

                if let value = self?.memory.value {
                    value.removeChunk(photoChunk)
                    self?.memory.accept(value)
                }
        }).disposed(by: self.disposeBag)
        
        return .PhotoItem(viewModel: viewModel)
    }
}


// MARK: Text Chunk ViewModel


class TextChunkViewModel: TextChunkViewModelType, TextChunkViewModelOutput, TextChunkViewModelInput {
    
    var outputs: TextChunkViewModelOutput { return self }
    var inputs: TextChunkViewModelInput { return self }
    
    // MARK: Outputs
    var text: BehaviorRelay<NSAttributedString>
    
    var removeTextRequest: Observable<Void>
    
    // MARK: Inputs
    lazy var tapRequest = { {} }()
    lazy var longPressRequest = { {} }()
    lazy var contextRemoveRequest = { { self.removeRequestPublisher.onNext(()) } }()
    
    // MARK: Private
    private let chunk: TextChunk
    private let disposeBag = DisposeBag()
    
    private let removeRequestPublisher = PublishSubject<Void>()
    
    // MARK: Init
    init(_ chunk: TextChunk) {
        self.chunk = chunk
        text = .init(value: chunk.text)
        
        removeTextRequest = removeRequestPublisher.asObservable()
        
        text.bind { [weak self] text in
            self?.chunk.text = text
        }.disposed(by: disposeBag)
    }
}


// MARK: Photo Chunk ViewModel


class PhotoChunkViewModel: PhotoChunkViewModelType, PhotoChunkViewModelOutput, PhotoChunkViewModelInput {
    var outputs: PhotoChunkViewModelOutput { return self }
    var inputs: PhotoChunkViewModelInput { return self }
    
    // MARK: Outputs
    var photo: BehaviorRelay<Data>
    
    var detailPhotoRequestObservable: Observable<Void>
    
    var sharePhotoRequest: Observable<Void>
    var copyPhotoRequest: Observable<Void>
    var removePhotoRequest: Observable<Void>
    
    // MARK: Inputs
    lazy var tapRequest = { { self.tapRequestPublisher.onNext(()) } }()
    lazy var longPressRequest = { {} }()
    
    lazy var contextShareRequest = { { self.shareRequestPublisher.onNext(()) } }()
    lazy var contextCopyRequest = { { self.copyRequestPublisher.onNext(()) } }()
    lazy var contextRemoveRequest = { { self.removeRequestPublisher.onNext(()) } }()
    
    // MARK: Private
    private let chunk: PhotoChunk
    private let disposeBag = DisposeBag()
    
    private let tapRequestPublisher = PublishSubject<Void>()
    
    private let shareRequestPublisher = PublishSubject<Void>()
    private let copyRequestPublisher = PublishSubject<Void>()
    private let removeRequestPublisher = PublishSubject<Void>()
    
    // MARK: Init
    init(_ chunk: PhotoChunk) {
        self.chunk = chunk
        photo = .init(value: chunk.photo)
        
        detailPhotoRequestObservable = tapRequestPublisher.asObservable()
        
        sharePhotoRequest = shareRequestPublisher.asObservable()
        copyPhotoRequest = copyRequestPublisher.asObservable()
        removePhotoRequest = removeRequestPublisher.asObservable()
        
        photo.bind { [weak self] photo in
            self?.chunk.photo = photo
        }.disposed(by: disposeBag)
    }
}


// MARK: Graffiti Chunk View Model


class GraffitiChunkViewModel: GraffitiChunkViewModelType, GraffitiChunkViewModelOutput, GraffitiChunkViewModelInput {
    
    var outputs: GraffitiChunkViewModelOutput { return self }
    var inputs: GraffitiChunkViewModelInput { return self }
    
    // MARK: Outputs
    let graffiti: Observable<Data>
    
    var sharePhotoRequest: Observable<Void> { .just(()) }
    var copyPhotoRequest: Observable<Void> { .just(()) }
    var removePhotoRequest: Observable<Void> { .just(()) }
    
    // MARK: Inputs
    var contextShareRequest: () -> () { { print("share") }}
    var contextCopyRequest: () -> () { { print("copy") }}
    var contextRemoveRequest: () -> () { { print("remove") }}
    
    // MARK: Private
    private let chunk: GraffitiChunk
    private let disposeBag = DisposeBag()
    
    // MARK: Init
    init(_ chunk: GraffitiChunk) {
        self.chunk = chunk
        graffiti = .just(chunk.graffiti)
    }
}

