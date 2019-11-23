//
//  ViewController.swift
//  TokenTest
//
//  Created by Florian on 23.11.19.
//  Copyright © 2019 Florian Heidenreich. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var tokenField: NSTokenField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}

class Token: Codable {

    let text: String
    let isRounded: Bool

    init(text: String, isRounded: Bool) {
        self.text = text
        self.isRounded = isRounded
    }
}

extension ViewController: NSTokenFieldDelegate {

    func tokenField(_ tokenField: NSTokenField, displayStringForRepresentedObject representedObject: Any) -> String? {
        if let token = representedObject as? Token {
            if token.isRounded {
                return token.text.trimmingCharacters(in: CharacterSet(charactersIn: "-")).capitalized(with: .current)
            } else {
                return token.text
            }
        }
        return representedObject as? String
    }

    func tokenField(_ tokenField: NSTokenField, styleForRepresentedObject representedObject: Any) -> NSTokenField.TokenStyle {
        if let token = representedObject as? Token {
            return token.isRounded ? .rounded : .none
        } else {
            return .none
        }
    }

    func tokenField(_ tokenField: NSTokenField, representedObjectForEditing editingString: String) -> Any? {
        var isRounded = editingString.hasPrefix("-") && editingString.hasSuffix("-") && editingString.count > 1
        if isRounded {
            // We treat it only as rounded token if we find no dashes inside the editing string
            let startIndex = editingString.index(after: editingString.startIndex)
            let endIndex = editingString.index(before: editingString.endIndex)
            let searchRange = startIndex..<endIndex
            let range = editingString.rangeOfCharacter(from: CharacterSet(charactersIn: "-"), options: [], range: searchRange)
            isRounded = range == nil
        }
        return Token(text: editingString, isRounded: isRounded)
    }

    func tokenField(_ tokenField: NSTokenField, editingStringForRepresentedObject representedObject: Any) -> String? {
        if let token =  representedObject as? Token {
            return token.text
        }
        return representedObject as? String
    }

    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        if let tokens = tokens as? [Token] {
            var added = [Any]()

            for token in tokens {
                if token.isRounded {
                    added.append(token)
                    continue
                }

                let newTokens = createTokens(token.text)
                added.append(contentsOf: newTokens)
            }

            return added
        }
        return tokens
    }

    func createTokens(_ text: String) -> [Token] {
        guard let exp = try? NSRegularExpression(pattern: "-(.+?)-", options: []) else {
            return []
        }

        var tokens = [Token]()
        var previousEndLocation = 0
        let matches = exp.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
        for match in matches {
            let range0 = match.range(at: 0) // Range that denotes the part before the match
            let range1 = match.range(at: 1) // Range that denotes the match

            if previousEndLocation < range0.location {
                let rangePrefix = NSRange(location: previousEndLocation, length: range0.location - previousEndLocation)
                // We found some text that prefixes the matches
                if rangePrefix.length > 0 {
                    if let swiftRange = Range(rangePrefix, in: text) {
                        let name = String(text[swiftRange])
                        tokens.append(Token(text: name, isRounded: false))
                    }
                }
            }

            if let swiftRange = Range(range1, in: text) {
                let name = "-" + text[swiftRange] + "-"
                tokens.append(Token(text: name, isRounded: true))
            }

            previousEndLocation = range0.location + range0.length
        }

        // We found some text that postfixes the matches
        if previousEndLocation < text.count {
            let range = NSRange(location: previousEndLocation, length: text.count - previousEndLocation)
            if let swiftRange = Range(range, in: text) {
                let name = String(text[swiftRange])
                tokens.append(Token(text: name, isRounded: false))
            }
        }

        return tokens
    }
}
