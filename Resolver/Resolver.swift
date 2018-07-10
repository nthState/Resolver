// The MIT License (MIT)
//
// Copyright (c) 2015 Chris Davis, contact@nthstate.com
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
//  Resolver.swift
//  Resolver
//
//  Created by Chris Davis on 20/06/2015.
//  Copyright © 2015 nthState. All rights reserved.
//

//
//  Dependency.swift
//  MyFramework
//
//  Created by Chris Davis on 02/05/2017.
//  Copyright © 2017 octopuslabs. All rights reserved.
//

// MARK:- Imports

import Foundation
import UIKit

// MARK:- References

public let Resolver_test_argument = "-RESOLVERTEST"
public let Resolver_test_prefix = "Resolver"

// MARK:- Class

public class Resolver
{
    
    fileprivate static var testSharedInstances:[String:AnyObject] = [String:AnyObject]()
    
    /**
     Encodes testable objects, base 64's the data and outputs a string.
     
     This string is then sent in the launch arguments
     */
    public class func DataForObjects(_ objects: AnyObject...) -> String {
        var output:[String:String] = [String:String]()
        for object in objects {
            let name = NSStringFromClass(type(of: object)).components(separatedBy: ".").last!
            let data = NSKeyedArchiver.archivedData(withRootObject: object)
            let asBase64 = data.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            output[name] = asBase64
        }
        
        var bytes:Data!
        do {
            bytes = try JSONSerialization.data(withJSONObject: output, options: JSONSerialization.WritingOptions(rawValue: 0))
        } catch let error as NSError {
            fatalError("error serializing objects: \(error.localizedDescription)")
        }
        
        return Resolver_test_prefix + bytes.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }
    
    /**
     If the resolve method is used in the projects code, it tries to get a class from the framework project
     and init' it up.
     
     However, if the code detects it's running from a UI Test, it tries to init up a test object.
     */
    public class func Resolve<T>(name:String, shared:AnyObject? = nil) -> T? {
        
        let isUITesting = CommandLine.arguments.contains(Resolver_test_argument)
        
        if isUITesting == false {
            return loadDefault(name: name, shared:shared)
        } else {
            
            // Take the encoded objects
            let matchingArgument = CommandLine.arguments.filter({$0.hasPrefix(Resolver_test_prefix)})
            
            var base64Encoded:String!
            if let first = matchingArgument.first {
                let rangeToRemove = Resolver_test_prefix.characters.indices.startIndex..<Resolver_test_prefix.characters.indices.endIndex
                base64Encoded = first.replacingCharacters(in: rangeToRemove, with: "")
                
                let data = Data(base64Encoded: base64Encoded, options: NSData.Base64DecodingOptions(rawValue: 0))!
                
                // Try and parse them in a dictionary
                var jsonObj:[String:String]!
                do {
                    jsonObj = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0)) as! [String : String]
                } catch let error as NSError {
                    print("error parsing serialized object to dictionary: \(error.localizedDescription)")
                }
                
                // For each entity
                for (key, value) in jsonObj {
                    
                    let shortName = key.replacingOccurrences(of: "Test", with: "")
                    if name.range(of: shortName) == nil {
                        continue
                    }
                    
                    // Extract the base64 data and unarchive
                    let base64Object = Data(base64Encoded: value, options: NSData.Base64DecodingOptions(rawValue: 0))!
                    if let inst = NSKeyedUnarchiver.unarchiveObject(with: base64Object) as? T {
                        // If we want a static, try and find it here
                        if let existingInst = testSharedInstances[key], shared != nil {
                            return existingInst as? T
                        }
                        
                        let instanceName = "\(inst.self)"
                        if instanceName.range(of: key) != nil {
                            testSharedInstances[key] = inst as! NSObject
                            return inst
                        }
                    } else {
                        print("Could not unarchive: \(name)")
                    }
                }
                
                // If not found.
                return loadDefault(name: name, shared:shared)
                
            }
            
        }
        
        return nil
    }
    
    /**
     Load default implementation of object
     */
    class func loadDefault<T>(name:String, shared:AnyObject? = nil) -> T? {
        let cls:AnyClass? = NSClassFromString("MyFramework." + name)
        let type:NSObject.Type = cls as! NSObject.Type
        if shared == nil {
            return type.init() as? T
        } else {
            return (shared as! T)
        }
    }
    
}



