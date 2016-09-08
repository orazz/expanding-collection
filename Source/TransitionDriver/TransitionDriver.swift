//
//  TransitionDriver.swift
//  TestCollectionView
//
//  Created by Alex K. on 11/05/16.
//  Copyright © 2016 Alex K. All rights reserved.
//

import UIKit

class TransitionDriver {
    
    //MARK: SLider
    //set in the setUpProgrammaticHorizontalCollectionViewController method
    var programmaticCarouselCollectionViewController : MILCarouselCollectionViewController!
    
    //delay timer for fake server to return back data
    var kImageServerDelayTime : NSTimeInterval = 1.5
    
    //instance of the timer that causes the carousel collection view to switch pages
    var serverDelayTimer : NSTimer!
    
    var imageURLArray = [String]()
    
    // MARK: Constants
    struct Constants {
        static let HideKey = 101
    }
    
    // MARK: Vars
    
    private let view: UIView
    private let duration: Double = 0.4
    
    // for push animation
    private var copyCell: BasePageCollectionCell?
    private var currentCell: BasePageCollectionCell?
    private var backImageView: UIImageView?
    
    private var leftCell: UICollectionViewCell?
    private var rightCell: UICollectionViewCell?
    private var step: CGFloat = 0
    
    private var frontViewFrame = CGRect.zero
    private var backViewFrame  = CGRect.zero
    
    init(view: UIView) {
        self.view = view
    }
}

// MARK: control

extension TransitionDriver {
    
    func setUpProgrammaticCarouselCollectionViewController(){
        
        //initialize programmaticCarouselCollectionViewController using MILCarouselCollectionViewFlowLayout
        let flow = MILCarouselCollectionViewFlowLayout()
        self.programmaticCarouselCollectionViewController = MILCarouselCollectionViewController(collectionViewLayout: flow)
        
        //set frame of programmaticCarouselCollectionViewController's view
        self.programmaticCarouselCollectionViewController.view.frame = CGRectMake(0, UIScreen.mainScreen().bounds.height/2, UIScreen.mainScreen().bounds.width, 194)
        
        //add programmaticCarouselCollectionViewController as child view controller to this view controller, and add the programmaticCarouselCollectionViewController's view to this ViewController's view
        //self.addChildViewController(self.programmaticCarouselCollectionViewController)
        //self.programmaticCarouselCollectionViewController.didMoveToParentViewController(self)
        //self.view.addSubview(self.programmaticCarouselCollectionViewController.view)
        
        //set the locally stored place holder image to be shown in each cell while we wait for the server to return an array of imageURLs or for the images to download from the image url's
        //self.programmaticCarouselCollectionViewController.localPlaceHolderImageName = "item0"
        
        //change default collectionView background color of black to white
        self.programmaticCarouselCollectionViewController.collectionView?.backgroundColor = UIColor.whiteColor()
        
    }
    
    
    /**
     This method fakes a query to a server to get images. It assumes a kImageServerDelayTime second delay
     */
    func getImagesFromServer(){
        self.serverDelayTimer = NSTimer.scheduledTimerWithTimeInterval(self.kImageServerDelayTime, target: self, selector: #selector(TransitionDriver.didReceiveImagesFromSever), userInfo: nil, repeats: false)
    }
    
    
    /**
     This method fakes a call back from a server that has an array of imageURL's
     */
    @objc func didReceiveImagesFromSever(){
        
        //refresh programmaticCarouselCollectionView with newly received data
        self.programmaticCarouselCollectionViewController.setToHandleImageURLStrings()
        self.programmaticCarouselCollectionViewController.refresh(imageURLArray)
    }
    
    func pushTransitionAnimationIndex(currentIndex: Int,
                                      collecitionView: UICollectionView,
                                      backImage: UIImage?,
                                      headerHeight: CGFloat,
                                      insets: CGFloat,
                                      completion: UIView -> Void) {
        
        guard case let cell as BasePageCollectionCell = collecitionView.cellForItemAtIndexPath(NSIndexPath(forRow: currentIndex, inSection: 0)),
            let copyView = cell.copyCell() else { return }
        copyCell = copyView
        setUpProgrammaticCarouselCollectionViewController()
        getImagesFromServer()
        // move cells
        moveCellsCurrentIndex(currentIndex, collectionView: collecitionView)
        
        currentCell = cell
        cell.hidden = true
        
        configurateCell(copyView, backImage: backImage)
        backImageView = addImageToView(copyView.backContainerView, image: backImage)
        
        openBackViewConfigureConstraints(copyView, height: headerHeight, insets: insets)
        openFrontViewConfigureConstraints(copyView, height: headerHeight, insets: insets)
        
        // corner animation
        copyView.backContainerView.animationCornerRadius(0, duration: duration)
        copyView.frontContainerView.animationCornerRadius(0, duration: duration)
        
        // constraints animation
        UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            self.backImageView?.alpha        = 1
            self.copyCell?.shadowView?.alpha = 0
            copyView.frontContainerView.subviewsForEach { if $0.tag == Constants.HideKey { $0.alpha = 0 } }
            }, completion: { success in
                let data = NSKeyedArchiver.archivedDataWithRootObject(copyView.frontContainerView)
                guard case let headerView as UIView = NSKeyedUnarchiver.unarchiveObjectWithData(data) else {
                    fatalError("must copy")
                }
                if let imageView = headerView.viewWithTag(109)?.subviews[0] as? UIImageView {
                    self.programmaticCarouselCollectionViewController.localPlaceHolderImage = imageView.image
                }
                
                headerView.viewWithTag(109)?.subviews[0].removeFromSuperview()
                let sliderView = self.programmaticCarouselCollectionViewController.view
                sliderView.frame = headerView.frame
                sliderView.frame.origin.x = 0
                sliderView.frame.origin.y = 0
                headerView.viewWithTag(109)?.addSubview(sliderView)
                
                completion(headerView)
        })
    }
    
    
    func popTransitionAnimationContantOffset(offset: CGFloat, backImage: UIImage?) {
        guard let copyCell = self.copyCell else {
            return
        }
        
        var currentImage: UIImage!
        let collectionView = self.programmaticCarouselCollectionViewController?.collectionView
        if let cell = collectionView?.cellForItemAtIndexPath(collectionView!.indexPathsForVisibleItems()[0]) as? MILCarouselCollectionViewCell {
            currentImage = cell.imageView.image
        }
        
        if let imageView = copyCell.viewWithTag(109)?.subviews[0] as? UIImageView {
            imageView.image = currentImage
        }
        
        backImageView?.image = backImage
        // configuration start position
        configureCellBeforeClose(copyCell, offset: offset)
        
        closeBackViewConfigurationConstraints(copyCell)
        closeFrontViewConfigurationConstraints(copyCell)
        
        // corner animation
        copyCell.backContainerView.animationCornerRadius(copyCell.backContainerView.layer.cornerRadius, duration: duration)
        copyCell.frontContainerView.animationCornerRadius(copyCell.frontContainerView.layer.cornerRadius, duration: duration)
        
        UIView.animateWithDuration(duration, delay: 0, options: .CurveEaseInOut, animations: {
            self.rightCell?.center.x -= self.step
            self.leftCell?.center.x  += self.step
            
            self.view.layoutIfNeeded()
            self.backImageView?.alpha  = 0
            copyCell.shadowView?.alpha = 1
            
            copyCell.frontContainerView.subviewsForEach { if $0.tag == Constants.HideKey { $0.alpha = 1 } }
            }, completion: { success in
                
                if let imageView = self.currentCell?.viewWithTag(109)?.subviews[0] as? UIImageView {
                    imageView.image = currentImage
                }
                self.currentCell?.hidden = false
                self.removeCurrentCell()
        })
    }
}

// MARK: Helpers

extension TransitionDriver {
    
    private func removeCurrentCell()  {
        if case let currentCell as UIView = self.copyCell {
            currentCell.removeFromSuperview()
        }
    }
    
    private func configurateCell(cell: BasePageCollectionCell, backImage: UIImage?) {
        cell.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cell)
        
        // add constraints
        [(NSLayoutAttribute.Width, cell.bounds.size.width), (NSLayoutAttribute.Height, cell.bounds.size.height)].forEach { info in
            cell >>>- {
                $0.attribute = info.0
                $0.constant  = info.1
            }
        }
        
        [NSLayoutAttribute.CenterX, .CenterY].forEach { attribute in
            (view, cell) >>>- { $0.attribute = attribute }
        }
        cell.layoutIfNeeded()
    }
    
    private func addImageToView(view: UIView, image: UIImage?) -> UIImageView? {
        guard let image = image else { return nil }
        
        let imageView = Init(UIImageView(image: image)) {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.alpha = 0
        }
        view.addSubview(imageView)
        // add constraints
        [NSLayoutAttribute.Left, .Right, .Top, .Bottom].forEach { attribute in
            (view, imageView) >>>- { $0.attribute = attribute }
        }
        imageView.layoutIfNeeded()
        
        return imageView
    }
    
    private func moveCellsCurrentIndex(currentIndex: Int, collectionView: UICollectionView) {
        self.leftCell  = nil
        self.rightCell = nil
        
        if let leftCell = collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: currentIndex - 1, inSection: 0)) {
            let step = leftCell.frame.size.width + (leftCell.frame.origin.x - collectionView.contentOffset.x)
            UIView.animateWithDuration(0.2, animations: {
                leftCell.center.x -= step
            })
            self.leftCell = leftCell
            self.step     = step
        }
        
        if let rightCell = collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: currentIndex + 1, inSection: 0)) {
            let step = collectionView.frame.size.width - (rightCell.frame.origin.x - collectionView.contentOffset.x)
            UIView.animateWithDuration(0.2, animations: {
                rightCell.center.x += step
            })
            self.rightCell = rightCell
            self.step      = step
        }
    }
}

// MARK: animations

extension TransitionDriver {
    
    private func openFrontViewConfigureConstraints(cell: BasePageCollectionCell, height: CGFloat, insets: CGFloat) {
        
        if let heightConstraint = cell.frontContainerView.getConstraint(.Height) {
            frontViewFrame.size.height = heightConstraint.constant
            heightConstraint.constant  = height
        }
        
        if let widthConstraint = cell.frontContainerView.getConstraint(.Width) {
            frontViewFrame.size.width = widthConstraint.constant
            widthConstraint.constant  = view.bounds.size.width
        }
        
        frontViewFrame.origin.y        = cell.frontConstraintY.constant
        cell.frontConstraintY.constant = -view.bounds.size.height / 2 + height / 2 + insets
    }
    
    private func openBackViewConfigureConstraints(cell: BasePageCollectionCell, height: CGFloat, insets: CGFloat) {
        
        if let heightConstraint = cell.backContainerView.getConstraint(.Height) {
            backViewFrame.size.height = heightConstraint.constant
            heightConstraint.constant = view.bounds.size.height - height
        }
        
        if let widthConstraint = cell.backContainerView.getConstraint(.Width) {
            backViewFrame.size.width = widthConstraint.constant
            widthConstraint.constant = view.bounds.size.width
        }
        
        backViewFrame.origin.y        = cell.backConstraintY.constant
        cell.backConstraintY.constant = view.bounds.size.height / 2 - (view.bounds.size.height - 236) / 2 + insets
    }
    
    private func closeBackViewConfigurationConstraints(cell: BasePageCollectionCell?) {
        guard let cell = cell else { return }
        
        let heightConstraint       = cell.backContainerView.getConstraint(.Height)
        heightConstraint?.constant = backViewFrame.size.height
        
        let widthConstraint       = cell.backContainerView.getConstraint(.Width)
        widthConstraint?.constant = backViewFrame.size.width
        
        cell.backConstraintY.constant = backViewFrame.origin.y
    }
    
    private func closeFrontViewConfigurationConstraints(cell: BasePageCollectionCell?) {
        guard let cell = cell else { return }
        
        if let heightConstraint = cell.frontContainerView.getConstraint(.Height) {
            heightConstraint.constant = frontViewFrame.size.height
        }
        
        if let widthConstraint = cell.frontContainerView.getConstraint(.Width) {
            widthConstraint.constant = frontViewFrame.size.width
        }
        cell.frontConstraintY.constant = frontViewFrame.origin.y
    }
    
    private func configureCellBeforeClose(cell: BasePageCollectionCell, offset: CGFloat) {
        cell.frontConstraintY.constant -= offset
        cell.backConstraintY.constant  -= offset / 2.0
        if let heightConstraint = cell.backContainerView.getConstraint(.Height) {
            heightConstraint.constant += offset
        }
        cell.contentView.layoutIfNeeded()
    }
}
