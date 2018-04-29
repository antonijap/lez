//
//  CustomCells.swift
//  Lez
//
//  Created by Antonija Pek on 03/04/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import UIKit
import Firebase
import SnapKit
import moa
import SkeletonView
import JGProgressHUD

enum MenuSections {
    case titleWithDescription
    case profileImages
    case simpleMenu
    case iconMenu
    case premiumMenu
    case headerCell
}

enum ChatSections {
    case newChat
    case chat
}
enum MessagesSections {
    case myMessageCell
    case herMessageCell
}

protocol ReuseIdentifiable {
    static var reuseID: String { get }
}

extension MyMessageCell: ReuseIdentifiable {
    static var reuseID: String { return String(describing: self) }
}

extension HerMessageCell: ReuseIdentifiable {
    static var reuseID: String { return String(describing: self) }
}

extension NewChatCell: ReuseIdentifiable {
    static var reuseID: String { return String(describing: self) }
}

extension ChatCell: ReuseIdentifiable {
    static var reuseID: String { return String(describing: self) }
}

extension ProfileImagesCell: ReuseIdentifiable {
    static var reuseID: String { return String(describing: self) }
}

extension TitleWithDescriptionCell: ReuseIdentifiable {
    static var reuseID: String { return String(describing: self) }
}

extension HeaderCell: ReuseIdentifiable {
    static var reuseID: String { return String(describing: self) }
}

extension SimpleMenuCell: ReuseIdentifiable {
    static var reuseID: String { return String(describing: self) }
}

extension IconMenuCell: ReuseIdentifiable {
    static var reuseID: String { return String(describing: self) }
}

extension PremiumMenuCell: ReuseIdentifiable {
    static var reuseID: String { return String(describing: self) }
}

class MyMessageCell: UITableViewCell {
    var messageLabel = UILabel()
    var bubbleView = UIView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupBubbleView()
        layoutIfNeeded()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupBubbleView() {
        addSubview(bubbleView)
        bubbleView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(4)
            make.right.equalToSuperview().inset(8)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().inset(70)
        }
        bubbleView.backgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.00)
        bubbleView.layer.cornerRadius = 10
        
        setupMessage()
    }
    
    func setupMessage() {
        bubbleView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { (make) in
            make.top.bottom.left.right.equalToSuperview().inset(8)
        }
        messageLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        messageLabel.numberOfLines = 100
    }
}

class HerMessageCell: UITableViewCell {
    var messageLabel = UILabel()
    var bubbleView = UIView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupBubbleView()
        layoutIfNeeded()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupBubbleView() {
        addSubview(bubbleView)
        bubbleView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(4)
            make.left.equalToSuperview().inset(8)
            make.bottom.equalToSuperview()
            make.right.equalToSuperview().inset(70)
        }
        bubbleView.backgroundColor = UIColor(red:0.91, green:1.00, blue:0.94, alpha:1.00)
        bubbleView.layer.cornerRadius = 10
        
        setupMessage()
    }
    
    func setupMessage() {
        bubbleView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(16)
        }
        messageLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        messageLabel.numberOfLines = 100
    }
}

class NewChatCell: UITableViewCell {
    var userPictureView = UIImageView()
    var titleLabel = UILabel()
    let separatorView = UIView()
    let ctaButton = UIButton()
    let newTag = UIButton()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUserPictureView()
        setupNameLabel()
        setupSeparatorView()
        setupCtaButton()
        setupNewTag()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUserPictureView() {
        addSubview(userPictureView)
        userPictureView.snp.makeConstraints { (make) in
            make.size.equalTo(64)
            make.left.equalToSuperview().inset(24)
            make.top.equalToSuperview().offset(24)
        }
        userPictureView.makeOvalWithImage(UIImage(named: "Taylor")!)
    }
    
    func setupNameLabel() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(userPictureView.snp.right).offset(16)
            make.top.equalTo(userPictureView.snp.top).inset(8)
            make.right.equalToSuperview().inset(65)
        }
        titleLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
    }
    
    func setupSeparatorView() {
        addSubview(separatorView)
        separatorView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.left.equalToSuperview().inset(24)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(userPictureView.snp.bottom).offset(16)
        }
        separatorView.backgroundColor = UIColor(red:0.94, green:0.94, blue:0.94, alpha:1.00)
    }
    
    func setupCtaButton() {
        addSubview(ctaButton)
        ctaButton.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.left)
            make.bottom.equalTo(userPictureView.snp.bottom).inset(8)
        }
        ctaButton.setTitle("Start Chat", for: .normal)
        ctaButton.setTitleColor(.purple, for: .normal)
        ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
    }
    
    func setupNewTag() {
        addSubview(newTag)
        newTag.snp.makeConstraints { (make) in
            make.centerY.equalTo(userPictureView.snp.centerY)
            make.right.equalToSuperview().inset(16)
        }
        newTag.setTitle("NEW", for: .normal)
        newTag.setTitleColor(.white, for: .normal)
        newTag.titleLabel?.font = UIFont.systemFont(ofSize: 12.0, weight: .bold)
        newTag.backgroundColor = .purple
        newTag.isUserInteractionEnabled = false
        newTag.layer.cornerRadius = 10
        newTag.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    }
}

class ChatCell: UITableViewCell {
    var userPictureView = UIImageView()
    var titleLabel = UILabel()
    let separatorView = UIView()
    var messageLabel = UILabel()
    var timeLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupUserPictureView()
        setupSeparatorView()
        setupNameLabel()
        setupMessageLabel()
        setupTimeLabel()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUserPictureView() {
        addSubview(userPictureView)
        userPictureView.snp.makeConstraints { (make) in
            make.size.equalTo(48)
            make.left.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(16)
        }
        userPictureView.backgroundColor = .gray
        userPictureView.layer.cornerRadius = 48 / 2
        userPictureView.clipsToBounds = true
    }
    
    func setupNameLabel() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(userPictureView.snp.right).offset(16)
            make.top.equalTo(userPictureView.snp.top)
            make.right.equalToSuperview().inset(80)
        }
        titleLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .bold)
    }
    
    func setupMessageLabel() {
        addSubview(messageLabel)
        messageLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.left)
            make.right.equalToSuperview().inset(8)
            make.bottom.equalTo(userPictureView.snp.bottom)
        }
        messageLabel.textColor = .gray
    }
    
    func setupSeparatorView() {
        addSubview(separatorView)
        separatorView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.left.equalToSuperview().inset(24)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(userPictureView.snp.bottom).offset(16)
        }
        separatorView.backgroundColor = UIColor(red:0.94, green:0.94, blue:0.94, alpha:1.00)
    }
    
    func setupTimeLabel() {
        addSubview(timeLabel)
        timeLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(16)
            make.top.equalTo(titleLabel.snp.top)
        }
        timeLabel.textColor = .gray
        timeLabel.font = UIFont.systemFont(ofSize: 12.0, weight: .regular)
    }
}

class IconMenuCell: UITableViewCell {
    
    let iconImageView = UIImageView()
    let titleLabel = UILabel()
    let separatorView = UIView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupIconImageView()
        setupTitleLabel()
        setupSeparatorView()
    }
    
    func setupSeparatorView() {
        addSubview(separatorView)
        separatorView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.left.equalToSuperview().inset(24)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(iconImageView.snp.bottom).offset(16)
        }
        separatorView.backgroundColor = UIColor(red:0.94, green:0.94, blue:0.94, alpha:1.00)
    }
    
    func setupIconImageView() {
        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.size.equalTo(24)
            make.left.equalToSuperview().inset(24)
            make.top.equalToSuperview().offset(24)
        }
    }
    
    func setupTitleLabel() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconImageView.snp.right).offset(8)
            make.centerY.equalTo(iconImageView)
        }
        titleLabel.text = "Label"
        titleLabel.textColor = UIColor(red:0.59, green:0.59, blue:0.59, alpha:1.00)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SimpleMenuCell: UITableViewCell {
    
    let titleLabel = UILabel()
    let separatorView = UIView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupTitleLabelNoIcon()
        setupSeparatorView()
    }
    
    func setupTitleLabelNoIcon() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(32)
            make.top.equalToSuperview().offset(16)
        }
        titleLabel.text = "Label"
        titleLabel.textColor = .black
    }
    
    func setupSeparatorView() {
        addSubview(separatorView)
        separatorView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.left.equalToSuperview().inset(24)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
        }
        separatorView.backgroundColor = UIColor(red:0.94, green:0.94, blue:0.94, alpha:1.00)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ProfileImagesCell: UITableViewCell {
    var scrollView = UIScrollView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupScrollView()
        layoutIfNeeded()
    }
    
    private func setupScrollView() {
        addSubview(scrollView)
        let x = frame.width * 1.6
        scrollView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(x)
            make.bottom.equalToSuperview().inset(16).priority(999)
        }
        scrollView.snp.setLabel("SCROLL_VIEW")
        scrollView.auk.settings.contentMode = .scaleAspectFill
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TitleWithDescriptionCell: UITableViewCell {
    var titleLabel = UILabel()
    var bodyLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 32, bottom: 0, right: 32))
        }
        titleLabel.textColor = .black
        titleLabel.textColor = UIColor(red:0.59, green:0.59, blue:0.59, alpha:1.00)
        
        addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(32)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-16)
        }
        bodyLabel.numberOfLines = 5
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}

class HeaderCell: UITableViewCell {
    var titleLabel = UILabel()
    var bodyLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 32, bottom: 0, right: 32))
        }
        titleLabel.textColor = .black
        titleLabel.textColor = UIColor(red:0.59, green:0.59, blue:0.59, alpha:1.00)
        titleLabel.font = UIFont.systemFont(ofSize: 21.0)
        titleLabel.numberOfLines = 2
        
        addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(32)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().inset(16)
        }
        bodyLabel.numberOfLines = 5
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}

class PremiumMenuCell: UITableViewCell {
    
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let separatorView = UIView()
    let premiumButton = UIButton()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupLabels()
        setupSeparatorView()
    }
    
    func setupLabels() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(32)
            make.top.equalToSuperview().offset(16)
        }
        titleLabel.text = "Get Premium"
        titleLabel.textColor = UIColor(red:0.05, green:0.79, blue:0.40, alpha:1.00)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 21.0)
        
        addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.left)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
        subtitleLabel.text = "Unlimited Matches"
        
        addSubview(premiumButton)
        premiumButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        premiumButton.backgroundColor = UIColor(red:0.05, green:0.79, blue:0.40, alpha:1.00)
        premiumButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        premiumButton.layer.cornerRadius = 10
        premiumButton.setTitle("2.99", for: .normal)
    }
    
    func setupSeparatorView() {
        addSubview(separatorView)
        separatorView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.left.equalToSuperview().inset(24)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
        }
        separatorView.backgroundColor = UIColor(red:0.94, green:0.94, blue:0.94, alpha:1.00)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
