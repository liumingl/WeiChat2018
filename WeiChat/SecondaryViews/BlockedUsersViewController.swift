//
//  BlockedUsersViewController.swift
//  WeiChat
//
//  Created by 刘铭 on 2018/12/1.
//  Copyright © 2018 刘铭. All rights reserved.
//

import UIKit
import ProgressHUD

class BlockedUsersViewController: UIViewController {
  
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var notificationLabel: UILabel!
  
  var blockedUserArray: [FUser] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.tableFooterView = UIView()
    loadUsers()
    navigationItem.largeTitleDisplayMode = .never
  }
  
  //MARK: - load blocked users
  func loadUsers() {
    if FUser.currentUser()!.blockedUsers.count > 0 {
      ProgressHUD.show()
      getUsersFromFirestore(withIds: FUser.currentUser()!.blockedUsers) { (allBlockUsers) in
        ProgressHUD.dismiss()
        self.blockedUserArray = allBlockUsers
        self.tableView.reloadData()
      }
    }
  }
  
}

extension BlockedUsersViewController: UITableViewDelegate, UITableViewDataSource{
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    notificationLabel.isHidden = blockedUserArray.count != 0
    
    return blockedUserArray.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
    
    cell.delegate = self
    cell.generateCellWith(fUser: blockedUserArray[indexPath.row], indexPath: indexPath)
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
  }
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
    return "Unblock"
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    var tempBlockUsers = FUser.currentUser()!.blockedUsers
    let userIdToUnblock = blockedUserArray[indexPath.row].objectId
    
    tempBlockUsers.remove(at: tempBlockUsers.index(of:userIdToUnblock)!)
    
    blockedUserArray.remove(at: indexPath.row)
    
    updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID: tempBlockUsers]) { (error) in
      if error != nil {
        ProgressHUD.showError(error!.localizedDescription)
      }
      self.tableView.reloadData()
    }
  }
  
}

extension BlockedUsersViewController: UserTableViewCellDelegate {
  func didTapAvatarImage(indexPath: IndexPath) {
    let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileTableViewController
    
    profileVC.user = blockedUserArray[indexPath.row]
    self.navigationController?.pushViewController(profileVC, animated: true)
  }
  
  
}
