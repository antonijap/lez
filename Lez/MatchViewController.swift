//
//  ViewController.swift
//  Lez
//
//  Created by Antonija Pek on 20/02/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit

class MatchCollectionViewCell: UICollectionViewCell {
    var helloWorld = "Hello World"
}

//class LabelSectionController: ListSectionController {
//    override func sizeForItem(at index: Int) -> CGSize {
//        return CGSize(width: collectionContext!.containerSize.width, height: 55)
//    }
//
//    override func cellForItem(at index: Int) -> UICollectionViewCell {
//        return collectionContext!.dequeueReusableCell(of: MatchCollectionViewCell.self, for: self, at: index)
//    }
//}

class MatchViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var matchCollectionView: UICollectionView!
    
    
    // MARK: - Variables
    let layout = UICollectionViewFlowLayout()
//    lazy var adapter: ListAdapter = {
//        return ListAdapter(updater: ListAdapterUpdater(), viewController: self, workingRangeSize: 0)
//    }()
    var users: [User] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        matchCollectionView.dataSource = self
        matchCollectionView.delegate = self
        matchCollectionView.isPagingEnabled = true
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 16
        layout.scrollDirection = .horizontal
        
        for i in 1...10 {
            let newMatchingPreferences = MatchingPreferences(preferedAge: (23, 33))
            let newUser = User(id: i, name: "User \(i)", email: "user@gmail.com", age: 27, location: "New York", isOnboarded: true, isPremium: true, matchingPreferences: newMatchingPreferences)
            users.append(newUser)
        }
    }
    
    // MARK: - Actions
    
    // MARK: - Methods
    func snapToNearestCell(_ collectionView: UICollectionView) {
        for i in 0..<matchCollectionView.numberOfItems(inSection: 0) {
            
            let itemWithSpaceWidth = layout.itemSize.width + layout.minimumLineSpacing
            let itemWidth = layout.itemSize.width
            
            if matchCollectionView.contentOffset.x <= CGFloat(i) * itemWithSpaceWidth + itemWidth / 2 {
                let indexPath = IndexPath(item: i, section: 0)
                matchCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                break
            }
        }
    }
}

//extension MatchViewController: ListAdapterDataSource {
//    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
//        return self.users
//    }
//    
//    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
//        return LabelSectionController()
//    }
//    
//    func emptyView(for listAdapter: ListAdapter) -> UIView? {
//        let view = UIView()
//        view.backgroundColor = .lightGray
//        return view
//    }
//}

extension MatchViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = matchCollectionView.dequeueReusableCell(withReuseIdentifier: "MatchCell", for: indexPath) as! MatchCollectionViewCell
        print(cell.helloWorld)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.bounds.width * 0.8, height: view.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let cellWidth: CGFloat = view.bounds.width * 0.8
        
        let numberOfCells = floor(self.view.frame.size.width / cellWidth)
        let edgeInsets = (self.view.frame.size.width - (numberOfCells * cellWidth)) / (numberOfCells + 1)
        
        return UIEdgeInsetsMake(16, edgeInsets, 0, edgeInsets)
    }

}
