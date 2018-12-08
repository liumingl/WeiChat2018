//
//  Group.swift
//  WeiChat
//
//  Created by 刘铭 on 2018/12/8.
//  Copyright © 2018 刘铭. All rights reserved.
//

import Foundation
import FirebaseFirestore

class Group {
  let groupDictionary: NSMutableDictionary
  
  init(groupId: String, subject: String, ownerId: String, members: [String], avatar: String) {
    groupDictionary = NSMutableDictionary(objects: [groupId, subject, ownerId, members, members, avatar], forKeys: [kGROUPID as NSCopying, kNAME as NSCopying, kOWNERID as NSCopying, kMEMBERS as NSCopying, kMEMBERSTOPUSH as NSCopying, kAVATAR as NSCopying])
  }
  
  func saveGroup(group: NSMutableDictionary) {
    let date = dateFormatter().string(from: Date())
    
    groupDictionary[kDATE] = date
    
    reference(.Group).document(group[kGROUPID] as! String).setData(group as! [String: Any])
  }
  
  class func updateGroup(groupId: String, withValues: [String: Any]) {
    reference(.Group).document(groupId).updateData(withValues)
  }
  
  
}
