//
//  BackgroundCollectionViewCell.swift
//  WeiChat
//
//  Created by 刘铭 on 2018/12/1.
//  Copyright © 2018 刘铭. All rights reserved.
//

import UIKit

class BackgroundCollectionViewCell: UICollectionViewCell {
  
  @IBOutlet weak var imageView: UIImageView!
  
  func generateCell(image: UIImage) {
    self.imageView.image = image
  }
  
}
