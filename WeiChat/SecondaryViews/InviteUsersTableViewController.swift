//
//  InviteUsersTableViewController.swift
//  WeiChat
//
//  Created by 刘铭 on 2018/12/11.
//  Copyright © 2018 刘铭. All rights reserved.
//

import UIKit
import ProgressHUD
import Firebase

class InviteUsersTableViewController: UITableViewController {
  
  @IBOutlet weak var headerView: UIView!
  
  var allUsers: [FUser] = []
  var allUsersGroupped = NSDictionary() as! [String: [FUser]]
  var sectionTitleList: [String] = []
  
  var newMemberIds: [String] = []
  var currentMemberIds: [String] = []
  var group: NSDictionary!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  
    self.title = "Users"
    tableView.tableFooterView = UIView()
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonPressed))
    
    self.navigationItem.rightBarButtonItem?.isEnabled = false
    
    currentMemberIds = group[kMEMBERS] as! [String]
  }
  
  override func viewWillAppear(_ animated: Bool) {
    loadUsers(filter: kCITY)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    ProgressHUD.dismiss()
  }
  
  //MARK: - IBActions
  @IBAction func filterSegmentValueChanged(_ sender: UISegmentedControl) {
  }
  
  @objc func doneButtonPressed() {
    updateGroup(group: group)
  }
  
  //MARK: - Helper functions
  func updateGroup(group: NSDictionary) {
    let tempMembers = currentMemberIds + newMemberIds
    let tempMembersToPush = group[kMEMBERSTOPUSH] as! [String] + newMemberIds
    
    let withValues = [kMEMBERSTOPUSH: tempMembersToPush, kMEMBERS: tempMembers]
    
    Group.updateGroup(groupId: group[kGROUPID] as! String, withValues: withValues)
    
    createRecentsForNewMembers(groupId: group[kGROUPID] as! String, groupName: group[kNAME] as! String, membersToPush: tempMembersToPush, avatar: group[kAVATAR] as! String)
    
    updateExistingRecentWithNewValues(chatRoomId: group[kGROUPID] as! String, members: tempMembers, withValues: withValues)
    
    goToGroupChat(membersToPush: tempMembersToPush, members: tempMembers)
  }
  
  func goToGroupChat(membersToPush: [String], members: [String]){
    let chatVC = ChatViewController()
    
    chatVC.titleName = group[kNAME] as? String
    chatVC.memberIds = members
    chatVC.membersToPush = membersToPush
    
    chatVC.chatRoomId = group[kGROUPID] as? String
    chatVC.isGroup = true
    chatVC.hidesBottomBarWhenPushed = true
    
    self.navigationController?.pushViewController(chatVC, animated: true)
  }
  
  //MARK: - Load Users Functions
  func loadUsers(filter: String) {
    ProgressHUD.show()
    
    var query: Query!
    
    switch filter {
    case kCITY:
      query = reference(.User).whereField(kCITY, isEqualTo: FUser.currentUser()!.city).order(by: kLASTNAME, descending: false)
    case kCOUNTRY:
      query = reference(.User).whereField(kCOUNTRY, isEqualTo: FUser.currentUser()!.country).order(by: kLASTNAME, descending: false)
    default:
      query = reference(.User).order(by: kLASTNAME, descending: false)
    }
    
    query.getDocuments { (snapshot, error) in
      self.allUsers = []
      self.sectionTitleList = []
      self.allUsersGroupped = [:]
      
      if error != nil {
        print(error!.localizedDescription)
        ProgressHUD.dismiss()
        return
      }
      
      guard let snapshot = snapshot else { ProgressHUD.dismiss(); return }
      
      if !snapshot.isEmpty {
        for userDictionary in snapshot.documents {
          let userDictionary = userDictionary.data() as NSDictionary
          let fUser = FUser(_dictionary: userDictionary)
          
          if fUser.objectId != FUser.currentId() {
            self.allUsers.append(fUser)
          }
        }
        
        //split to groups
        self.splitDataIntoSection()
      }
      
      self.tableView.reloadData()
      ProgressHUD.dismiss()
    }
  }
  
  //MARK: - split Data into section
  
  fileprivate func splitDataIntoSection() {
    var sectionTitle = ""
    
    for i in 0 ..< self.allUsers.count {
      let currentUser = self.allUsers[i]
      let firstChar = currentUser.lastname.first
      let firstCharString = "\(firstChar!)"
      
      if firstCharString != sectionTitle {
        sectionTitle = firstCharString
        self.allUsersGroupped[sectionTitle] = []
        
        if !sectionTitleList.contains(sectionTitle) {
          self.sectionTitleList.append(sectionTitle)
        }
        
      }
      self.allUsersGroupped[sectionTitle]?.append(currentUser)
    }
  }
  
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return self.allUsersGroupped.count
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let sectionTitle = self.sectionTitleList[section]
    let users = self.allUsersGroupped[sectionTitle]
    
    return users!.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
    
    var user: FUser
    
    let sectionTitle = self.sectionTitleList[indexPath.section]
    let users = self.allUsersGroupped[sectionTitle]
    user = users![indexPath.row]
    
    cell.delegate = self
    cell.generateCellWith(fUser: user, indexPath: indexPath)
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return sectionTitleList[section]
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    tableView.deselectRow(at: indexPath, animated: true)
    
    let sectionTitle = self.sectionTitleList[indexPath.section]
    let users = self.allUsersGroupped[sectionTitle]
    let selectUser = users![indexPath.row]
    
    if currentMemberIds.contains(selectUser.objectId) {
      ProgressHUD.showError("Already in the group!")
      return
    }
    
    if let cell = tableView.cellForRow(at: indexPath) {
      if cell.accessoryType == .checkmark {
        cell.accessoryType = .none
      }else {
        cell.accessoryType = .checkmark
      }
    }
    
    // add/remove users
    let selected = newMemberIds.contains(selectUser.objectId)
    
    if selected {
      //remove
      let objectIndex = newMemberIds.index(of: selectUser.objectId)
      newMemberIds.remove(at: objectIndex!)
    }else {
      // add to array
      newMemberIds.append(selectUser.objectId)
    }
    
    self.navigationItem.rightBarButtonItem?.isEnabled = newMemberIds.count > 0
  }
  
}

extension InviteUsersTableViewController: UserTableViewCellDelegate {
  func didTapAvatarImage(indexPath: IndexPath) {
    let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileTableViewController
    
    let sectionTitle = self.sectionTitleList[indexPath.section]
    let users = self.allUsersGroupped[sectionTitle]
    let user = users![indexPath.row]
    
    profileVC.user = user
    self.navigationController?.pushViewController(profileVC, animated: true)
  }
  
  
}
