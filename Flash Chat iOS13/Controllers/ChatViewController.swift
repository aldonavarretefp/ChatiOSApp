//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ChatViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!h
    @IBOutlet weak var messageTextfield: UITextField!
    let db = Firestore.firestore()
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true
        tableView.dataSource = self
//        tableView.delegate = self
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        title = "Your Chat"
        loadMessages()
    }
    func loadMessages() {
        db.collection(K.FStore.collectionName)
            .order(by: K.FStore.dateField)
            .addSnapshotListener { (querySnapshot, err) in
                self.messages = []
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    guard let snapshotDocs = querySnapshot?.documents else { return }
                    for doc in snapshotDocs {
                        let data = doc.data()
                        guard let messageSender = data[K.FStore.senderField] as? String, let messageBody = data[K.FStore.bodyField] as? String else { return }
                        let newMessage = Message(sender: messageSender, body: messageBody)
                        self.messages.append(newMessage)
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                            self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                        }
                    }
                }
        }
    }
    
    @IBAction func signOutPressed(_ sender: UIBarButtonItem) {
        let firebaseAuth = Auth.auth()
        navigationController?.popToRootViewController(animated: true)
        do {
          try firebaseAuth.signOut()
        } catch let signOutError as NSError {
          print("Error signing out: %@", signOutError)
        }
    }
    @IBAction func sendPressed() {
        if(messageTextfield.text == ""){
            return
        }
        
        guard let messageBody: String = messageTextfield.text, let userName: String = Auth.auth().currentUser?.email else { return }
        db.collection(K.FStore.collectionName).addDocument(data:[
                K.FStore.senderField: userName,
                K.FStore.bodyField: messageBody,
                K.FStore.dateField: Date().timeIntervalSince1970
            ]) { error in
                if let e = error {
                    print(e)
                }else{
                    DispatchQueue.main.async {
                        self.messageTextfield.text = "";
                    }
                }
            };
    }
    
    @IBAction func textFieldPrimaryActionTriggered(_ sender: UITextField) {
        sendPressed()
    }
    
    

}

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        if (message.sender == Auth.auth().currentUser?.email) {
            cell.youAvatarImageView.isHidden = true
            cell.avatarImageView.isHidden = false
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightBlue)
            cell.label.textColor = UIColor(named: K.BrandColors.blue)
        }else{
            cell.youAvatarImageView.isHidden = false
            cell.avatarImageView.isHidden = true
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.label.textColor = UIColor(named: K.BrandColors.purple)
        }
        cell.label.text = message.body
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
}
//
//extension ChatViewController: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    }
//}
