//
//  TextFieldCollectionViewCell.swift
//  EmojiArt
//
//  Created by Jorge Encinas on 08/01/20.
//  Copyright © 2020 Jorge Encinas. All rights reserved.
//

import UIKit

class TextFieldCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var textField: UITextField!{
        didSet{
            textField.delegate = self
        }
    }
    
    var resignationHandler : (() -> Void)?
    
}

extension TextFieldCollectionViewCell : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        resignationHandler?()
    }
    
}
