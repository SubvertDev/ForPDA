//
//  Errors.swift
//  ForPDA
//
//  Created by Subvert on 19.08.2023.
//
//  swiftlint:disable unneeded_synthesized_initializer

import Foundation

struct FailingRouterIgnoreError: Error {

    let underlyingError: Error

    init(underlyingError: Error) {
        self.underlyingError = underlyingError
    }

}
