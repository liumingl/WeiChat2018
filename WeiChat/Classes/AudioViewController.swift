//
//  AudioViewController.swift
//  WeiChat
//
//  Created by 刘铭 on 2018/11/23.
//  Copyright © 2018 刘铭. All rights reserved.
//

import Foundation
import IQAudioRecorderController

class AudioViewController {
  var delegate: IQAudioRecorderViewControllerDelegate
  
  init(delegate_: IQAudioRecorderViewControllerDelegate) {
    delegate = delegate_
  }
  
  func presentAudioRecorder(target: UIViewController) {
    let controller = IQAudioRecorderViewController()
    controller.title = "Record"
    controller.delegate = delegate
    controller.maximumRecordDuration = kAUDIOMAXDURATION
    controller.allowCropping = true
    
    target.presentBlurredAudioRecorderViewControllerAnimated(controller)
  }
}
