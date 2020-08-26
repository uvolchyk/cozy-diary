//
//  ImageProposalSheetController.swift
//  Cozy
//
//  Created by Uladzislau Volchyk on 8/20/20.
//  Copyright © 2020 Uladzislau Volchyk. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UIAlertController {
    
    /// Bindable sink for `title`.
    public var title: Binder<String> {
        return Binder(base) { alertController, title in
            alertController.title = title
        }
    }
    
    /// Bindable sink for `message`.
    public var message: Binder<String> {
        return Binder(base) { alertController, message in
            alertController.message = message
        }
    }
}


class ImageProposalSheetController: UIAlertController {

    var viewModel: ImageProposalViewModelType!
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    func bindViewModel() {
        
        let outputs = viewModel.outputs
        let inputs = viewModel.inputs
        
        outputs.title
            .bind(to: self.rx.title)
            .disposed(by: disposeBag)
        
        outputs.message
            .bind(to: self.rx.message)
            .disposed(by: disposeBag)
        
        let unsplashAction = UIAlertAction(
            title: "Unsplash",
            style: .default,
            handler: { _ in inputs.unsplashAction() })
        addAction(unsplashAction)
        
        let galleryAction = UIAlertAction(
            title: "Gallery",
            style: .default,
            handler: { _ in inputs.galleryAction()})
        addAction(galleryAction)
        
        let cameraAction = UIAlertAction(
            title: "Camera",
            style: .default,
            handler: { _ in inputs.cameraAction()})
        addAction(cameraAction)
        
        addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    }
    
}
