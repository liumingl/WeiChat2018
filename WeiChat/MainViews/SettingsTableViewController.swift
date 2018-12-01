//
//  SettingsTableViewController.swift
//  WeiChat
//
//  Created by 刘铭 on 2018/11/1.
//  Copyright © 2018 刘铭. All rights reserved.
//

import UIKit
import ProgressHUD

class SettingsTableViewController: UITableViewController {
  
  @IBOutlet weak var avatarImageView: UIImageView!
  @IBOutlet weak var fullNameLabel: UILabel!
  @IBOutlet weak var deleteButtonOutlet: UIButton!
  @IBOutlet weak var showAvatarStatusSwitch: UISwitch!
  @IBOutlet weak var versionLabel: UILabel!
  
  var avatarSwitchStatus = false
  
  let userDefaults = UserDefaults.standard
  var firstLoad: Bool?

  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationController?.navigationBar.prefersLargeTitles = true
    
    tableView.tableFooterView = UIView()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    if FUser.currentUser() != nil {
      setupUI()
    }
    
    loadUserDefaults()
  }
  
  //MARK: - save User Defaults
  func saveUserDefaults() {
    userDefaults.set(avatarSwitchStatus, forKey: kSHOWAVATAR)
    userDefaults.synchronize()
  }
  
  func loadUserDefaults() {
    firstLoad = userDefaults.bool(forKey: kFIRSTRUN)
    
    if !firstLoad! {
      userDefaults.set(true, forKey: kFIRSTRUN)
      userDefaults.set(avatarSwitchStatus, forKey: kSHOWAVATAR)
      userDefaults.synchronize()
    }
    
    avatarSwitchStatus = userDefaults.bool(forKey: kSHOWAVATAR)
    showAvatarStatusSwitch.isOn = avatarSwitchStatus
  }
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 4
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 1 {
      return 5
    }
    return 2
  }
  
  //MARK: - Table View Delegate
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return ""
  }
  
  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return UIView()
  }
  
  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    if section == 0 {
      return 0
    }else {
      return 30
    }
  }
  
  //MARK: - IBAction
  @IBAction func showAvatarSwitchValueChanged(_ sender: UISwitch) {
    avatarSwitchStatus = sender.isOn

    saveUserDefaults()
  }
  
  @IBAction func cleanCacheButtonPressed(_ sender: Any) {
    do {
      let files = try FileManager.default.contentsOfDirectory(atPath: getDocumentsURL().path)
      
      for file in files {
        try FileManager.default.removeItem(atPath: getDocumentsURL().path + "/" + file)
      }
      ProgressHUD.showSuccess("Cache Cleaned!")
      
    }catch {
      ProgressHUD.showError("Couldn't clean media files.")
    }
  }
  
  @IBAction func tellAFriendButtonPressed(_ sender: Any) {
    let text = "Hey! Let's chat on WeiChat \(kAPPURL)"
    
    let objectsToShare: [Any] = [text]
    let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
    
    activityViewController.popoverPresentationController?.sourceView = self.view
    
    activityViewController.setValue("Let's chat on WeiChat", forKey: "subject")
    self.present(activityViewController, animated: true, completion: nil)
    
  }
  
  @IBAction func deleteAccountButtonPressed(_ sender: Any) {
    let optionMenu = UIAlertController(title: "Delete Account", message: "Are you sure you want to delete this account?", preferredStyle: .actionSheet)
    
    let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { (alert) in
      // delete the user
      self.deleteUser()
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    
    optionMenu.addAction(deleteAction)
    optionMenu.addAction(cancelAction)
    
    self.present(optionMenu, animated: true, completion: nil)
    
  }
  
  
  @IBAction func logOutButtonPressed(_ sender: Any) {
    FUser.logOutCurrentUser { (success) in
      if success {
        self.showLoginView()
      }
    }
  }
  
  func showLoginView() {
    let welcomeView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "welcomeView")
    
    self.present(welcomeView, animated: true, completion: nil)
  }
  
  //MARK: - Delete User
  func deleteUser() {
    //delete locally
    userDefaults.removeObject(forKey: kPUSHID)
    userDefaults.removeObject(forKey: kCURRENTUSER)
    userDefaults.synchronize()
    
    //delete from firebase
    reference(.User).document(FUser.currentId()).delete()
    
    FUser.deleteUser { (error) in
      if error != nil {
        DispatchQueue.main.async {
          ProgressHUD.showError("Couldn't delete user")
          return
        }
      }
      
      self.showLoginView()
    }
    
  }
  
  
  //MARK: - setupUI
  func setupUI() {
    let currentUser = FUser.currentUser()!
    fullNameLabel.text = currentUser.fullname
    
    if currentUser.avatar != "" {
      imageFromData(pictureData: currentUser.avatar) { (avatarImage) in
        if avatarImage != nil {
          self.avatarImageView.image = avatarImage!.circleMasked
        }
      }
    }
    
    // set app version
    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
      versionLabel.text = version
    }
    
    
  }
  
  
}
