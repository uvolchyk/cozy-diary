//
//  MemoryEditViewModelType.swift
//  Cozy
//
//  Created by Uladzislau Volchyk on 9/3/20.
//  Copyright © 2020 Uladzislau Volchyk. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa


enum MemoryCreateCollectionItem {
    case TextItem(viewModel: TextChunkViewModelType)
    case PhotoItem(viewModel: PhotoChunkViewModelType)
    case GraffitiItem(viewModel: GraffitiChunkViewModelType)
}

protocol MemoryCreateViewModelOutput {
    
    // MARK: Controller Output
    var items: BehaviorRelay<[MemoryCreateCollectionItem]> { get }
    var title: Driver<String> { get }
    
    // MARK: Coordinator Output
    var photoInsertRequestObservable: Observable<Void> { get }
    var photoDetailRequestObservable: Observable<Data> { get }
    var photoShareRequestObservable: Observable<Data> { get }
    
    var tagAddRequestObservable: Observable<Memory> { get }
    
    var graffitiInsertRequestObservable: Observable<Void> { get }
    
    var shouldClearStack: Observable<Void> { get }
}

protocol MemoryCreateViewModelInput {
    
    // MARK: Controller Input
    var viewWillAppear: PublishRelay<Void> { get }
    var viewWillDisappear: PublishRelay<Void> { get }
    
    var textChunkAdd: PublishRelay<Void> { get }
    var photoChunkAdd: PublishRelay<Void> { get }
    var graffitiChunkAdd: PublishRelay<Void> { get }
    var tagAdd: PublishRelay<Void> { get }
    
    // MARK: Coordinator Input
    var photoInsertResponse: (ImageMeta) -> () { get }
    var graffitiInsertResponse: (Data) -> () { get }
}

protocol MemoryCreateViewModelType {
    var outputs: MemoryCreateViewModelOutput { get }
    var inputs: MemoryCreateViewModelInput { get }
}
