//
//  StringArrayTransformer.swift
//  RadioPlay
//
//  Created by Martin Parmentier
//

import Foundation

@objc(StringArrayTransformer)
final class StringArrayTransformer: NSSecureUnarchiveFromDataTransformer {

    /// Le nom du transformer pour l'enregistrement
    static let name = NSValueTransformerName(rawValue: String(describing: StringArrayTransformer.self))

    /// Les classes autorisées pour la désérialisation sécurisée
    override static var allowedTopLevelClasses: [AnyClass] {
        return [NSArray.self, NSString.self]
    }

    /// Enregistrer le transformer au démarrage de l'app
    public static func register() {
        let transformer = StringArrayTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}
