//
//  DocumentInfoViewController.swift
//  EmojiArtDoc
//
//  Created by Jorge Encinas on 23/01/20.
//  Copyright © 2020 Jorge Encinas. All rights reserved.
//

import UIKit

class DocumentInfoViewController: UIViewController {
    
    var document: EmojiArtDocument?{
        didSet { updateUI() }
    }
    
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var topLevelView: UIStackView!
    @IBOutlet weak var returnToDocument: UIButton!
    
    
    @IBOutlet weak var thumbnailAspectRatio: NSLayoutConstraint!
    
    @IBAction func done() {
        presentingViewController?.dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let fittedSize = topLevelView?.sizeThatFits(UIView.layoutFittingCompressedSize){
            preferredContentSize = CGSize(width: fittedSize.width + 30, height: fittedSize.height + 30)
        }
    }
    
    private let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    private func updateUI() {
        
        if sizeLabel != nil, createdLabel != nil,
            let url = document?.fileURL,
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path){
            sizeLabel.text = "\(attributes[.size] ?? 0) bytes"
            if let created = attributes[.creationDate] as? Date {
                createdLabel.text = shortDateFormatter.string(from: created)
            }
        }
        
        if thumbnailImageView != nil, let thumbnail = document?.thumbnail, thumbnailAspectRatio != nil {
            thumbnailImageView.image = thumbnail
            thumbnailImageView.removeConstraint(thumbnailAspectRatio)
            
            thumbnailAspectRatio = NSLayoutConstraint(
                item: thumbnailImageView!,
                attribute: .width,
                relatedBy: .equal,
                toItem: thumbnailImageView,
                attribute: .height,
                multiplier: thumbnail.size.width / thumbnail.size.height,
                constant: 0
            )

            thumbnailImageView.addConstraint(thumbnailAspectRatio)

        }
        
        if presentationController is UIPopoverPresentationController {
            thumbnailImageView?.isHidden = true
            returnToDocument?.isHidden = true
            view.backgroundColor = .clear
        }
        
    }
    

}
