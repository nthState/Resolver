//
//  ExampleController.swift
//  Resolver
//
//  Created by Chris Davis on 10/07/2018.
//  Copyright © 2018 nthState. All rights reserved.
//

import Foundation

class ExampleController {
    
    var userService: ExampleUserServiceProtocol!
    
    init() {
        satisfyDependencies()
    }
    
    private func satisfyDependencies() {
        userService = userService ?? Resolver.Resolve(name: "ExampleUserService")
        // or
        userService = userService ?? Resolver.Resolve(name: "ExampleUserService", shared: ExampleUserService.shared)
    }
    
}
