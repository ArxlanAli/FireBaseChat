//
//  ViewController.swift
//  FireBaseChat
//
//  Created by Arslan Ali on 2/6/18.
//  Copyright © 2018 Arslan Ali. All rights reserved.
//

import UIKit
import FirebaseDatabase




class Channel:NSObject{
    var id:String?
    var name:String?
    init(id:String,name:String) {
        self.id = id
        self.name = name
    }
}

class ChannelViewController: UITableViewController {

    var channels = [Channel]()
    private lazy var channelRef = Database.database().reference().child("channels")
    private var channelrefHandle:DatabaseHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        configureNavBar()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "id")
        self.observeChannels()
    }
    
    
    func observeChannels(){
        channelrefHandle = channelRef.observe(DataEventType.childAdded, with: { (snapshot) in
            let data = snapshot.value as! NSDictionary
            if let name = data["name"] as? String{
                self.channels.append(Channel(id: snapshot.key, name: name))
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    
    deinit {
        if let ref = channelrefHandle{
            channelRef.removeObserver(withHandle: ref)
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let channel = self.channels[indexPath.row]
        let view = ChatViewController(collectionViewLayout: UICollectionViewFlowLayout())
        view.channel = channel
        view.channelRef = self.channelRef.child(self.channels[indexPath.row].id!)
        self.navigationController?.pushViewController(view, animated: true)
    }
    
    @objc func addAction(){
        let alert = UIAlertController(title: "Add Channel", message: "Give Channel Name!!!", preferredStyle: .alert)
        alert.addTextField { (textfield) in
            textfield.placeholder = "Channel Name"
        }
        alert.addAction(UIAlertAction(title: "Create Channel", style: UIAlertActionStyle.default, handler: { (_) in
            if (alert.textFields?.first?.hasText)!{
                self.createChannel(name: (alert.textFields?.first?.text!)!)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func createChannel(name:String){
        let name = [
            "name":name
        ]
        let ref = channelRef.childByAutoId()
        ref.setValue(name)
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.channels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "id", for: indexPath)
        cell.textLabel?.text = self.channels[indexPath.row].name
        return cell
    }
    
    func configureNavBar(){
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(addAction))
        self.navigationItem.title = "Channels"
    }

}

