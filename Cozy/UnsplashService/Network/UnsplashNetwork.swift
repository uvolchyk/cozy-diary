//
//  UnsplashNetwork.swift
//  Cozy
//
//  Created by Uladzislau Volchyk on 8/26/20.
//  Copyright © 2020 Uladzislau Volchyk. All rights reserved.
//

import Foundation
import RxSwift


protocol URLRequestConvertible {
    func urlReqeust() -> URLRequest?
}

enum UnsplashRequest: URLRequestConvertible {
    case photos(page: Int, limit: Int)
    case searchPhotos(term: String, page: Int, limit: Int)
    
    // MARK: Configurations
    
    var scheme: String {
        "https"
    }
    
    var host: String {
        "api.unsplash.com"
    }
    
    var endPoint: String {
        switch self {
        case .photos:
            return "/photos"
        case .searchPhotos:
            return "/search/photos"
        }
    }
    
    var method: String {
        switch self {
        case .photos,
             .searchPhotos:
            return "GET"
        }
    }
    
    var queryItems: [URLQueryItem] {
        let base: [URLQueryItem] = [ .init(name: "client_id", value: "v6gYNEmZzZCBVu_aVTGmHNQduCmZwUdqjQzM_IViH7Q") ]
        switch self {
        case let .photos(page, limit):
            return [
                .init(name: "page", value: "\(page)"),
                .init(name: "per_page", value: "\(limit)")
            ] + base
        case let .searchPhotos(term, page, limit):
            return [
                .init(name: "query", value: "\(term)"),
                .init(name: "page", value: "\(page)"),
                .init(name: "per_page", value: "\(limit)")
            ] + base
        }
    }
    
    func urlReqeust() -> URLRequest? {
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        urlComponents.path = "\(endPoint)"
        urlComponents.queryItems = queryItems
//        64590bced0328aeeb23ef7fe893c6b6e2e54aa963f383020f6cbf2bddde5fcb4
//        v6gYNEmZzZCBVu_aVTGmHNQduCmZwUdqjQzM_IViH7Q
        
        guard let url = urlComponents.url else { return nil }
        var request = URLRequest(url: url)
        
        request.httpMethod = method
        return request
    }
    
}


protocol UnsplashServiceType {
    func fetch<T: Decodable>(request: UnsplashRequest) -> Observable<T>
}

class UnsplashService: UnsplashServiceType {
    
    func fetch<T: Decodable>(request: UnsplashRequest) -> Observable<T> {
            guard let request = request.urlReqeust() else {
                return .create { (observer) -> Disposable in
                    observer.onError(URLError(.badURL))
                    return Disposables.create()
                }                
            }
            
            return URLSession.shared.rx.data(request: request).flatMap { (data) -> Observable<T> in
                .create { (observer) -> Disposable in
                    if let result = try? JSONDecoder().decode(T.self, from: data) {
                        observer.onNext(result)
                        observer.onCompleted()
                    } else {
                        observer.onError(URLError(.downloadDecodingFailedToComplete))
                    }
                    return Disposables.create()
                }
            }
    }
    
}
