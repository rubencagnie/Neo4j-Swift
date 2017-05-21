//
//  NSDictionary+Extensions.swift
//  Theo
//
//  Created by Cory D. Wiles on 5/16/17.
//
//

import Foundation

extension NSDictionary {
    
    func decodingKey<ReturnType: DecodableType>(_ key: Key) throws -> ReturnType {
        
        guard let value = self[key] as? ReturnType else {
            throw DecodeError.noValueForFoundationKey(message: "Foundation error for key: \(key)")
        }
        
        return value
    }
    
    func decodingKey<ReturnType: DecodableType>(_ key: Key) -> ReturnType? {
        return self[key] as? ReturnType
    }
}
