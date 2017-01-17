//
//  QuestionTableCell.swift
//  MaziRecorder
//
//  Created by Lutz on 16/01/17.
//  Copyright © 2017 Erich Grunewald. All rights reserved.
//

import Foundation
import UIKit

class QuestionTableCell : UITableViewCell {

    let buttonWidth = CGFloat(100)

    var nameLabel: UILabel!
    var deleteButton : UIButton!

    var question: String? {
        didSet {
            if let str = question {
                nameLabel.text = str
                setNeedsLayout()
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        nameLabel = UILabel(frame: CGRect.zero)
        nameLabel.textAlignment = .left
        nameLabel.textColor = UIColor.black
        contentView.addSubview(nameLabel)

        deleteButton = MaziUIButtonSmall()
        deleteButton.setTitle("Delete", for: UIControlState.normal)
        contentView.addSubview(deleteButton)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

    }

    override func layoutSubviews() {
        super.layoutSubviews()
        deleteButton.frame = CGRect( x: MaziStyle.textPadding + frame.width - buttonWidth , y: MaziStyle.textPadding , width: buttonWidth - MaziStyle.textPadding*2, height: frame.height - MaziStyle.textPadding*2)
        nameLabel.frame = CGRect( x: MaziStyle.textPadding , y: MaziStyle.textPadding , width: frame.width - deleteButton.frame.width - MaziStyle.textPadding, height: frame.height - 2*MaziStyle.textPadding)
    }
}
