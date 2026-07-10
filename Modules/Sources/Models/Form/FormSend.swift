//
//  FormSend.swift
//  ForPDA
//
//  Created by Xialtal on 18.03.25.
//

public enum FormSend: Sendable {
    case post(PostSend)
    case topic(Int)
    case report
    case note
}
