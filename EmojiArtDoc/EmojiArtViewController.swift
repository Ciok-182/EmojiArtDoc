//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Jorge Encinas on 16/12/19.
//  Copyright © 2019 Jorge Encinas. All rights reserved.
//

import UIKit

class EmojiArtViewController: UIViewController, EmojiArtViewDelegate {
    
    var imageFetcher: ImageFetcher!
    var emojis = "🐼🛥🌾💀🍄🌲🌴🥀🌧☁️🌩🦃🐇🐆🦜🦥🕊🦅🦆🐝🦒🦌🐿".map { String($0) }
    var suppresBadURLWarnings = false
    
    lazy var emojiArtView: EmojiArtView = {
        let eav = EmojiArtView()
        eav.delegate = self
        return eav
    }()
    
    // MARK: - EmojiArtViewDelegate
    
    func emojiArtViewDidChange(_ sender: EmojiArtView) {
        documentChanged()
    }

    private var documentObserver: NSObjectProtocol?
    
    private var addingEmoji = false
    
    @IBAction func addEmoji(_ sender: UIButton) {
        addingEmoji = true
        emojiCollectionView.reloadSections(IndexSet(integer: 0))
    }
    
    @IBOutlet weak var dropZone: UIView!{
        didSet{
            dropZone.addInteraction(UIDropInteraction(delegate: self))
        }
    }
    
    @IBOutlet weak var scrollView: UIScrollView!{
        didSet{
            scrollView.minimumZoomScale = 0.1
            scrollView.maximumZoomScale = 5.0
            scrollView.delegate = self
            scrollView.addSubview(emojiArtView)
        }
    }
    
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView?{
        return emojiArtView
    }
    
    private var _emojiArtBackgroundImageURL: URL?
    
    var emojiArtBackgroundImage: (url: URL?, image: UIImage?){
        get{
            return (_emojiArtBackgroundImageURL, emojiArtView.backgroundImage)
        }
        set{
            //print("Set: \(String(describing: newValue.url))")
            _emojiArtBackgroundImageURL = newValue.url
            scrollView?.zoomScale = 1.0
            emojiArtView.backgroundImage = newValue.image
            let size = newValue.image?.size ?? CGSize.zero
            emojiArtView.frame = CGRect(origin: CGPoint.zero, size: size)
            scrollView?.contentSize = size
            scrollViewHeight?.constant = size.height
            scrollViewWidth?.constant = size.width
            if let dropZone = self.dropZone, size.width > 0, size.height > 0{
                scrollView?.zoomScale = max(dropZone.bounds.size.width / size.width, dropZone.bounds.size.height / size.height)
            }
        }
    }
    
    @IBOutlet weak var emojiCollectionView: UICollectionView!{
        didSet{
            emojiCollectionView.dataSource = self
            emojiCollectionView.delegate = self
            emojiCollectionView.dragDelegate = self
            emojiCollectionView.dropDelegate = self
            emojiCollectionView.dragInteractionEnabled = true //it't true by defaul on ipad but false on iphone so now its gonna be true for both
        }
    }
    
    private var font: UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(60))
    }
    
    
    var document: EmojiArtDocument?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // start monitoring our document's documentState
        documentObserver = NotificationCenter.default.addObserver(
            forName: UIDocument.stateChangedNotification,
            object: document,
            queue: OperationQueue.main,
            using: { notification in
                print("DocumentState changed to \(self.document!.documentState)")
            }
        )
        
        
        // whenever we appear, we'll open our document
        // (might want to close it in viewDidDisappear, by the way)
        document?.open { success in
            if success {
                self.title = self.document?.localizedName
                // update our Model from the document's Model
                self.emojiArt = self.document?.emojiArt
                // now that our document is open
                // start watching our EmojiArtView for changes
                // so we can let our document know when it has changes
                // that need to be autosaved
                /*self.emojiArtViewObserver = NotificationCenter.default.addObserver(
                    forName: .EmojiArtViewDidChange,
                    object: self.emojiArtView,
                    queue: OperationQueue.main,
                    using: { notification in
                        self.documentChanged()
                    }
                )*/
            }
        }
        
    }
    
    private func documentChanged() {
        document?.emojiArt = emojiArt
        if document?.emojiArt != nil {
            document?.updateChangeCount(.done)
        }
    }
    
    /*@IBAction func saveAction(_ sender: UIBarButtonItem? = nil) {
        document?.emojiArt = emojiArt
        if document?.emojiArt != nil {
            document?.updateChangeCount(.done)
        }
    }*/
    
    @IBAction func closeAction(_ sender: UIBarButtonItem) {
        
        documentChanged()
        
        if document?.emojiArt != nil {
            document?.thumbnail = emojiArtView.snapshot
        }
        
        dismiss(animated: true, completion: {

            self.document?.close(completionHandler: { success in
                if let observer = self.documentObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
            } )

        })
        
    }
    
    private func presentBadURLWarning(for url: URL?){
        if !suppresBadURLWarnings {
            let alert = UIAlertController(
                title: "Image transfer fail",
                message: "Couldn't transfer the dropped image from its source\n Show this warning in the future?",
                preferredStyle: .alert)
            
            
            alert.addAction(UIAlertAction(title: "Keep warning", style: .default, handler: nil))
            
            alert.addAction(UIAlertAction(title: "Stop warning", style: .destructive, handler: { action in
                self.suppresBadURLWarnings = true
            }))
            
            present(alert, animated: true)
        }
        
    }
    
    // MARK: - Model
    var emojiArt: EmojiArt? {
        get {
            if let url = emojiArtBackgroundImage.url{
                let emojis = emojiArtView.subviews.compactMap {$0 as? UILabel}.compactMap { EmojiArt.EmojiInfo(label: $0) }
                return EmojiArt(url: url, emojis: emojis)
            }
            return nil
        }
        set {
            emojiArtBackgroundImage = (nil, nil)
            emojiArtView.subviews.compactMap {$0 as? UILabel}.forEach { $0.removeFromSuperview()}
            
            if let url = newValue?.url {
                imageFetcher = ImageFetcher(fetch: url, handler: {(url, image) in
                    DispatchQueue.main.async {
                        //print("Se recibe url \(url)")
                        self.emojiArtBackgroundImage = (url, image)
                        newValue?.emojis.forEach {
                            let attributedText = $0.text.attributedString(withTextStyle: .body, ofSize: CGFloat($0.size))
                            self.emojiArtView.addLabel(with: attributedText, centeredAt: CGPoint(x: $0.x, y: $0.y))
                        }
                    }
                })
            }
        }
    }
    

}

// MARK: - EmojiArt

extension EmojiArt.EmojiInfo {
    init?(label: UILabel) {
        if let attributedText = label.attributedText, let font = attributedText.font {
            x = Int(label.center.x)
            y = Int(label.center.y)
            text = attributedText.string
            size = Int(font.pointSize)
        } else {
            return nil
        }
    }
}

// MARK: - UIDropInteractionDelegate
extension EmojiArtViewController: UIDropInteractionDelegate{
    
    //Solo si el objeto que estas arrojando es del tipo de clases NSURL y UIIMage continuara con sessionDidUpdate
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        print("dropInteraction canHandle")
        return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
    }
    
    //Todo lo q se deje en la zona se va copiar ya que puede recibir de otras apps
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        print("dropInteraction sessionDidUpdate")
        return UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        print("dropInteraction performDrop")
        self.imageFetcher = ImageFetcher() { (url, image) in
            DispatchQueue.main.async {
                self.emojiArtBackgroundImage = (url, image)
                self.documentChanged()
            }
        }
        
        session.loadObjects(ofClass: NSURL.self, completion: {nsurls in
            if let url = nsurls.first as? URL{
                //self.imageFetcher.fetch(url)
                DispatchQueue.global(qos: .userInitiated).async {
                    if let imageData = try? Data(contentsOf: url.imageURL), let image = UIImage(data: imageData){
                        print("loadObjects OK")
                        DispatchQueue.main.async {
                            self.emojiArtBackgroundImage = (url, image)
                            self.documentChanged()
                        }
                    } else {
                        print("loadObjects BAD")
                        DispatchQueue.main.async {
                            self.presentBadURLWarning(for: url)
                        }
                    }
                }
            }
        })
        
        session.loadObjects(ofClass: UIImage.self, completion: {images in
            if let image = images.first as? UIImage{
                self.imageFetcher.backup = image
            }
        })
    }
    
}

// MARK: - UIScrollViewDelegate
extension EmojiArtViewController: UIScrollViewDelegate{
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewWidth.constant = scrollView.contentSize.width
        scrollViewHeight.constant = scrollView.contentSize.height
    }
    
}

// MARK: - UICollectionViewDelegate
extension EmojiArtViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
            case 0: return 1
            case 1: return emojis.count
            default: return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 1{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
            if let emojiCell = cell as? EmojiCollectionViewCell{
                let text = NSAttributedString(string: emojis[indexPath.item], attributes: [.font : font])
                emojiCell.label.attributedText = text
            }
            return cell
        } else if addingEmoji{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiImputCell", for: indexPath)
            if let inputCell = cell as? TextFieldCollectionViewCell {
                inputCell.resignationHandler = { [weak self, unowned inputCell] in
                    if let text = inputCell.textField.text{
                        self?.emojis = (text.map { String($0) } + self!.emojis).uniquified
                    }
                    self?.addingEmoji = false
                    self?.emojiCollectionView.reloadData()
                }
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddEmojiButtonCell", for: indexPath)
            return cell
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if addingEmoji && indexPath.section == 0 {
            return CGSize(width: 300, height: 80)
        } else {
            return CGSize(width: 80, height: 80)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let inputCell = cell as? TextFieldCollectionViewCell {
            inputCell.textField.becomeFirstResponder()
        }
    }
    
}

// MARK: - UICollectionViewDragDelegate
extension EmojiArtViewController: UICollectionViewDragDelegate{
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        if !addingEmoji, let attributedString = (emojiCollectionView.cellForItem(at: indexPath) as? EmojiCollectionViewCell)?.label.attributedText{
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: attributedString))
            dragItem.localObject = attributedString
            return [dragItem]
        } else{
            return []
        }
    }
    
    //Start the drag
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView //(1) Para despues cuando se haga el drop, saber si estamos haciendo drop en nuestra collection de emojis y no dejarlo solo hacer .move
        return dragItems(at: indexPath)
    }
    
    //agregar multiples
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
}

// MARK: - UICollectionViewDropDelegate
extension EmojiArtViewController: UICollectionViewDropDelegate{
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if let indexPath = destinationIndexPath, indexPath.section == 1{
            let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView //(1)
            return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal(operation: .cancel)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        
        
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0) //drop in our own collectionView
        for item in coordinator.items{
            if let sourceIndexPath = item.sourceIndexPath{ // si traemos idexPath es pq es nuestro collectionView
                if let attributedString = item.dragItem.localObject as? NSAttributedString{
                    collectionView.performBatchUpdates({
                        emojis.remove(at: sourceIndexPath.item)
                        emojis.insert(attributedString.string, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    })
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            } else { //source doesn't have an index, so it's coming from outside our collectionView
                let placeholderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell"))
                item.dragItem.itemProvider.loadObject(ofClass: NSAttributedString.self) { provider, error in
                    DispatchQueue.main.async {
                        if let attributedString = provider as? NSAttributedString{
                            placeholderContext.commitInsertion(dataSourceUpdates: { insertionIndexPath in
                                self.emojis.insert(attributedString.string, at: insertionIndexPath.item)
                            })
                        } else {
                            placeholderContext.deletePlaceholder()
                        }
                        
                    }
                }
            }
        }
    }
    
}
