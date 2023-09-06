//
//  LoginInterceptor.swift
//  ForPDA
//
//  Created by Subvert on 19.08.2023.
//

import UIKit
import RouteComposer

final class LoginInterceptor<C>: RoutingInterceptor {

    typealias Context = C

    func perform(with context: Context, completion: @escaping (_: RoutingResult) -> Void) {
        guard SettingsService().getUser() == nil else {
            completion(.success)
            return
        }
        
        let router = DefaultRouter()
        do {
            try router.navigate(to: LoginConfiguration.loginScreen, with: nil, animated: true) { routingResult in
                guard routingResult.isSuccessful,
                      let viewController = ClassFinder<LoginVC, Any?>().getViewController() else {
                    completion(.failure(RoutingError.compositionFailed(.init("LoginViewController was not found."))))
                    return
                }
                viewController.interceptorCompletionBlock = completion
            }
        } catch {
            completion(.failure(RoutingError.compositionFailed(.init(
                "Could not present login view controller", underlyingError: error))))
        }
    }
}
