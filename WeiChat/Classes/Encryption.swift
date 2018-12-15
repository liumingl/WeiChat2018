//
//  Encryption.swift
//  WeiChat
//
//  Created by 刘铭 on 2018/12/14.
//  Copyright © 2018 刘铭. All rights reserved.
//

import Foundation
import RNCryptor

class Encryption {
  class func encrytText(chatRoomId: String, message: String) -> String {
    let data = message.data(using: String.Encoding.utf8)
    
    let encryptedData = RNCryptor.encrypt(data: data!, withPassword: chatRoomId)
    
    return encryptedData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
  }
  
  class func decrytText(chatRoomId: String, encryptedMessage: String) -> String {
    let decrptor = RNCryptor.Decryptor(password: chatRoomId)
    
    let encryptedData = NSData(base64Encoded: encryptedMessage, options: NSData.Base64DecodingOptions(rawValue: 0))
    
    var message: NSString = ""
    
    if encryptedData != nil {
      do {
        let decryptedData = try decrptor.decrypt(data: encryptedData! as Data)
        
        message = NSString(data: decryptedData, encoding: String.Encoding.utf8.rawValue)!
      }catch {
        print("error decrypting text \(error.localizedDescription)")
      }
    }
    
    return message as String
  }
}
