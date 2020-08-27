//
//  UnsplashImageCollectionCoordinator.swift
//  Cozy
//
//  Created by Uladzislau Volchyk on 8/26/20.
//  Copyright © 2020 Uladzislau Volchyk. All rights reserved.
//

import Foundation
import RxSwift


class UnsplashImageCollectionCoordinator: ParentCoordinator {
    
    
    var childCoordinators: [Coordinator] = []
    
    var viewController: UnsplashImageCollectionController!
    var viewModel: UnsplashImageCollectionViewModel!
    
    private let disposeBag = DisposeBag()
    
    func start() {
        
        viewModel = UnsplashImageCollectionViewModel(service: UnsplashService())
        
        viewModel.outputs.detailImageRequest
            .asObservable()
            .subscribe(onNext: { [weak self] (photo) in
                self?.gotodetail(meta: photo)
            })
            .disposed(by: disposeBag)
        
        viewController = UnsplashImageCollectionController(viewModel: viewModel)        
    }
    
    func gotodetail(meta: UnsplashPhoto) {
        let viewModel = UnsplashImageDetailViewModel(imageMeta: meta)
        let controller = ImageDetailViewController(viewModel)
        
        viewController.present(controller, animated: true)
    }
}
