//
//  PostsViewController.swift
//  Movables
//
//  Created by Eddie Chen on 5/25/18.
//  Copyright © 2018 Movables, Inc. All rights reserved.
//

import UIKit
import SlackTextViewController
import Firebase

class PostsViewController: SLKTextViewController {
    
    var reference: DocumentReference!
    var referenceType: CommunityType!
    var posts: [Post]?
    var listener: ListenerRegistration?
    var emptyStateView: EmptyStateView!
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override init?(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(collectionViewLayout: layout)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        
        title = "Conversation"
        collectionView?.dataSource = self
        collectionView?.delegate = self
        collectionView?.alwaysBounceVertical = true
        collectionView?.contentInsetAdjustmentBehavior = .never
        collectionView?.contentInset.top = 35
        collectionView?.backgroundColor = .white
        let layout = collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        layout.estimatedItemSize = CGSize(width: UIScreen.main.bounds.width, height: 120)
        layout.itemSize = UICollectionViewFlowLayoutAutomaticSize
        
        collectionView?.register(PostCollectionViewCell.self, forCellWithReuseIdentifier: "postCell")
        collectionView?.register(ActivityIndicatorCollectionViewCell.self, forCellWithReuseIdentifier: "loadingViewCell")
        
        self.navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        self.navigationController?.navigationBar.shadowImage = nil
        
        textInputbar.rightButton.setTitle("Send", for: .normal)
        textInputbar.autoHideRightButton = false
        textInputbar.isTranslucent = false
        textInputbar.textView.placeholder = "Say something..."
        
        let moreButton = UIBarButtonItem(image: UIImage(named: "round_more_black_24pt"), style: .plain, target: self, action: #selector(didTapMoreButton(sender:)))
        navigationItem.rightBarButtonItem = moreButton
        
        emptyStateView = EmptyStateView(frame: .zero)
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true
        emptyStateView.transform = self.collectionView!.transform
        emptyStateView.actionButton.isHidden = true
        collectionView?.addSubview(emptyStateView)
        
        collectionView?.addConstraint(NSLayoutConstraint(item: emptyStateView, attribute: .width, relatedBy: .equal, toItem: collectionView, attribute: .width, multiplier: 1, constant: 0))
        collectionView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[emptyStateView]|", options: .directionLeadingToTrailing, metrics: nil, views: ["emptyStateView": emptyStateView]) + NSLayoutConstraint.constraints(withVisualFormat: "V:[emptyStateView]", options: .alignAllCenterX, metrics: nil, views: ["emptyStateView": emptyStateView]))
            collectionView?.addConstraints([
                NSLayoutConstraint(item: emptyStateView, attribute: .centerX, relatedBy: .equal, toItem: collectionView, attribute: .centerX, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: emptyStateView, attribute: .centerY, relatedBy: .equal, toItem: collectionView, attribute: .centerY, multiplier: 1, constant: 0)
                ])
        
        // attach listener on public comments
        listenToPosts()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // detach listener on public comments
        self.listener?.remove()
    }
    
    @objc private func didTapMoreButton(sender: UIBarButtonItem) {
        print("tapped more")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func listenToPosts() {
        reference.collection("public_comments").order(by: "created_date", descending: true).getDocuments { (querySnapshot, error) in
            guard let snapshot = querySnapshot else {
                print("Error fetching snapshots: \(error!)")
                return
            }
            var postsTemp:[Post] = []
            for document in snapshot.documents {
                postsTemp.append(Post(dictionary: document.data(), reference: document.reference))
            }
            self.posts = postsTemp
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0, animations: {
                    self.collectionView?.reloadData()
                    if self.posts != nil && self.posts!.count > 0 {
                        self.emptyStateView.isHidden = true
                    } else {
                        self.emptyStateView.isHidden = false
                    }
                })
            }
            self.listener = self.reference.collection("public_comments").order(by: "created_date", descending: true).addSnapshotListener { (querySnapshot, error) in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                var newPosts:[Post] = []
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        if self.posts?.index(where: { $0.reference == diff.document.reference}) != nil {
                        } else {
                            newPosts.append(Post(dictionary: diff.document.data(), reference: diff.document.reference))
                        }
                        print("added")
                    }
                    if (diff.type == .modified) {
                        if let index = self.posts?.index(where: { $0.reference == diff.document.reference}) {
                            self.posts?[index] = Post(dictionary: diff.document.data(), reference: diff.document.reference)
                            print("Modified")
                        }
                    }
                    if (diff.type == .removed) {
                        if let index = self.posts?.index(where: { $0.reference == diff.document.reference}) {
                            self.posts?.remove(at: index)
                            print("Removed")
                        }
                    }
                }
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0, animations: {
                        self.posts?.insert(contentsOf: newPosts, at: 0)
                        self.collectionView?.reloadData()
                        if self.posts != nil && self.posts!.count > 0 {
                            self.emptyStateView.isHidden = true
                        } else {
                            self.emptyStateView.isHidden = false
                        }
                    })
                }
            }
        }
    }
    
    override func didPressRightButton(_ sender: Any?) {
        let postData: [String: Any] = [
            "author": [
                "name": Auth.auth().currentUser?.displayName ?? "",
                "pic_url": Auth.auth().currentUser?.photoURL?.absoluteString ?? "",
                "reference": Firestore.firestore().collection("users").document(Auth.auth().currentUser!.uid)
            ],
            "content": [
                "attachments": nil,
                "text": self.textView.text
            ],
            "created_date": Date()
        ]
        self.textView.text = ""
        reference.collection("public_comments").addDocument(data: postData) { (error) in
            if let error = error {
                print(error)
            } else {
                print("saved new public comment")
            }
        }
        reference.updateData([
                "participants.\(Auth.auth().currentUser!.uid)": Date().timeIntervalSince1970
            ]) { (error) in
            if let error = error {
                print(error)
            } else {
                print("added current user as conversation participant")
            }
        }
        
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if posts != nil {
            if posts!.count > 0 {
                return posts!.count
            } else {
                return 0
            }
        } else {
            return 1
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if posts != nil {
            if posts!.count > 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "postCell", for: indexPath) as! PostCollectionViewCell
                let post = posts![indexPath.item]
                let subtitleString = "\(post.author.displayName) . \(post.createdAt.timeAgoSinceNow)"
                cell.commentLabel.text = post.content.text
                cell.metaLabel.text = subtitleString
                cell.parentView.transform = self.collectionView!.transform
                if let photoUrl = post.author.photoUrl {
                    cell.profileImageView.sd_setImage(with: URL(string: photoUrl)) { (image, error, cacheType, url) in
                        print("loaded author")
                    }
                }
                cell.separatorView.isHidden = indexPath.item == 0
                return cell
            } else {
                return UICollectionViewCell()
            }
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "loadingViewCell", for: indexPath) as! ActivityIndicatorCollectionViewCell
            cell.activityIndicatorView.startAnimating()
            return cell
        }
    }
}
