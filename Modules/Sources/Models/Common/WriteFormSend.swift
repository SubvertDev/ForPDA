//
//  WriteFormSend.swift
//  ForPDA
//
//  Created by Xialtal on 18.03.25.
//

public enum WriteFormSend: Sendable {
    case post(PostSend)
    case report(ReportResponseType)
}
