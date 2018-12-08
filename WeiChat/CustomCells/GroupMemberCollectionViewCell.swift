//
//  GroupMemberCollectionViewCell.swift
//  WeiChat
//
//  Created by 刘铭 on 2018/12/8.
//  Copyright © 2018 刘铭. All rights reserved.
//

import UIKit

protocol GroupMemberCollectionViewCellDelegate {
  func didClickDeleteButton(indexPath: IndexPath)
}

class GroupMemberCollectionViewCell: UICollectionViewCell {
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var avatarImageView: UIImageView!
  
  var indexPath: IndexPath!
  var delegate: GroupMemberCollectionViewCellDelegate?
  
  
  @IBAction func deleteButtonPressed(_ sender: Any) {
    delegate?.didClickDeleteButton(indexPath: indexPath)
  }
  
  func generateCell(user: FUser, indexPath: IndexPath) {
    self.indexPath = indexPath
    
    nameLabel.text = user.fullname
    if user.avatar != "" {
      imageFromData(pictureData: user.avatar) { (avatarImage) in
        if avatarImage != nil {
          self.avatarImageView.image = avatarImage?.circleMasked
        }
      }
    }
  }
}
