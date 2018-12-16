//
//  EditProfileTableViewController.swift
//  WeiChat
//
//  Created by 刘铭 on 2018/12/2.
//  Copyright © 2018 刘铭. All rights reserved.
//

import UIKit
import ProgressHUD
import ImagePicker

class EditProfileTableViewController: UITableViewController {
  
  @IBOutlet weak var saveButtonOutlet: UIBarButtonItem!
  @IBOutlet weak var avatarImageView: UIImageView!
  @IBOutlet weak var firstNameTextField: UITextField!
  @IBOutlet weak var lastNameTextField: UITextField!
  @IBOutlet weak var emailTextField: UITextField!
  @IBOutlet var avatarTapGestureRecognizer: UITapGestureRecognizer!
  
  var avatarImage: UIImage?
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationItem.largeTitleDisplayMode = .never
    tableView.tableFooterView = UIView()
    
    setupUI()
  }
  
  //MARK: - IBActions
  
  @IBAction func avatarTap(_ sender: Any) {
    let imagePickerController = ImagePickerController()
    imagePickerController.delegate = self
    imagePickerController.imageLimit = 1
    
    present(imagePickerController, animated: true, completion: nil)
  }
  
  
  @IBAction func saveButtonPressed(_ sender: Any) {
    if firstNameTextField.text != "" && lastNameTextField.text != "" && emailTextField.text != "" {
      ProgressHUD.show("Save……")
      
      //block save button
      saveButtonOutlet.isEnabled = false
      
      let fullname = lastNameTextField.text! + " " + firstNameTextField.text!
      var withValues = [kFIRSTNAME: firstNameTextField.text!, kLASTNAME: lastNameTextField.text!, kFULLNAME: fullname]
      
      if avatarImage != nil {
        let avatarData = avatarImage!.jpegData(compressionQuality: 0.7)!
        let avatarString = avatarData.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        
        withValues[kAVATAR] = avatarString
      }
      
      //update current user
      updateCurrentUserInFirestore(withValues: withValues) { (error) in
        if error != nil {
          DispatchQueue.main.async {
            ProgressHUD.showError(error?.localizedDescription)
            print("Couldn't update user \(error!.localizedDescription)")
            self.saveButtonOutlet.isEnabled = true
          }
          return
        }
        
        ProgressHUD.showSuccess("Saved")
        self.saveButtonOutlet.isEnabled = true
        self.navigationController?.popViewController(animated: true)
      }
    }else {
      ProgressHUD.showError("All fields are required!")
    }
  }
  
  
  // MARK: - Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 4
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return ""
  }
  
  //MARK: - setupUI
  func setupUI() {
    let currentUser = FUser.currentUser()!
    avatarImageView.isUserInteractionEnabled = true
    
    firstNameTextField.text = currentUser.firstname
    lastNameTextField.text = currentUser.lastname
    emailTextField.text = currentUser.email
    
    if currentUser.avatar != "" {
      imageFromData(pictureData: currentUser.avatar) { (avatarImage) in
        if avatarImage != nil {
          self.avatarImageView.image = avatarImage!.circleMasked
        }
      }
    }
  }
}

extension EditProfileTableViewController: ImagePickerDelegate {
  func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
    self.dismiss(animated: true, completion: nil)
  }
  
  func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
    if images.count > 0 {
      self.avatarImage = images.first!
      self.avatarImageView.image = avatarImage?.circleMasked
    }
    
    self.dismiss(animated: true, completion: nil)
  }
  
  func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
    self.dismiss(animated: true, completion: nil)
  }
  
  
}
