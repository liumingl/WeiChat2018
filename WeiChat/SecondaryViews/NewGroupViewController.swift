//
//  NewGroupViewController.swift
//  WeiChat
//
//  Created by 刘铭 on 2018/12/8.
//  Copyright © 2018 刘铭. All rights reserved.
//

import UIKit
import ProgressHUD
import ImagePicker

class NewGroupViewController: UIViewController {
  
  @IBOutlet weak var groupIconImageView: UIImageView!
  @IBOutlet weak var avatarButtonOutlet: UIButton!
  
  @IBOutlet weak var groupSubjectTextField: UITextField!
  @IBOutlet weak var participantsLabel: UILabel!
  @IBOutlet weak var collectionView: UICollectionView!
  
  @IBOutlet var iconTapGesture: UITapGestureRecognizer!
  
  
  var memberIds: [String] = []
  var allMembers: [FUser] = []
  var groupIcon: UIImage?
  
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.navigationItem.largeTitleDisplayMode = .never
    groupIconImageView.isUserInteractionEnabled = true
    groupIconImageView.addGestureRecognizer(iconTapGesture)
    
    updateParticipantsLabel()
  }
  
  //MARK: - Helper functions
  func updateParticipantsLabel() {
    participantsLabel.text = "PARTICIPANTS: \(allMembers.count)"
    
    self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(self.createButtonPressed))
    
    self.navigationItem.rightBarButtonItem?.isEnabled = allMembers.count > 0
  }
  
  func showIconOptions() {
    let optionMenu = UIAlertController(title: "Choose Group Icon", message: nil, preferredStyle: .actionSheet)
    
    let takePhotoAction = UIAlertAction(title: "Take/Choose Photo", style: .default) { (alert) in
      let imagePickerController = ImagePickerController()
      imagePickerController.delegate = self
      imagePickerController.imageLimit = 1
      
      self.present(imagePickerController, animated: true, completion: nil)
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    
    if groupIcon != nil {
      let resetAction = UIAlertAction(title: "Reset", style: .default) { (alert) in
        self.groupIcon = nil
        self.groupIconImageView.image = UIImage(named: "cameraImage")
        self.avatarButtonOutlet.isHidden = true
      }
      optionMenu.addAction(resetAction)
    }
    
    optionMenu.addAction(takePhotoAction)
    optionMenu.addAction(cancelAction)
    
    self.present(optionMenu, animated: true, completion: nil)
  }
  
  //MARK: - IBAction
  @objc func createButtonPressed() {
    if groupSubjectTextField.text != "" {
      memberIds.append(FUser.currentId())
      
      let avatarData = UIImage(named: "groupIcon")?.jpegData(compressionQuality: 0.7)
      var avatar = avatarData?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
      
      if groupIcon != nil {
        let avatarData = groupIcon!.jpegData(compressionQuality: 0.7)
        avatar = avatarData?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
      }
      
      let groupId = UUID().uuidString
      
      // Create group
      let group = Group(groupId: groupId, subject: groupSubjectTextField.text!, ownerId: FUser.currentId(), members: memberIds, avatar: avatar!)
      
      group.saveGroup(group: group.groupDictionary)
      
      // create group recent
      startGroupChat(group: group)
      
      // go to chat view
      let chatVC = ChatViewController()
      chatVC.titleName = group.groupDictionary[kNAME] as? String
      
      chatVC.memberIds = group.groupDictionary[kMEMBERS] as? [String]
      chatVC.membersToPush = group.groupDictionary[kMEMBERSTOPUSH] as? [String]
      chatVC.chatRoomId = groupId
      chatVC.isGroup = true
      chatVC.hidesBottomBarWhenPushed = true
      self.navigationController?.pushViewController(chatVC, animated: true)
      
    }else {
      ProgressHUD.showError("Subject is required!")
    }
  }
  
  @IBAction func groupIconTapped(_ sender: Any) {
    showIconOptions()
  }
  
  @IBAction func editIconButtonPressed(_ sender: Any) {
    showIconOptions()
  }
  
}

extension NewGroupViewController: UICollectionViewDataSource, UICollectionViewDelegate{
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return allMembers.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! GroupMemberCollectionViewCell
    
    cell.delegate = self
    cell.generateCell(user: allMembers[indexPath.row], indexPath: indexPath)
    
    return cell
  }
  
  
}

//MARK: - Group Member Collection View Cell Delegate
extension NewGroupViewController: GroupMemberCollectionViewCellDelegate {
  func didClickDeleteButton(indexPath: IndexPath) {
    allMembers.remove(at: indexPath.row)
    memberIds.remove(at: indexPath.row)
    
    collectionView.reloadData()
  }
}


extension NewGroupViewController: ImagePickerDelegate {
  func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
    self.dismiss(animated: true, completion: nil)
  }
  
  func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
    if images.count > 0 {
      groupIcon = images.first!
      self.groupIconImageView.image = groupIcon?.circleMasked
    }
    
    self.dismiss(animated: true, completion: nil)
  }
  
  func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
    self.dismiss(animated: true, completion: nil)
  }
}
