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

import Foundation
import UIKit

public let Resolver_test_arument = "TEST"
let Resolver_test_prefix = "Resolver"

//: ## Resolver
//:
//: Uses Coding-by-convention:
//: If your protocol is called: MyProtocol and lives in AppNameFramework
//: Then your real implementation is called: My and lives in AppName
//: Your test implementation is called: TestMy and lives in AppNameFrameworkTest
//:
public class Resolver
{
    
    private static var testSingletons:[String:AnyObject] = [String:AnyObject]()
    
    //: ## Create a serialized string of your objects
    //:
    //: Pass this into your UI Launch Arguments
    //:
    public class func DataForObjects(objects: AnyObject...) -> String
    {
        var output:[String:String] = [String:String]()
        for object in objects
        {
            let name = NSStringFromClass(object.dynamicType).componentsSeparatedByString(".").last!
            let data = NSKeyedArchiver.archivedDataWithRootObject(object)
            let asBase64 = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
            output[name] = asBase64
        }
        
        var bytes:NSData!
        do
        {
            bytes = try NSJSONSerialization.dataWithJSONObject(output, options: NSJSONWritingOptions(rawValue: 0))
        } catch let error as NSError {
            print("error serializing objects: \(error.localizedDescription)")
        }
        
        return Resolver_test_prefix + bytes.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    }
    
    //: ## Load a default object
    //:
    //: Note, sharedInstance is now an extension on NSObject public class var sharedInstance:NSObject
    //:
    private class func loadDefault<T>(name:String, useStatic:Bool = false) -> T?
    {
        let cls:AnyClass? = NSClassFromString(name)
        let type:NSObject.Type = cls as! NSObject.Type
        if useStatic == false{
            return type() as? T
        } else {
            return type.sharedInstance as? T
        }
    }
    
    //: ## Resolve
    //:
    //: Uses Coding-by-convention:
    //: If your protocol is called: MyProtocol and lives in AppNameFramework
    //: Then your real implementation is called: My and lives in AppName
    //: Your test implementation is called: TestMy and lives in AppNameFrameworkTest
    //:
    public class func Resolve<T>(name:String, useStatic:Bool = false) -> T?
    {
        let bundleName = NSBundle.mainBundle().infoDictionary!["CFBundleName"] as! String
        let appPrefix = bundleName + "Framework"
        let uitest = Process.arguments.contains(Resolver_test_arument)
        
        var protocolName = "\(T.self)"
        protocolName = protocolName.stringByReplacingOccurrencesOfString("Swift.Optional", withString: "")
        protocolName = protocolName.stringByReplacingOccurrencesOfString("<", withString: "")
        protocolName = protocolName.stringByReplacingOccurrencesOfString(">", withString: "")
        protocolName = protocolName.stringByReplacingOccurrencesOfString(".", withString: "")
        protocolName = protocolName.stringByReplacingOccurrencesOfString(appPrefix, withString: "")
        protocolName = protocolName.stringByReplacingOccurrencesOfString("Protocol", withString: "")
        let defaultName = bundleName + "." + protocolName
        
        var obj:AnyObject!
        if uitest == false
        {
            // Load real implementation
            obj = loadDefault(defaultName, useStatic: useStatic)
        } else {
            
            // Take the encoded objects
            let matchingArgument = Process.arguments.filter({$0.hasPrefix(Resolver_test_prefix)})
            
            var base64Encoded:String!
            if let first = matchingArgument.first
            {
                let rangeToRemove = Range<String.Index>(start: Resolver_test_prefix.startIndex, end: Resolver_test_prefix.endIndex)
                base64Encoded = first.stringByReplacingCharactersInRange(rangeToRemove, withString: "")
            } else {
                print("No data found found")
                return nil
            }
            
            
            let data = NSData(base64EncodedString: base64Encoded, options: NSDataBase64DecodingOptions(rawValue: 0))!
            
            // Try and parse them in a dictionary
            var jsonObj:[String:String]!
            do
            {
                jsonObj = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(rawValue: 0)) as! [String : String]
            } catch let error as NSError {
                print("error parsing serialized object to dictionary: \(error.localizedDescription)")
            }
            
            // For each entity
            for (key, value) in jsonObj
            {
                // Extract the base64 data and unarchive
                let base64Object = NSData(base64EncodedString: value, options: NSDataBase64DecodingOptions(rawValue: 0))!
                if let inst = NSKeyedUnarchiver.unarchiveObjectWithData(base64Object) as? T
                {
                    // If we want a static, try and find it here
                    if
                        let existingInst = testSingletons[key] as? NSObject.Type
                        where useStatic
                    {
                        return existingInst.sharedInstance as? T
                    }
                    
                    // Otherwise "init()" one up.
                    let name = "\(inst.self)"
                    if name.rangeOfString(key) != nil
                    {
                        testSingletons[key] = inst as! NSObject
                        return inst// as? T
                    }
                }
            }
            
            // load a default, if no test implementation was found.
            obj = loadDefault(defaultName, useStatic: useStatic)
            
        }
        
        return obj as? T
    }
    
    //: ## ResolveNotNil
    //:
    //: Resolve if passed object is not nil.
    //:
    public class func Resolve<T>(objectToInit:AnyObject?, useStatic:Bool = false) -> T?
    {
        if objectToInit != nil
        {
            return objectToInit as? T
        } else {
            return Resolver.Resolve("", useStatic:useStatic)
        }
    }
    
}
