//
//  ViewController.swift
//  Lez
//
//  Created by Antonija Pek on 20/02/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import SnapKit
import moa

class MatchCollectionViewCell: UICollectionViewCell {
    var helloWorld = "Hello World"
    var userImage = UIImageView()
    var userName = UILabel()
    var parent = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        parent = self.contentView
        setupUserImage()
        
        parent.addSubview(userName)
        userName.snp.makeConstraints { (make) in
            make.left.equalTo(parent)
            make.right.equalTo(parent)
            make.height.equalTo(20)
            make.bottom.equalTo(-150)
        }
        userName.text = helloWorld
        userName.textColor = UIColor.red
        userName.textAlignment = .center
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUserImage() {
        parent.addSubview(userImage)
        userImage.snp.makeConstraints { make in
            make.top.equalTo(parent)
            make.bottom.equalTo(parent).offset(-200)
            make.left.equalTo(parent)
            make.right.equalTo(parent)
        }
        userImage.image = UIImage(named: "Taylor")
        userImage.contentMode = .scaleAspectFill
        userImage.clipsToBounds = true
    }
}

class MatchViewController: UIViewController {
    
    // MARK: - Outlets
    var collectionView: UICollectionView!
    
    // MARK: - Variables
    let collectionViewLayout = CenteredCellCollectionViewFlowLayout()
    let userImage = UIImageView()
    var users: [User] = []
    var superview = UIView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        superview = self.view
        
        for i in 1...10 {
            let newMatchingPreferences = MatchingPreferences(preferedAge: (23, 33))
            let newUser = User(id: i, name: "User \(i)", email: "user@gmail.com", age: 27, location: "New York", isOnboarded: true, isPremium: true, imageURL: "https://lorempixel.com/1000/1000/people/", matchingPreferences: newMatchingPreferences)
            users.append(newUser)
        }

        setupCollectionViewLayout()
        setupCollectionView()
    }
    
    // MARK: - Actions
    func setupCollectionViewLayout() {
        collectionViewLayout.sectionHeadersPinToVisibleBounds = false
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.minimumInteritemSpacing = 8
        collectionViewLayout.minimumLineSpacing = 16
        collectionViewLayout.headerReferenceSize = CGSize(width: 0, height: 0.0)
        collectionViewLayout.footerReferenceSize = CGSize(width: 0, height: 0.0)
    }
    
    func setupCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: collectionViewLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
        collectionView.backgroundColor = UIColor.yellow // Remove this
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.scrollIndicatorInsets = .zero
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.register(MatchCollectionViewCell.self, forCellWithReuseIdentifier: "MatchCell")
        
        view.addSubview(collectionView)
        
        collectionView.snp.makeConstraints { (make) -> Void in
            make.width.equalTo(superview)
            make.height.equalTo(550)
            make.center.equalTo(superview)
        }
    }
    
    // MARK: - Methods

}

extension MatchViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MatchCell", for: indexPath) as! MatchCollectionViewCell
        cell.backgroundColor = .clear
        cell.userImage.moa.url = users[indexPath.row].imageURL
        cell.userName.text = users[indexPath.row].name
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        print("IndexPath \(indexPath.row)")
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.bounds.width * 0.8, height: view.bounds.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let cellWidth: CGFloat = view.bounds.width * 0.8 // 300
        let numberOfCells = floor(view.frame.size.width / cellWidth)  // In my case it will be 1.0
        let edgeInsets = (view.frame.size.width - (numberOfCells * cellWidth)) / (numberOfCells + 1)
        return UIEdgeInsetsMake(16, edgeInsets, 0, edgeInsets)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView.bounds.minX > (view.bounds.width / 2) * 0.3  {
            print("Scroll.")
        }
    }
}

final class CenteredCellCollectionViewFlowLayout: UICollectionViewFlowLayout {
    var mostRecentOffset = CGPoint()
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard velocity.x != 0.0 else { return mostRecentOffset }
        guard let collectionView = self.collectionView,
            let attributesForVisibleCells = layoutAttributesForElements(in: collectionView.bounds) else {
                mostRecentOffset = super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
                return mostRecentOffset
        }
        let halvedWidth = collectionView.bounds.size.width / 2
        var candidateAttributes: UICollectionViewLayoutAttributes?
        for attributes in attributesForVisibleCells {
            guard attributes.representedElementCategory == .cell else { continue }
            if attributes.center.x == 0.0 ||
                (attributes.center.x > (collectionView.contentOffset.x + halvedWidth) && velocity.x < 0.0) { continue }
            candidateAttributes = attributes
        }
        if proposedContentOffset.x == -collectionView.contentInset.left { return proposedContentOffset }
        guard candidateAttributes != nil else { return mostRecentOffset }
        mostRecentOffset = CGPoint(x: floor(candidateAttributes!.center.x - halvedWidth), y: proposedContentOffset.y)
        return mostRecentOffset
    }
}
