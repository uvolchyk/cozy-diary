//
//  GraffitiCreateCoordinator.swift
//  Cozy
//
//  Created by Uladzislau Volchyk on 8/24/20.
//  Copyright © 2020 Uladzislau Volchyk. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

protocol GraffitiCreateCoordinatorOutput {
    var saveObservable: Observable<Data> { get }
    var closeObservable: Observable<Void> { get }
}


class GraffitiCreateCoordinator: Coordinator, GraffitiCreateCoordinatorOutput {
    
    var outputs: GraffitiCreateCoordinatorOutput { return self }
    
    // MARK: Outputs
    let saveObservable: Observable<Data>
    let closeObservable: Observable<Void>
    
    // MARK: Private
    private let savePublisher = PublishSubject<Data>()
    private let closePublisher = PublishSubject<Void>()
    
    var viewController: GraffitiCreateViewController!
    let presentationController: UIViewController
    
    private let disposeBag = DisposeBag()
    
    init(_ presentationController: UIViewController) {
        self.presentationController = presentationController
        
        saveObservable = savePublisher.asObservable()
        closeObservable = closePublisher.asObservable()
    }
    
    func start() {
        let viewModel = GraffitiCreateViewModel()
        viewController = .init(viewModel: viewModel)
        viewController.modalPresentationStyle = .fullScreen
        presentationController.present(viewController, animated: true)
        
        
        
        viewModel.outputs.saveRequestObservable
            .subscribe(onNext: { [weak self] data in
                self?.savePublisher.onNext(data)
            }).disposed(by: disposeBag)
        
        
        viewModel.outputs.closeRequestObservable
            .subscribe(onNext: { [weak self] in
                self?.closePublisher.onNext(())
            }).disposed(by: disposeBag)
        
        
        
        
    }
}
