//
//  PictureCollectionViewCell.swift
//  WeiChat
//
//  Created by 刘铭 on 2018/11/25.
//  Copyright © 2018 刘铭. All rights reserved.
//

import UIKit

class PictureCollectionViewCell: UICollectionViewCell {
    
  @IBOutlet weak var imageView: UIImageView!
  
  func generateCell(image: UIImage) {
    self.imageView.image = image
  }
}
