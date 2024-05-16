//
//  LoginInterceptor.swift
//  ForPDA
//
//  Created by Subvert on 19.08.2023.
//

import UIKit
import RouteComposer
import Factory

final class LoginInterceptor<C>: RoutingInterceptor {
    
    @Injected(\.analyticsService) private var analytics
    @Injected(\.settingsService) private var settings

    typealias Context = C

    func perform(with context: Context, completion: @escaping (_: RoutingResult) -> Void) {
        guard settings.getUser() == nil else {
            analytics.event(Event.Menu.profileOpen.rawValue)
            completion(.success)
            return
        }
        
        do {
            analytics.event(Event.Menu.loginOpen.rawValue)
            try DefaultRouter().navigate(to: LoginConfiguration.loginScreen, with: nil, animated: true) { routingResult in
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
