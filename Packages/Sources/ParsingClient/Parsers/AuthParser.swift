//
//  File.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 01.08.2024.
//

import Foundation
import Models

public struct AuthParser {
    
    // 0 - success
    // 3 - captcha failed
    // 4 - log/pass failed
    
    /// 0. 71642 - request id
    /// 1. 4 - login failed
    /// 2. https://4pda.to/static/captcha/679cb0ca4a09ff1bd20908c179411a47.gif - captcha url
    public static func parseCaptchaUrl(from string: String) throws -> URL {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                let urlString = array[2] as! String
                return URL(string: urlString)!
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    /// 0. 71556 - request id
    /// 1.  0 - login success
    /// 2. 3640948 - user id
    /// 3. 514b1b86eda2bd571b3252fed474adf8 - token
    public static func parseLoginResponse(from string: String) throws -> AuthResponse {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                let responseTypeId = array[1] as! Int
                switch responseTypeId {
                case 0:
                    let userId = array[2] as! Int
                    let token = array[3] as! String
                    return .success(userId: userId, token: token)
                case 3:
                    return .wrongPassword
                case 4:
                    let urlString = array[2] as! String
                    let url = URL(string: urlString)!
                    return .wrongCaptcha(url: url)
                default:
                    return .unknown
                }
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
}
