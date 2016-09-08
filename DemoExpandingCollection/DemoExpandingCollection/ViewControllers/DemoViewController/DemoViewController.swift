//
//  DemoViewController.swift
//  TestCollectionView
//
//  Created by Alex K. on 12/05/16.
//  Copyright © 2016 Alex K. All rights reserved.
//

import UIKit

class DemoViewController: ExpandingViewController {
    
    typealias ItemInfo = (imageName: String, title: String)
    private var cellsIsOpen = [Bool]()
    private let items: [ItemInfo] = [("item0", "Boston"),("item1", "New York"),("item2", "San Francisco"),("item3", "Washington")]
    
    let imageURLArray = ["http://i.imgur.com/6vus956.png", "http://i.imgur.com/LCJnJxO.png", "http://i.imgur.com/ArMRWx4.png", "http://i.imgur.com/wydD5dr.png"]
    private var imageCache : [String : UIImage] = [String : UIImage]()
    
    @IBOutlet weak var pageLabel: UILabel!
}

// MARK: life cicle

extension DemoViewController {
    
    override func viewDidLoad() {
        itemSize = CGSize(width: 256, height: 335)
        super.viewDidLoad()
        
        registerCell()
        fillCellIsOpeenArry()
        addGestureToView(collectionView!)
        configureNavBar()
    }
}

// MARK: Helpers

extension DemoViewController {
    
    private func registerCell() {
        let nib = UINib(nibName: String(DemoCollectionViewCell), bundle: nil)
        collectionView?.registerNib(nib, forCellWithReuseIdentifier: String(DemoCollectionViewCell))
    }
    
    private func fillCellIsOpeenArry() {
        for _ in items {
            cellsIsOpen.append(false)
        }
    }
    
    private func getViewController() -> ExpandingTableViewController {
        let storyboard = UIStoryboard(storyboard: .Main)
        let toViewController: DemoTableViewController = storyboard.instantiateViewController()
        return toViewController
    }
    
    private func configureNavBar() {
        navigationItem.leftBarButtonItem?.image = navigationItem.leftBarButtonItem?.image!.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
    }
}

/// MARK: Gesture

extension DemoViewController {
    
    private func addGestureToView(toView: UIView) {
        let gesutereUp = Init(UISwipeGestureRecognizer(target: self, action: #selector(DemoViewController.swipeHandler(_:)))) {
            $0.direction = .Up
        }
        
        let gesutereDown = Init(UISwipeGestureRecognizer(target: self, action: #selector(DemoViewController.swipeHandler(_:)))) {
            $0.direction = .Down
        }
        toView.addGestureRecognizer(gesutereUp)
        toView.addGestureRecognizer(gesutereDown)
    }
    
    func swipeHandler(sender: UISwipeGestureRecognizer) {
        let indexPath = NSIndexPath(forRow: currentIndex, inSection: 0)
        guard let cell  = collectionView?.cellForItemAtIndexPath(indexPath) as? DemoCollectionViewCell else { return }
        // double swipe Up transition
        if cell.isOpened == true && sender.direction == .Up {
            pushToViewController(getViewController(), array: imageURLArray)
            
            if let rightButton = navigationItem.rightBarButtonItem as? AnimatingBarButton {
                rightButton.animationSelected(true)
            }
        }
        let open = sender.direction == .Up ? true : false
        cell.cellIsOpen(open)
        cellsIsOpen[indexPath.row] = cell.isOpened
    }
}

// MARK: UIScrollViewDelegate

extension DemoViewController {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        pageLabel.text = "\(currentIndex+1)/\(items.count)"
    }
}

// MARK: UICollectionViewDataSource

extension DemoViewController {
    
    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        super.collectionView(collectionView, willDisplayCell: cell, forItemAtIndexPath: indexPath)
        guard let cell = cell as? DemoCollectionViewCell else { return }
        
        let index = indexPath.row % items.count
        let info = items[index]
        cell.backgroundImageView?.image = UIImage(named: info.imageName)
        
        let urlString = self.imageURLArray[indexPath.row]
        //check the image cache to see if cell has been previously downloaded and cached. If so set the cell with the image
        if let image = self.imageCache[urlString] {
            cell.backgroundImageView.image = image
        }
            //cache doesn't contain image, asynchronously download image and then cache it, then set cell.
        else{
            self.asychronouslyDownloadImageFromURLAndSetCollectionViewCellAtIndexPath(urlString, indexPath: indexPath)
        }
        
        cell.customTitle.text = info.title
        cell.cellIsOpen(cellsIsOpen[index], animated: false)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? DemoCollectionViewCell
            where currentIndex == indexPath.row else { return }
        
        if cell.isOpened == false {
            cell.cellIsOpen(true)
        } else {
            
            pushToViewController(getViewController(), array: imageURLArray)
            
            if let rightButton = navigationItem.rightBarButtonItem as? AnimatingBarButton {
                rightButton.animationSelected(true)
            }
        }
    }
}

// MARK: UICollectionViewDataSource

extension DemoViewController {
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCellWithReuseIdentifier(String(DemoCollectionViewCell), forIndexPath: indexPath)
    }
    
    /**
     This method asychronously downloades an image from the specified urlString, caches this image, and then updates the the collection view cell with this image.
     
     - parameter collectionView:
     - parameter indexPath:
     */
    private func asychronouslyDownloadImageFromURLAndSetCollectionViewCellAtIndexPath(urlString : String, indexPath : NSIndexPath){
        if(urlString != ""){
            if let url  = NSURL(string: urlString){
                
                let request: NSURLRequest = NSURLRequest(URL: url)
                let mainQueue = NSOperationQueue.mainQueue()
                
                NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) -> Void in
                    if error == nil {
                        let image = UIImage(data: data!)
                        // Store the image in the cache
                        self.imageCache[urlString] = image
                        // Update the cell with this image
                        dispatch_async(dispatch_get_main_queue(), {
                            if let cell = self.collectionView?.cellForItemAtIndexPath(indexPath) {
                                (cell as! DemoCollectionViewCell).backgroundImageView.image = image
                            }
                        })
                    }
                    else {
                        print("Error: \(error!.localizedDescription)")
                    }
                })
            }
        }
    }
}
