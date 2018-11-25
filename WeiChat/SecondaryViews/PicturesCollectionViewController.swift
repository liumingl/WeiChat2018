//
//  PicturesCollectionViewController.swift
//  WeiChat
//
//  Created by 刘铭 on 2018/11/25.
//  Copyright © 2018 刘铭. All rights reserved.
//

import UIKit
import IDMPhotoBrowser

private let reuseIdentifier = "Cell"

class PicturesCollectionViewController: UICollectionViewController {
  
  var allImages: [UIImage] = []
  var allImageLinks: [String] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.navigationItem.title = "All Pictures"
    
    if allImageLinks.count > 0 {
      downloadImages()
    }
  }
  
  //MARK: - Download Images
  func downloadImages() {
    for imageLink in allImageLinks {
      downloadImage(imageUrl: imageLink) { (image) in
        if image != nil {
          self.allImages.append(image!)
          self.collectionView.reloadData()
        }
      }
    }
  }
  
  // MARK: UICollectionViewDataSource
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return allImages.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PictureCollectionViewCell
    
    cell.generateCell(image: allImages[indexPath.row])
    
    return cell
  }
  
  // MARK: UICollectionViewDelegate
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let photos = IDMPhoto.photos(withImages: allImages)
    
    let browser = IDMPhotoBrowser(photos: photos)
    browser?.displayDoneButton = false
    browser?.setInitialPageIndex(UInt(indexPath.row))
    
    present(browser!, animated: true, completion: nil)
  }
  
}
