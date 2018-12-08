//
//  Recent.swift
//  WeiChat
//
//  Created by 刘铭 on 2018/11/6.
//  Copyright © 2018 刘铭. All rights reserved.
//

import Foundation

func startPrivateChat(user1: FUser, user2: FUser) -> String {
  let userId1 = user1.objectId
  let userId2 = user2.objectId
  
  var chatRoomId = ""
  
  let value = userId1.compare(userId2).rawValue
  
  if value < 0 {
    chatRoomId = userId1 + userId2
  }else {
    chatRoomId = userId2 + userId1
  }
  
  let members = [userId1, userId2]
  
  // create recent chats
  createRecent(members: members, chatRoomId: chatRoomId, withUserUserName: "", type: kPRIVATE, users: [user1, user2], avatarOfGroup: nil)
  
  return chatRoomId
}

func createRecent(members: [String], chatRoomId: String, withUserUserName: String, type: String, users: [FUser]?, avatarOfGroup: String?) {
  
  var tempMembers = members
  
  reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
    guard let snapshot = snapshot else { return }
    
    if !snapshot.isEmpty {
      for recent in snapshot.documents {
        let currentRecent = recent.data() as NSDictionary
        if let currentUserId = currentRecent[kUSERID] {
          if tempMembers.contains(currentUserId as! String) {
            tempMembers.remove(at: tempMembers.index(of: currentUserId as! String)!)
          }
        }
      }
    }
    
    for userId in tempMembers {
      // Create recent items
      createRecentItem(userId: userId, chatRoomId: chatRoomId, members: members, withUserUserName: withUserUserName, type: type, users: users, avatarOfGroup: avatarOfGroup)
    }
  }
}


func createRecentItem(userId: String, chatRoomId: String, members: [String], withUserUserName: String, type: String, users: [FUser]?, avatarOfGroup: String?) {
  
  let localReference = reference(.Recent).document()
  let recentId = localReference.documentID
  let date = dateFormatter().string(from: Date())
  
  var recent: [String: Any]!
  
  if type == kPRIVATE {
    //private
    var withUser: FUser?
    
    if users != nil && users!.count > 0 {
      if userId == FUser.currentId() {
        withUser = users!.last
      }else {
        withUser = users!.first
      }
    }
    
    recent = [kRECENTID: recentId, kUSERID: userId, kCHATROOMID: chatRoomId, kMEMBERS: members, kMEMBERSTOPUSH: members, kWITHUSERFULLNAME: withUser!.fullname, kWITHUSERUSERID: withUser!.objectId, kLASTMESSAGE: "", kCOUNTER: 0, kDATE: date, kTYPE: type, kAVATAR: withUser!.avatar]
    
  }else {
    //group
    if avatarOfGroup != nil {
      recent = [kRECENTID: recentId, kUSERID: userId, kCHATROOMID: chatRoomId, kMEMBERS: members, kMEMBERSTOPUSH: members, kWITHUSERFULLNAME: withUserUserName, kLASTMESSAGE: "", kCOUNTER: 0, kDATE: date, kTYPE: type, kAVATAR: avatarOfGroup!]
    }
  }
  
  //save recent chat
  localReference.setData(recent)
}

func restartRecentChat(recent: NSDictionary) {
  if recent[kTYPE] as! String == kPRIVATE {
    createRecent(members: recent[kMEMBERSTOPUSH] as! [String], chatRoomId: recent[kCHATROOMID] as! String, withUserUserName: recent[kWITHUSERFULLNAME] as! String, type: recent[kTYPE] as! String, users: [FUser.currentUser()!], avatarOfGroup: nil)
  }
  
  if recent[kTYPE] as! String == kGROUP {
    createRecent(members: recent[kMEMBERSTOPUSH] as! [String], chatRoomId: recent[kCHATROOMID] as! String, withUserUserName: recent[kWITHUSERFULLNAME] as! String, type: kGROUP, users: nil, avatarOfGroup: nil)
  }
}

// Clear Counter
func clearRecentCounterItem(recent: NSDictionary) {
  reference(.Recent).document(recent[kRECENTID] as! String).updateData([kCOUNTER: 0])
}

func clearRecentCounter(chatRoomId: String) {
  reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
    guard let snapshot = snapshot else { return }
    
    if !snapshot.isEmpty {
      for recent in snapshot.documents {
        let currentRecent = recent.data() as NSDictionary
        if currentRecent[kUSERID] as! String == FUser.currentId() {
          clearRecentCounterItem(recent: currentRecent)
        }
      }
    }
  }
}

// update Recent
func updateRecentItem(recent: NSDictionary, lastMessage: String) {
  let date = dateFormatter().string(from: Date())
  
  var counter = recent[kCOUNTER] as! Int
  
  if recent[kUSERID] as? String != FUser.currentId() {
    counter += 1
  }
  
  let values = [kLASTMESSAGE: lastMessage, kCOUNTER: counter, kDATE: date] as [String: Any]
  
  reference(.Recent).document(recent[kRECENTID] as! String).updateData(values)
}

func updateRecents(chatRoomId: String, memberIds: [String], lastMessage: String) {
  reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
    guard let snapshot = snapshot else { return }
    
    if !snapshot.isEmpty {
      for recent in snapshot.documents {
        let currentRecent = recent.data() as NSDictionary
        updateRecentItem(recent: currentRecent, lastMessage: lastMessage)
      }
    }
  }
}

func updateExistingRecentWithNewValues(chatRoomId: String, members: [String], withValues: [String: Any]) {
  reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
    guard let snapshot = snapshot else { return }
    
    if !snapshot.isEmpty {
      for recent in snapshot.documents {
        let recent = recent.data() as NSDictionary
        updateRecent(recentId: recent[kRECENTID] as! String, withValues: withValues)
      }
    }
  }
}


func updateRecent(recentId: String, withValues: [String: Any]) {
  reference(.Recent).document(recentId).updateData(withValues)
}

// Block User
func blockUser(userToBlock: FUser) {
  let userId1 = FUser.currentId()
  let userId2 = userToBlock.objectId
  
  var chatRoomId = ""
  
  let value = userId1.compare(userId2).rawValue
  
  if value < 0 {
    chatRoomId = userId1 + userId2
  }else {
    chatRoomId = userId2 + userId1
  }
  
  getRecentsFor(chatRoomId: chatRoomId)
}

func getRecentsFor(chatRoomId: String) {
  reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
    guard let snapshot = snapshot else { return }
    
    if !snapshot.isEmpty {
      for recent in snapshot.documents {
        let recent = recent.data() as NSDictionary
        deleteRecentChat(recentDictionary: recent)
      }
    }
  }
}

//MARK: - Delete Recent
func deleteRecentChat(recentDictionary: NSDictionary) {
  if let recentId = recentDictionary[kRECENTID] {
    reference(.Recent).document(recentId as! String).delete()
  }
}

//MARK: - Group

func createRecentsForNewMembers(groupId: String, groupName: String, membersToPush: [String], avatar: String) {
  createRecent(members: membersToPush, chatRoomId: groupId, withUserUserName: groupName, type: kGROUP, users: nil, avatarOfGroup: avatar)
}

func startGroupChat(group: Group) {
  let chatRoomId = group.groupDictionary[kGROUPID] as! String
  
  let members = group.groupDictionary[kMEMBERS] as! [String]
  
  createRecent(members: members, chatRoomId: chatRoomId, withUserUserName: group.groupDictionary[kNAME] as! String, type: kGROUP, users: nil, avatarOfGroup: group.groupDictionary[kAVATAR] as? String)
}


