//
//  ExampleUserService.swift
//  Resolver
//
//  Created by Chris Davis on 10/07/2018.
//  Copyright © 2018 nthState. All rights reserved.
//

import Foundation

public class ExampleUserService : ExampleUserServiceProtocol {
    
    public static let shared = ExampleUserService()
    
    init() {
        
    }
    
    var name: String! = "None"
    
}
