//
//  ViewController.swift
//  Lez
//
//  Created by Antonija Pek on 20/02/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import AnimatedCollectionViewLayout

class MatchCollectionViewCell: UICollectionViewCell {
    var helloWorld = "Hello World"
}

class MatchViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var matchCollectionView: UICollectionView!
    
    
    // MARK: - Variables
    let layout = AnimatedCollectionViewLayout()

    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        matchCollectionView.dataSource = self
        matchCollectionView.delegate = self
        
        layout.animator = LinearCardAttributesAnimator()
        layout.scrollDirection = .horizontal
        
        matchCollectionView.collectionViewLayout = layout
        // Turn on the paging mode for auto snaping support.
        matchCollectionView?.isPagingEnabled = true
    }
    
    // MARK: - Actions
    
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
        let cell = matchCollectionView.dequeueReusableCell(withReuseIdentifier: "MatchCell", for: indexPath) as! MatchCollectionViewCell
        print(cell.helloWorld)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 300, height: 600)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
