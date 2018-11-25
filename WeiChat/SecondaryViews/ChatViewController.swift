//
//  ChatViewController.swift
//  WeiChat
//
//  Created by 刘铭 on 2018/11/13.
//  Copyright © 2018 刘铭. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Firebase
import FirebaseStorage
import IDMPhotoBrowser
import AVFoundation
import AVKit
import IQAudioRecorderController
import ProgressHUD

class ChatViewController: JSQMessagesViewController {
  
  var outgoingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
  var incomingBubble = JSQMessagesBubbleImageFactory()?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
  
  var chatRoomId: String!
  var memberIds: [String]!
  var membersToPush: [String]!
  var titleName: String!
  
  var legitTypes = [kAUDIO, kVIDEO, kTEXT, kLOCATION, kPICTURE]
  
  var messages: [JSQMessage] = []
  var objectMessages: [NSDictionary] = []
  var loadedMessages: [NSDictionary] = []
  var allPictureMessages: [String] = []
  
  var initialLoadComplete = false
  
  var maxMessageNumber = 0
  var minMessageNumber = 0
  
  var loadOld = false
  var loadedMessageCount = 0
  
  var newChatListener: ListenerRegistration?
  var typingListener: ListenerRegistration?
  var updatedChatListener: ListenerRegistration?
  
  var typingCounter = 0
  
  let appDelegate = UIApplication.shared.delegate as! AppDelegate
  
  var jsqAvatarDictionary: NSMutableDictionary?
  var avatarImageDictionary: NSMutableDictionary?
  var showAvatars = true
  var firstLoad: Bool?
  
  //MARK: Custom Headers
  
  var withUsers: [FUser] = []
  
  var isGroup: Bool?
  var group: NSDictionary?
  
  let leftBarButtonView: UIView = {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
    return view
  }()
  
  let avatarButton: UIButton = {
    let button = UIButton(frame: CGRect(x: 0, y: 10, width: 25, height: 25))
    return button
  }()
  
  let titleLabel: UILabel = {
    let title = UILabel(frame: CGRect(x: 30, y: 10, width: 140, height: 15))
    title.textAlignment = .left
    title.font = UIFont(name: title.font.fontName, size: 14)
    return title
  }()
  
  let subTitle: UILabel = {
    let title = UILabel(frame: CGRect(x: 30, y: 25, width: 140, height: 15))
    title.textAlignment = .left
    title.font = UIFont(name: title.font.fontName, size: 10)
    return title
  }()
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    createTypingObserver()
    
    self.senderId = FUser.currentId()
    self.senderDisplayName = FUser.currentUser()?.fullname
    
    //custom send button
    self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
    self.inputToolbar.contentView.rightBarButtonItem.setTitle("", for: .normal)
    
    navigationItem.largeTitleDisplayMode = .never
    self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(self.backAction))]
    
    collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
    collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
    
    jsqAvatarDictionary = [:]
    
    setCustomTitle()
    
    loadMessages()
    
  }
  
  override func viewWillAppear(_ animated: Bool) {
    clearRecentCounter(chatRoomId: chatRoomId)
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    clearRecentCounter(chatRoomId: chatRoomId)
  }
  
  @objc func backAction() {
    clearRecentCounter(chatRoomId: chatRoomId)
    
    removeListener()
    self.navigationController?.popViewController(animated: true)
  }
  
}

extension ChatViewController {
  override func didPressAccessoryButton(_ sender: UIButton!) {
    
    let camera = Camera(delegate_: self)
    
    let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    
    let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { (action) in
      print("Camera")
    }
    
    let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { (action) in
      camera.PresentPhotoLibrary(target: self, canEdit: false)
    }
    
    let shareVideo = UIAlertAction(title: "Share Video", style: .default) { (action) in
      camera.PresentVideoLibrary(target: self, canEdit: false)
    }
    
    let shareLocation = UIAlertAction(title: "Share Location", style: .default) { (action) in
      if self.haveAccessToUserLocation() {
        self.sendMessage(text: nil, date: Date(), picture: nil, location: kLOCATION, video: nil, audio: nil)
      }
    }
    
    let cancel = UIAlertAction(title: "Cancel", style: .cancel)
    
    takePhotoOrVideo.setValue(UIImage(named: "camera"), forKey: "image")
    sharePhoto.setValue(UIImage(named: "picture"), forKey: "image")
    shareVideo.setValue(UIImage(named: "video"), forKey: "image")
    shareLocation.setValue(UIImage(named: "location"), forKey: "image")
    
    optionMenu.addAction(takePhotoOrVideo)
    optionMenu.addAction(sharePhoto)
    optionMenu.addAction(shareVideo)
    optionMenu.addAction(shareLocation)
    optionMenu.addAction(cancel)
    
    self.present(optionMenu, animated: true, completion: nil)
  }
  
  override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
    
    if text != "" {
      sendMessage(text: text, date: date, picture: nil, location: nil, video: nil, audio: nil)
      updateSendButton(isSend: false)
      
    }else {
      // Audio message
      let audioVC = AudioViewController(delegate_: self)
      audioVC.presentAudioRecorder(target: self)
    }
  }
  
  override func textViewDidChange(_ textView: UITextView) {
    if textView.text != "" {
      updateSendButton(isSend: true)
    }else {
      updateSendButton(isSend: false)
    }
  }
  
  //MARK: - Send Message function
  func sendMessage(text: String?, date: Date, picture: UIImage?, location: String?, video: NSURL?, audio: String?) {
    
    var outgoingMessage: OutgoingMessages?
    let currentUser = FUser.currentUser()!
    
    // text message
    if let text = text {
      outgoingMessage = OutgoingMessages(message: text, senderId: currentUser.objectId, senderName: currentUser.fullname, date: date, status: kDELIVERED, type: kTEXT)
    }
    
    // picture message
    if let pic = picture {
      uploadImage(image: pic, chatRoomId: chatRoomId, view: self.navigationController!.view) { (imageLink) in
        if imageLink != nil {
          let text = "[\(kPICTURE)]"
          outgoingMessage = OutgoingMessages(message: text, pictureLink: imageLink!, senderId: currentUser.objectId, senderName: currentUser.fullname, date: date, status: kDELIVERED, type: kPICTURE)
          
          JSQSystemSoundPlayer.jsq_playMessageSentSound()
          self.finishSendingMessage()
          outgoingMessage?.sendMessage(chatRoomId: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, memberToPush: self.membersToPush)
        }
      }
      return
    }
    
    // send video
    if let video = video {
      let videoData = NSData(contentsOfFile: video.path!)
      let thumbNail = videoThumbnail(video: video)
      let dataThumbnail = thumbNail.jpegData(compressionQuality: 0.7)! as NSData
      
      uploadVideo(video: videoData!, chatRoomId: chatRoomId, view: self.navigationController!.view) { (videoLink) in
        if videoLink != nil {
          let text = "[\(kVIDEO)]"
          outgoingMessage = OutgoingMessages(message: text, video: videoLink!, thumbNail: dataThumbnail, senderId: currentUser.objectId, senderName: currentUser.fullname, date: date, status: kDELIVERED, type: kVIDEO)
          
          JSQSystemSoundPlayer.jsq_playMessageSentSound()
          self.finishSendingMessage()
          outgoingMessage?.sendMessage(chatRoomId: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, memberToPush: self.membersToPush)
        }
      }
      
      return
    }
    
    // send audio
    if let audioPath = audio {
      uploadAudio(audioPath: audioPath, chatRoomId: chatRoomId, view: self.navigationController!.view) { (audioLink) in
        if audioLink != nil {
          let text = "[\(kAUDIO)]"
          outgoingMessage = OutgoingMessages(message: text, audio: audioLink!, senderId: currentUser.objectId, senderName: currentUser.fullname, date: date, status: kDELIVERED, type: kAUDIO)
          
          JSQSystemSoundPlayer.jsq_playMessageSentSound()
          self.finishSendingMessage()
          outgoingMessage?.sendMessage(chatRoomId: self.chatRoomId, messageDictionary: outgoingMessage!.messageDictionary, memberIds: self.memberIds, memberToPush: self.membersToPush)
        }
      }
      return
    }
    
    // send location message
    if location != nil {
      print("send location")
      let lat: NSNumber = NSNumber(value: appDelegate.coordinates!.latitude)
      let long: NSNumber = NSNumber(value: appDelegate.coordinates!.longitude)
      
      let text = "[\(kLOCATION)]"
      outgoingMessage = OutgoingMessages(message: text, latitude: lat, longitude: long, senderId: currentUser.objectId, senderName: currentUser.fullname, date: date, status: kDELIVERED, type: kLOCATION)
    }
    
    outgoingMessage!.sendMessage(chatRoomId: chatRoomId!, messageDictionary: outgoingMessage!.messageDictionary, memberIds: memberIds!, memberToPush: membersToPush!)
    
    JSQSystemSoundPlayer.jsq_playMessageSentSound()
    self.finishSendingMessage()
  }
  
  
  //MARK: - Custom Send Button
  func updateSendButton(isSend: Bool) {
    if isSend {
      self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "send"), for: .normal)
    }else {
      self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
    }
  }
  
  //MARK: - Load Messages
  func loadMessages() {
    // to update message status
    updatedChatListener = reference(.Message).document(FUser.currentId()).collection(chatRoomId).addSnapshotListener({ (snapshot, error) in
      guard let snapshot = snapshot else { return }
      
      if !snapshot.isEmpty {
        snapshot.documentChanges.forEach({ (diff) in
          if diff.type == .modified {
            // update local message
            self.updateMessage(messageDictionary: diff.document.data() as NSDictionary)
          }
        })
      }
    })
    
    
    //get last 11 messages
    reference(.Message).document(FUser.currentId()).collection(chatRoomId).order(by: kDATE, descending: true).limit(to: 11).getDocuments { (snapshot, error) in
      guard let snapshot = snapshot else {
        //initial loading is done
        self.initialLoadComplete = true
        
        //listen for new chat
        self.listenForNewChats()
        
        return
      }
      
      let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
      
      //remove bad message
      self.loadedMessages = self.removeBadMessages(allMessages: sorted)
      
      self.initialLoadComplete = true
      
      //insert messages
      self.insertMessages()
      self.finishReceivingMessage(animated: true)
      print("We have \(self.messages.count) messages loaded.")
      
      //get picture message
      self.getPictureMessages()
      
      //get old message in Background
      self.getOldMessagesInBackground()
      
      //start listening for new chats
      self.listenForNewChats()
    }
  }
  
  //MARK: - get old messages in background
  
  func getOldMessagesInBackground() {
    if loadedMessages.count > 10 {
      let firstMessageDate = loadedMessages.first![kDATE] as! String
      reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isLessThan: firstMessageDate).getDocuments { (snapshot, error) in
        guard let snapshot = snapshot else { return }
        
        let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
        
        self.loadedMessages = self.removeBadMessages(allMessages: sorted) + self.loadedMessages
        
        // get picture message
        self.getPictureMessages()
        
        self.maxMessageNumber = self.loadedMessages.count - self.loadedMessageCount - 1
        self.minMessageNumber = self.maxMessageNumber - kNUMBEROFMESSAGES
      }
    }
  }
  
  //MARK: - Load More Messages
  func loadMoreMessages(maxNumber: Int, minNumber: Int) {
    if loadOld {
      maxMessageNumber = minNumber - 1
      minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
    }
    
    if minMessageNumber < 0 {
      minMessageNumber = 0
    }
    
    for i in (minMessageNumber ... maxMessageNumber).reversed() {
      let messageDictionary = loadedMessages[i]
      insertNewMessage(messageDictionary: messageDictionary)
      loadedMessageCount += 1
    }
    
    loadOld = true
    self.showLoadEarlierMessagesHeader = (loadedMessages.count != loadedMessageCount)
    
  }
  
  func insertNewMessage(messageDictionary: NSDictionary) {
    let incomingMessage = IncomingMessage(collectionView_: self.collectionView)
    
    let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
    objectMessages.insert(messageDictionary, at: 0)
    messages.insert(message!, at: 0)
  }
  
  //MARK: - Location access
  func haveAccessToUserLocation() -> Bool {
    if appDelegate.locationManager != nil {
      return true
    }else {
      ProgressHUD.showError("Please give access location in Settings")
      return false
    }
  }
  
  //MARK: - Typing Indicator
  func createTypingObserver() {
    typingListener = reference(.Typing).document(chatRoomId).addSnapshotListener({ (snapshot, error) in
      guard let snapshot = snapshot else { return }
      
      if snapshot.exists {
        for data in snapshot.data()! {
          if data.key != FUser.currentId() {
            let typing = data.value as! Bool
            self.showTypingIndicator = typing
            if typing {
              self.scrollToBottom(animated: true)
            }
          }
        }
      }else {
        reference(.Typing).document(self.chatRoomId).setData([FUser.currentId(): false])
      }
      
    })
  }
  
  func typingCounterStart() {
    typingCounter += 1
    typingCounterSave(typing: true)
    self.perform(#selector(self.typingCounterStop), with: nil, afterDelay: 2.0)
  }
  
  @objc func typingCounterStop() {
    typingCounter -= 1
    if typingCounter == 0 {
      typingCounterSave(typing: false)
    }
  }
  
  func typingCounterSave(typing: Bool) {
    reference(.Typing).document(chatRoomId).updateData([FUser.currentId(): typing])
  }
  
  //MARK: - Helper functions
  func updatePushMembers(recent: NSDictionary, mute: Bool) {
    var membersToPush = recent[kMEMBERSTOPUSH] as! [String]
    
    if mute {
      let index = membersToPush.index(of: FUser.currentId())!
      membersToPush.remove(at: index)
    }else {
      membersToPush.append(FUser.currentId())
    }
    
    //Save the changes
    updateExistingRecentWithNewValues(chatRoomId: chatRoomId, members: recent[kMEMBERS] as! [String], withValues: [kMEMBERSTOPUSH: membersToPush])
  }
  
  func addNewPictureMessageLink(link: String) {
    allPictureMessages.append(link)
  }
  
  func getPictureMessages() {
    allPictureMessages = []
    
    for message in loadedMessages {
      if message[kTYPE] as! String == kPICTURE {
        allPictureMessages.append(message[kPICTURE] as! String)
      }
    }
  }
  
  func presentUserProfile(forUser: FUser) {
    let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileTableViewController
    
    profileVC.user = forUser
    self.navigationController?.pushViewController(profileVC, animated: true)
  }
  
  func getAvatarImages() {
    if showAvatars {
      collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 30, height: 30)
      
      collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 30, height: 30)
      
      // get current user avatar
      avatarImageFrom(fUser: FUser.currentUser()!)
      for user in withUsers {
        avatarImageFrom(fUser: user)
      }
    }
  }
  
  func avatarImageFrom(fUser: FUser) {
    if fUser.avatar != "" {
      dataImageFromString(pictureString: fUser.avatar) { (imageData) in
        if imageData == nil { return }
        
        if self.avatarImageDictionary != nil {
          // update avatar if we had one.
          self.avatarImageDictionary!.removeObject(forKey: fUser.objectId)
          self.avatarImageDictionary?.setObject(imageData!, forKey: fUser.objectId as NSCopying)
        }else {
          self.avatarImageDictionary = [fUser.objectId: imageData!]
        }
        
        //Create JSQAvatar
        self.createJSQAvatars(avatarDictionary: self.avatarImageDictionary!)
        
      }
    }
  }
  
  func createJSQAvatars(avatarDictionary: NSMutableDictionary?) {
    let defaultAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)
    
    if avatarDictionary != nil {
      for userId in memberIds {
        if let avatarImageData = avatarDictionary![userId] {
          let jsqAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(data: avatarImageData as! Data), diameter: 70)
          
          self.jsqAvatarDictionary!.setValue(jsqAvatar, forKey: userId)
        }else {
          self.jsqAvatarDictionary!.setValue(defaultAvatar, forKey: userId)
        }
      }
      self.collectionView.reloadData()
    }
  }
  
  func removeListener() {
    if typingListener != nil {
      typingListener!.remove()
    }
    
    if newChatListener != nil {
      newChatListener!.remove()
    }
    
    if updatedChatListener != nil {
      updatedChatListener!.remove()
    }
  }
  
  
  func setCustomTitle() {
    leftBarButtonView.addSubview(avatarButton)
    leftBarButtonView.addSubview(titleLabel)
    leftBarButtonView.addSubview(subTitle)
    
    let infoButton = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(self.infoButtonPressed))
    
    self.navigationItem.rightBarButtonItem = infoButton
    
    let leftBarButtonItem = UIBarButtonItem(customView: leftBarButtonView)
    self.navigationItem.leftBarButtonItems?.append(leftBarButtonItem)
    
    if isGroup! {
      avatarButton.addTarget(self, action: #selector(self.showGroup), for: .touchUpInside)
    }else {
      avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
    }
    
    getUsersFromFirestore(withIds: memberIds) { (withUsers) in
      self.withUsers = withUsers
      
      if !self.isGroup! {
        self.setUIForSingleChat()
      }
    }
    
    //get avatars
    self.getAvatarImages()
    
  }
  
  func setUIForSingleChat() {
    let withUser = withUsers.first!
    imageFromData(pictureData: withUser.avatar) { (image) in
      if image != nil {
        avatarButton.setImage(image!.circleMasked, for: .normal)
      }
    }
    
    titleLabel.text = withUser.fullname
    if withUser.isOnline {
      subTitle.text = "Online"
    }else {
      subTitle.text = "Offline"
    }
    
    avatarButton.addTarget(self, action: #selector(showUserProfile), for: .touchUpInside)
  }
  
  @objc func infoButtonPressed() {
    let mediaVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mediaView") as! PicturesCollectionViewController
    
    mediaVC.allImageLinks = allPictureMessages
    
    self.navigationController?.pushViewController(mediaVC, animated: true)
  }
  
  @objc func showGroup() {
    print("show Group")
  }
  
  @objc func showUserProfile() {
    let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileTableViewController
    
    profileVC.user = withUsers.first!
    self.navigationController?.pushViewController(profileVC, animated: true)
  }
  
  
  func listenForNewChats() {
    var lastMessageDate = "0"
    if loadedMessages.count > 0 {
      lastMessageDate = loadedMessages.last![kDATE] as! String
    }
    
    newChatListener = reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isGreaterThan: lastMessageDate).addSnapshotListener({ (snapshot, error) in
      guard let snapshot = snapshot else { return }
      
      if !snapshot.isEmpty {
        for diff in snapshot.documentChanges {
          if diff.type == .added {
            let item = diff.document.data() as NSDictionary
            if let type = item[kTYPE] {
              if self.legitTypes.contains(type as! String) {
                //this is for picture message
                if (type as! String) == kPICTURE {
                  // add to pic
                  self.addNewPictureMessageLink(link: item[kPICTURE] as! String)
                }
                
                if self.insertInitialLoadMessages(messageDictionary: item) {
                  JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                }
                self.finishReceivingMessage()
              }
            }
          }
        }
      }
    })
    
  }
  
  func readTimeFrom(dateString: String) -> String {
    let date = dateFormatter().date(from: dateString)
    let currentDateFormat = dateFormatter()
    currentDateFormat.dateFormat = "HH:mm"
    return currentDateFormat.string(from: date!)
  }
  
  func removeBadMessages(allMessages: [NSDictionary]) -> [NSDictionary] {
    var tempMessages = allMessages
    
    for message in tempMessages {
      if message[kTYPE] != nil {
        if !self.legitTypes.contains(message[kTYPE] as! String) {
          //remove the message
          tempMessages.remove(at: tempMessages.index(of: message)!)
        }
      }else {
        tempMessages.remove(at: tempMessages.index(of: message)!)
      }
    }
    
    return tempMessages
  }
  
  func insertMessages() {
    maxMessageNumber = loadedMessages.count - loadedMessageCount
    minMessageNumber = maxMessageNumber - kNUMBEROFMESSAGES
    
    if minMessageNumber < 0 {
      minMessageNumber = 0
    }
    
    for i in minMessageNumber ..< maxMessageNumber {
      let messageDictionary = loadedMessages[i]
      
      //insert message
      insertInitialLoadMessages(messageDictionary: messageDictionary)
      loadedMessageCount += 1
      
      
      
    }
    
    self.showLoadEarlierMessagesHeader = (loadedMessageCount != loadedMessages.count)
  }
  
  func insertInitialLoadMessages(messageDictionary: NSDictionary) -> Bool {
    let incomingMessage = IncomingMessage(collectionView_: self.collectionView)
    
    //check if incoming
    if (messageDictionary[kSENDERID] as! String) != FUser.currentId() {
      //update message status
      OutgoingMessages.updateMessage(withId: messageDictionary[kMESSAGEID] as! String, chatRoomId: chatRoomId, memberIds: memberIds)
      
    }
    
    let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
    
    if message != nil {
      objectMessages.append(messageDictionary)
      messages.append(message!)
    }
    
    return isIncoming(messageDictionary: messageDictionary)
  }
  
  func updateMessage(messageDictionary: NSDictionary) {
    for index in 0 ..< objectMessages.count {
      let temp = objectMessages[index]
      if messageDictionary[kMESSAGEID] as! String == temp[kMESSAGEID] as! String {
        objectMessages[index] = messageDictionary
        self.collectionView.reloadData()
      }
    }
  }
  
  func isIncoming(messageDictionary: NSDictionary) -> Bool {
    if FUser.currentId() == (messageDictionary[kSENDERID] as! String) {
      return false
    }else {
      return true
    }
  }
  
}

//MARK: - JSQMessage Data Source functions
extension ChatViewController {
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
    
    let data = messages[indexPath.row]
    if data.senderId == FUser.currentId() {
      cell.textView?.textColor = .white
    }else {
      cell.textView?.textColor = .black
    }
    
    return cell
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
    return messages[indexPath.row]
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return messages.count
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
    let data = messages[indexPath.row]
    
    if data.senderId == FUser.currentId() {
      return outgoingBubble
    }else {
      return incomingBubble
    }
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
    if indexPath.item % 3 == 0 {
      let message = messages[indexPath.row]
      return JSQMessagesTimestampFormatter.shared()?.attributedTimestamp(for: message.date)
    }else {
      return nil
    }
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
    if indexPath.item % 3 == 0 {
      return kJSQMessagesCollectionViewCellLabelHeightDefault
    }else {
      return 0.0
    }
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
    let message = objectMessages[indexPath.row]
    let status: NSAttributedString!
    let attributedStringColor = [NSAttributedString.Key.foregroundColor: UIColor.darkGray]
    
    switch (message[kSTATUS] as! String) {
    case kDELIVERED:
      status = NSAttributedString(string: kDELIVERED)
    case kREAD:
      let statusText = "Read" + " " + readTimeFrom(dateString: message[kREADDATE] as! String)
      
      status = NSAttributedString(string: statusText, attributes: attributedStringColor)
    default:
      status = NSAttributedString(string: "✔️")
    }
    
    if indexPath.row == (messages.count - 1) {
      return status
    }else {
      return NSAttributedString(string: "")
    }
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
    let data = messages[indexPath.row]
    if data.senderId == FUser.currentId() {
      return kJSQMessagesCollectionViewCellLabelHeightDefault
    }else {
      return 0.0
    }
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
    
    //load More Messages
    loadMoreMessages(maxNumber: maxMessageNumber, minNumber: minMessageNumber)
    self.collectionView.reloadData()
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
    print("tap on message at \(indexPath!)")
    
    let messageDictionary = objectMessages[indexPath.row]
    let messageType = messageDictionary[kTYPE] as! String
    
    switch messageType {
    case kPICTURE:
      let message = messages[indexPath.row]
      let mediaItem = message.media as! PhotoMediaItem
      let photos = IDMPhoto.photos(withImages: [mediaItem.image])
      let browser = IDMPhotoBrowser(photos: photos)
      self.present(browser!, animated: true, completion: nil)
    case kLOCATION:
      let message = messages[indexPath.row]
      let mediaItem = message.media as! JSQLocationMediaItem
      let mapView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
      mapView.location = mediaItem.location
      self.navigationController?.pushViewController(mapView, animated: true)
    case kVIDEO:
      let message = messages[indexPath.row]
      let mediaItem = message.media as! VideoMessage
      let player = AVPlayer(url: mediaItem.fileURL! as URL)
      let moviePlayer = AVPlayerViewController()
      let session = AVAudioSession.sharedInstance()
      try! session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
      moviePlayer.player = player
      self.present(moviePlayer, animated: true) {
        moviePlayer.player!.play()
      }
    default:
      print("unknow media type")
    }
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
    
    let message = messages[indexPath.row]
    
    var avatar: JSQMessageAvatarImageDataSource
    
    if let testAvatar = jsqAvatarDictionary!.object(forKey: message.senderId) {
      avatar = testAvatar as! JSQMessageAvatarImageDataSource
    }else {
      avatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)
    }
    
    return avatar
  }
  
  override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
    let senderId = messages[indexPath.row].senderId
    var selectedUser: FUser?
    
    if senderId == FUser.currentId() {
      selectedUser = FUser.currentUser()
    }else {
      for user in withUsers {
        if user.objectId == senderId {
          selectedUser = user
        }
      }
    }
    
    //show user profile
    presentUserProfile(forUser: selectedUser!)
  }
  
  
  
}

extension JSQMessagesInputToolbar {
  override open func didMoveToWindow() {
    super.didMoveToWindow()
    guard let window = window else { return }
    if #available(iOS 11.0, *) {
      let anchor = window.safeAreaLayoutGuide.bottomAnchor
      bottomAnchor.constraint(lessThanOrEqualToSystemSpacingBelow: anchor, multiplier: 1.0).isActive = true
    }
  }
}

//MARK: - UIImagePickerController Delegate

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    let video = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL
    
    let picture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
    
    sendMessage(text: nil, date: Date(), picture: picture, location: nil, video: video, audio: nil)
    
    picker.dismiss(animated: true, completion: nil)
  }
}

//MARK: - IQAudio Recorder Controller Delegate
extension ChatViewController: IQAudioRecorderViewControllerDelegate {
  func audioRecorderController(_ controller: IQAudioRecorderViewController, didFinishWithAudioAtPath filePath: String) {
    controller.dismiss(animated: true, completion: nil)
    self.sendMessage(text: nil, date: Date(), picture: nil, location: nil, video: nil, audio: filePath)
  }
  
  func audioRecorderControllerDidCancel(_ controller: IQAudioRecorderViewController) {
    controller.dismiss(animated: true, completion: nil)
  }
  
}

extension ChatViewController: UITextFieldDelegate {
  override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    typingCounterStart()
    return true
  }
}
