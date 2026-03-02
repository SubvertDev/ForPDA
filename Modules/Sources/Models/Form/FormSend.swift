//
//  FormSend.swift
//  ForPDA
//
//  Created by Xialtal on 18.03.25.
//

public enum FormSend: Sendable {
    case post(PostSend)
    case report(ReportResponseType)
    case topic(Int)
}
