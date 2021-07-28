//
//  Models+Ext.swift
//  AlexChat
//
//  Created by Alex Lee on 6/10/21.
//  Copyright © 2021 Alex Lee. All rights reserved.
//

import Foundation

protocol Defaultable {
    associatedtype Element

    static var defaultValue: Element { get }
    static var defaultValues: [Element] { get }
}

extension Defaultable {
    static var defaultValues: [Element] {
        return [defaultValue]
    }

    static func firstStored(with predicate: (Element) -> Bool) -> Element? {
        return defaultValues.first(where: predicate)
    }

    static func fetchStored(with predicate: (Element) -> Bool) -> [Element]? {
        return defaultValues.filter(predicate)
    }
}

enum StorableTarget {
    case userDefaults
}

extension Encodable {
    func store(in location: StorableTarget, at name: String) {
        switch location {
        case .userDefaults:
            let encodedSelf = try? JSONEncoder().encode(self)
            UserDefaults.standard.set(encodedSelf, forKey: name)
        }
    }
}

extension Decodable {
    static func retrieve(from location: StorableTarget, with name: String) -> Self? {
        switch location {
        case .userDefaults:
            guard let storedData = UserDefaults.standard.data(forKey: name) else {
                return nil
            }
            return try? JSONDecoder().decode(Self.self, from: storedData)
        }
    }
}
