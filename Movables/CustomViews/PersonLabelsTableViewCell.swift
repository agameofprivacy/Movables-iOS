//
//  PersonLabelsTableViewCell.swift
//  Movables
//
//  Created by Eddie Chen on 6/13/18.
//  Copyright © 2018 Movables, Inc. All rights reserved.
//

import UIKit

class PersonLabelsTableViewCell: UITableViewCell {

    var profileImageView: UIImageView!
    var titleLabel: UILabel!
    var subtitleLabel: UILabel!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        
        profileImageView = UIImageView(frame: .zero)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.backgroundColor = Theme().keyTint.withAlphaComponent(0.1)
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 25
        contentView.addSubview(profileImageView)
        
        titleLabel = UILabel(frame: .zero)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.numberOfLines = 1
        contentView.addSubview(titleLabel)
        
        subtitleLabel = UILabel(frame: .zero)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.numberOfLines = 1
        contentView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            profileImageView.heightAnchor.constraint(equalToConstant: 50),
            profileImageView.widthAnchor.constraint(equalToConstant: 50),
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
            profileImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
            profileImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 15),
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: profileImageView.topAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -18),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])
    }
    
}
