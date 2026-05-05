//
//  TopicEditRequest+Extension.swift
//  ForPDA
//
//  Created by Xialtal on 1.05.26.
//

import APIClient
import Models

extension Topic.Poll {
    var asDocument: PDAPIDocument {
        let document = PDAPIDocument()
        try! document.append(name)
        
        let options = PDAPIDocument()
        for option in self.options {
            let optionDocument = PDAPIDocument()
            
            try! optionDocument.append(option.name)
            try! optionDocument.append(option.several)
            try! optionDocument.append(option.choices.compactMap { $0.name })
            try! optionDocument.append(option.choices.compactMap { $0.votes })
            
            try! options.append(optionDocument)
        }
        try! document.append(options)
        
        return document
    }
}
