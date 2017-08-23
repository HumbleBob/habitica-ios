//
//  RewardViewController.swift
//  Habitica
//
//  Created by Phillip on 21.08.17.
//  Copyright © 2017 Phillip Thelen. All rights reserved.
//

import UIKit

class RewardViewController: HRPGBaseCollectionViewController, NSFetchedResultsControllerDelegate, UICollectionViewDelegateFlowLayout {
    
    lazy var fetchRequest: NSFetchRequest<MetaReward> = {
        return NSFetchRequest<MetaReward>(entityName: "MetaReward")
    }()
    
    lazy var fetchedResultsController: NSFetchedResultsController<MetaReward> = {
        self.fetchRequest.sortDescriptors = [NSSortDescriptor(key: "type", ascending: false)]
        
        let frc = NSFetchedResultsController(
            fetchRequest: self.fetchRequest,
            managedObjectContext: self.managedObjectContext,
            sectionNameKeyPath: "type",
            cacheName: nil)
        
        frc.delegate = self
        
        return frc
    }()
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let customRewardNib = UINib.init(nibName: "CustomRewardCell", bundle: .main)
        collectionView?.register(customRewardNib, forCellWithReuseIdentifier: "CustomRewardCell")
        let inAppRewardNib = UINib.init(nibName: "InAppRewardCell", bundle: .main)
        collectionView?.register(inAppRewardNib, forCellWithReuseIdentifier: "InAppRewardCell")
        
        collectionView?.alwaysBounceVertical = true
        refreshControl.tintColor = UIColor.purple400()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        collectionView?.addSubview(refreshControl)
        
        do {
            try? self.fetchedResultsController.performFetch()
        }
    }
    
    func refresh() {
        HRPGManager.shared().fetchBuyableRewards({[weak self] in
            self?.refreshControl.endRefreshing()
        }) {[weak self] in
            self?.refreshControl.endRefreshing()
        }
    }
    
    private var editedReward: Reward?
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomRewardCell", for: indexPath)
            if let rewardCell = cell as? CustomRewardCell, let reward = self.fetchedResultsController.object(at: indexPath) as? Reward {
                rewardCell.configure(reward: reward)
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InAppRewardCell", for: indexPath)
            if let rewardCell = cell as? InAppRewardCell {
                rewardCell.configure(reward: self.fetchedResultsController.object(at: indexPath), manager: HRPGManager.shared())
            }
            return cell
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (indexPath.section == 0), let reward = self.fetchedResultsController.object(at: indexPath) as? Reward {
            editedReward = reward
            performSegue(withIdentifier: "FormSegue", sender: self)
        } else {
            let storyboard = UIStoryboard(name: "BuyModal", bundle: nil)
            if let viewController = storyboard.instantiateViewController(withIdentifier: "HRPGBuyItemModalViewController") as? HRPGBuyItemModalViewController {
                viewController.modalTransitionStyle = .crossDissolve
                self.present(viewController, animated: true, completion: nil)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: self.view.frame.size.width, height: 60)
        } else {
            return CGSize(width: 80, height: 108)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if section == 0 {
            return 0
        } else {
            return 8
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if section == 0 {
            return 0
        } else {
            return 8
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if section == 0 {
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        } else {
            return UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let indexPath = indexPath, let newIndexPath = newIndexPath else {
            return
        }
        switch type {
        case .delete:
            collectionView?.deleteItems(at: [indexPath])
            break
        case .insert:
            collectionView?.insertItems(at: [indexPath])
            break
        case .move:
            collectionView?.moveItem(at: indexPath, to: newIndexPath)
            break
        case .update:
            collectionView?.reloadItems(at: [indexPath])
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FormSegue", let reward = self.editedReward {
            guard let destinationController = segue.destination as? UINavigationController else {
                return
            }
            guard let formController = destinationController.topViewController as? RewardFormController else {
                return
            }

            formController.editReward = true
            formController.reward = reward
            self.editedReward = nil
        }
    }
    
    @IBAction func undindToList(segue: UIStoryboardSegue) {}
    
    @IBAction func unwindToSaveReward(segue: UIStoryboardSegue) {
        if let sourceViewController = segue.source as? RewardFormController {
            if sourceViewController.editReward {
                HRPGManager.shared().update(sourceViewController.reward, onSuccess: nil, onError: nil)
            } else {
                HRPGManager.shared().createReward(sourceViewController.reward, onSuccess: nil, onError: nil)
            }
        }
    }
}
