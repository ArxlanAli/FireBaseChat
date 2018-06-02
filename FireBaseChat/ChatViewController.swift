//
//  ChatViewController.swift
//  FireBaseChat
//
//  Created by Arslan Ali on 2/6/18.
//  Copyright © 2018 Arslan Ali. All rights reserved.
//

import UIKit
import FirebaseDatabase



class Messages:NSObject{
    var senderId:String?
    var message:String?
    
    init(senderId:String,message:String) {
        self.senderId = senderId
        self.message = message
    }
}

class ChatViewController: UICollectionViewController,UICollectionViewDelegateFlowLayout{

    var channel:Channel!
    var channelRef:DatabaseReference!
    var bottomConstraint : NSLayoutConstraint!
    private var messageRef:DatabaseReference!
    private var newMessageRefHandle: DatabaseHandle?
    
    
    
    var messageArray = [Messages]()
    
    let bottomview:UIView = {
        let bottView = UIView()
        bottView.backgroundColor = UIColor.white
        bottView.translatesAutoresizingMaskIntoConstraints = false
        return bottView
        
    }()
    
    let textField:UITextField = {
        let text = UITextField()
        text.attributedPlaceholder = NSAttributedString(string: "Type here...", attributes: [NSAttributedStringKey.font:UIFont.italicSystemFont(ofSize: 15)])
        text.translatesAutoresizingMaskIntoConstraints = false
        return text
    }()
    
    let send:UIButton = {
        let button = UIButton(type: UIButtonType.system)
        button.setTitle("Send", for: .normal)
        button.titleLabel?.font = UIFont.italicSystemFont(ofSize: 13)
        button.setTitleColor(.white, for: .normal)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 10
        button.backgroundColor = UIColor(displayP3Red: 35/255, green: 218/255, blue: 109/255, alpha: 1)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
        
        
    }()
    let line:UIView = {
        let linee = UIView()
        linee.translatesAutoresizingMaskIntoConstraints = false
        linee.backgroundColor = UIColor.lightGray.withAlphaComponent(0.6)
        return linee
    }()
    
    
    
    
    var cellIdentifier = "id"
    fileprivate func COnfigureViews() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 30
        self.collectionView?.collectionViewLayout = layout
        self.collectionView?.backgroundColor = .white
        self.collectionView?.register(chatLogController.self, forCellWithReuseIdentifier: cellIdentifier)
        self.view.addSubview(bottomview)
        self.view.addSubview(textField)
        self.view.addSubview(self.send)
        self.view.addSubview(self.line)
        let gesture = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.dismissAll))
        self.view.addGestureRecognizer(gesture)
        
        self.bottomview.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        self.bottomview.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        self.bottomConstraint = self.bottomview.bottomAnchor.constraint(equalTo: view.bottomAnchor,constant:0)
        bottomConstraint.isActive = true
        
        self.bottomview.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        self.textField.centerYAnchor.constraint(equalTo: self.bottomview.centerYAnchor,constant:0).isActive = true
        self.textField.leftAnchor.constraint(equalTo: self.bottomview.leftAnchor,constant: 30).isActive = true
        self.textField.rightAnchor.constraint(equalTo: self.send.leftAnchor).isActive = true
        
        self.send.topAnchor.constraint(equalTo: self.bottomview.topAnchor,constant:8).isActive = true
        self.send.rightAnchor.constraint(equalTo: self.bottomview.rightAnchor,constant: -20).isActive = true
        self.send.widthAnchor.constraint(equalToConstant: 50).isActive = true
        self.send.addTarget(self, action: #selector(sendAction), for: .touchUpInside)
        
        self.line.leftAnchor.constraint(equalTo: self.bottomview.leftAnchor,constant:20).isActive = true
        self.line.rightAnchor.constraint(equalTo: self.bottomview.rightAnchor,constant:-20).isActive = true
        self.line.topAnchor.constraint(equalTo: self.bottomview.topAnchor).isActive = true
        self.line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDetection(userInfo:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDisappear(userInfo:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        
    }
    
    @objc func keyboardDisappear(userInfo:Notification){
        
        self.collectionView?.contentInset = UIEdgeInsetsMake(5, 0, 0, 0)
        dismissAll()
        //self.collectionView?.contentInset = UIEdgeInsetsMake(5, 0, self.bottomview.frame.height - 30, 0)
    }
    
    
    
    @objc func sendAction(){
        
        if textField.hasText{
            let data = [
                "senderId":UserDefaults.standard.string(forKey: "userId")!,
                "text":self.textField.text!,
            ]
            let newMessage = self.messageRef.childByAutoId()
            newMessage.setValue(data)
            self.textField.text = ""
        }
    }
    
    
    func addObserver(){
        self.newMessageRefHandle = self.messageRef.observe(DataEventType.childAdded, with: { (snapshot) in
            let data = snapshot.value as! NSDictionary
            print(data)
            if let senderId = data["senderId"] as? String, let message = data["text"] as? String{
                self.messageArray.append(Messages(senderId: senderId, message: message))
                DispatchQueue.main.async {
                    self.collectionView?.reloadData()
                    DispatchQueue.main.async {
                        let index = IndexPath(row: self.messageArray.count - 1, section: 0)
                        if index.row >= 0{
                            self.collectionView?.scrollToItem(at: index, at: UICollectionViewScrollPosition.top, animated: true)
                        }
                    }
                }
            }
        })
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.messageRef = self.channelRef.child("messages")
        self.navigationItem.title = self.channel.name
        COnfigureViews()
        addObserver()
    }
    
    
    @objc func dismissAll(){
        self.view.endEditing(true)
        UIView.animate(withDuration: 0.5) {
            self.bottomConstraint.constant = 0
          
        }
    }
    
    @objc func keyboardDetection(userInfo:Notification){
        if let userindo = userInfo.userInfo{
            
            let frame = (userindo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            print(frame)
            self.bottomConstraint.constant = -(frame.height)
            
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
            }, completion: { (_) in
                
                let index = IndexPath(row: self.messageArray.count - 1, section: 0)
                self.collectionView?.scrollToItem(at: index, at: .top, animated: true)
            })
            
            
            
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsetsMake(19, 0, self.bottomview.frame.height + 20, 0)
        
    }
    
    func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return self.messageArray.count
    }
    
    
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! chatLogController
        let mes = self.messageArray[indexPath.row].message
        cell.messgae.text = mes
        let size = CGSize(width: 250, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        let estimatedFrame = NSString(string: mes!).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 13)], context: nil)
        if self.messageArray[indexPath.row].senderId != UserDefaults.standard.string(forKey: "userId"){
            cell.messgae.frame = CGRect(x: 20, y: 0, width: estimatedFrame.width + 35, height: estimatedFrame.height + 28)
            cell.messgae.textColor = UIColor.black
            cell.messgae.backgroundColor = UIColor(displayP3Red: 233/255, green: 240/255, blue: 246/255, alpha: 1)
        }else if self.messageArray[indexPath.row].senderId == UserDefaults.standard.string(forKey: "userId"){
            cell.messgae.frame = CGRect(x: self.view.frame.width - estimatedFrame.width - 18 - 2 - 30, y: 0, width: estimatedFrame.width + 35, height: estimatedFrame.height + 28)
            cell.messgae.backgroundColor = UIColor(displayP3Red: 206/255, green: 224/255, blue: 237/255, alpha: 1)
            cell.messgae.textColor = UIColor.black
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let message = messageArray[indexPath.row].message
        let size = CGSize(width: 250, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        let estimatedFrame = NSString(string: message!).boundingRect(with: size, options: options, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 13)], context: nil)
        return CGSize(width: self.view.frame.width, height: estimatedFrame.height + 10)
        
        
    }
    
    
    
    
}


class chatLogController: BaseCell{
    

    
    let messgae:UITextView = {
        let text = UITextView()
        text.text = "Hello First Message"
        text.translatesAutoresizingMaskIntoConstraints = false
        text.font = UIFont.systemFont(ofSize: 13)
        text.isEditable = false
        text.layer.cornerRadius = 15.0
        text.layer.masksToBounds = true
        text.textContainerInset = UIEdgeInsetsMake(10, 10, 0, 0)
        return text
    }()
    
    
    
    
    override func setUp() {
        super.setUp()
        self.addSubview(self.messgae)
    }
    
}
class BaseCell: UICollectionViewCell{
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setUp()
        
        
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUp(){
        
    }
}

