//
//  CommentsFactory.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 19.11.2023.
//

import RouteComposer

final class CommentsFactory: Factory {
    
    typealias ViewController = CommentsVC
    typealias Context = Article
    
    func build(with context: Context) throws -> ViewController {
        let presenter = CommentsPresenter(article: context)
        let viewController = ViewController(presenter: presenter)
        presenter.view = viewController
        
        return viewController
    }
}
