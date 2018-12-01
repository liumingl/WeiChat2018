//
//  BackgroundCollectionViewController.swift
//  WeiChat
//
//  Created by 刘铭 on 2018/12/1.
//  Copyright © 2018 刘铭. All rights reserved.
//

import UIKit
import ProgressHUD

class BackgroundCollectionViewController: UICollectionViewController {
  
  var backgrounds: [UIImage] = []
  let userDefaults = UserDefaults.standard
  
  private let imageNamesArray = ["bg0","bg1","bg2","bg3","bg4","bg5","bg6","bg7","bg8","bg9","bg10","bg11"]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let resetButton = UIBarButtonItem(title: "Reset", style: .plain, target: self, action: #selector(self.resetToDefault))
    self.navigationItem.rightBarButtonItem = resetButton
    
    self.navigationItem.largeTitleDisplayMode = .never
    setupImageArray()
    
  }
  
  //MARK: - IBActions
  @objc func resetToDefault() {
    userDefaults.removeObject(forKey: kBACKGROUBNDIMAGE)
    userDefaults.synchronize()
    ProgressHUD.showSuccess("Set!")
  }
  
  // MARK: UICollectionViewDataSource
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return backgrounds.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! BackgroundCollectionViewCell
    
    cell.generateCell(image: backgrounds[indexPath.row])
    
    return cell
  }
  
  // MARK: UICollectionViewDelegate
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    userDefaults.set(imageNamesArray[indexPath.row], forKey: kBACKGROUBNDIMAGE)
    userDefaults.synchronize()
    ProgressHUD.showSuccess("Set!")
  }
  
  //MARK: - Helpers
  func setupImageArray() {
    for imageName in imageNamesArray {
      let image = UIImage(named: imageName)
      if image != nil {
        backgrounds.append(image!)
      }
    }
  }
  
}
