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
import JGProgressHUD
import ImageSlideshow

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

extension ReuseIdentifiable { // Default implementation of ReuseIdentifiable
    static var reuseID: String { return String(describing: self) }
}

extension MatchCell: ReuseIdentifiable {}
extension MyMessageCell: ReuseIdentifiable {}
extension HerMessageCell: ReuseIdentifiable {}
extension NewChatCell: ReuseIdentifiable {}
extension ChatCell: ReuseIdentifiable {}
extension ProfileImagesCell: ReuseIdentifiable {}
extension TitleWithDescriptionCell: ReuseIdentifiable {}
extension HeaderCell: ReuseIdentifiable {}
extension SimpleMenuCell: ReuseIdentifiable {}
extension IconMenuCell: ReuseIdentifiable {}
extension PremiumMenuCell: ReuseIdentifiable {}

final class MatchCell: UITableViewCell {
    var userImageView = UIImageView()
    var nameAndAgeLabel = UILabel()
    var locationLabel = UILabel()
    var likeButton = UIButton(type: .custom)
    weak var delegate: MatchCellDelegate?
    let gradientLayer = CAGradientLayer()
    
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addShadow()
        setupCell()
        layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = userImageView.bounds
    }
    
    private func setupCell() {
        selectionStyle = .none
        let x = frame.width * 1.6
        addSubview(userImageView)
        userImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().priority(999)
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().inset(8)
            make.height.equalTo(x)
        }
        userImageView.contentMode = .scaleAspectFill
        userImageView.layer.cornerRadius = 16
        userImageView.clipsToBounds = true
        
        addSubview(locationLabel)
        locationLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().inset(24)
        }
        locationLabel.textColor = .white
        
        addSubview(nameAndAgeLabel)
        nameAndAgeLabel.snp.makeConstraints { make in
            make.leading.equalTo(locationLabel.snp.leading)
            make.bottom.equalTo(locationLabel.snp.top).offset(-3)
        }
        nameAndAgeLabel.textColor = .white
        
        addSubview(likeButton)
        likeButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(locationLabel.snp.bottom)
        }
        likeButton.setImage(#imageLiteral(resourceName: "Like_Disabled"), for: .normal)
    }
    
    private func addShadow() {
        userImageView.layer.addSublayer(gradientLayer)
        let black = UIColor.black.withAlphaComponent(0.5).cgColor
        gradientLayer.colors = [black, UIColor.clear.cgColor]
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.7)
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.opacity = 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MyMessageCell: UITableViewCell {
    var messageLabel = UILabel()
    var bubbleView = UIView()
    var timeLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupTimeLabel()
        setupBubbleView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupTimeLabel() {
        addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().inset(8)
        }
        timeLabel.textColor = .gray
        timeLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        timeLabel.text = "Time"
    }
    
    func setupBubbleView() {
        addSubview(bubbleView)
        bubbleView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.trailing.equalToSuperview().inset(8)
            make.bottom.equalTo(timeLabel.snp.top).inset(-4)
            make.leading.equalToSuperview().inset(70)
        }
        bubbleView.backgroundColor = UIColor(red:0.33, green:0.33, blue:0.33, alpha:1.00)
        bubbleView.layer.cornerRadius = 10
        
        setupMessage()
    }
    
    func setupMessage() {
        bubbleView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in make.top.bottom.leading.trailing.equalToSuperview().inset(8) }
        messageLabel.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        messageLabel.numberOfLines = 100
        messageLabel.textColor = .white
    }
}

final class HerMessageCell: UITableViewCell {
    var messageLabel = UILabel()
    var bubbleView = UIView()
    var timeLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupTimeLabel()
        setupBubbleView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupTimeLabel() {
        addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in make.leading.bottom.equalToSuperview().inset(8) }
        timeLabel.textColor = .gray
        timeLabel.font = .systemFont(ofSize: 12, weight: .regular)
        timeLabel.text = "Time"
    }
    
    func setupMessage() {
        bubbleView.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in make.edges.equalToSuperview().inset(8) }
        messageLabel.font = .systemFont(ofSize: 16.0, weight: .regular)
        messageLabel.numberOfLines = 100
    }
    
    func setupBubbleView() {
        addSubview(bubbleView)
        bubbleView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.leading.equalToSuperview().inset(8)
            make.bottom.equalTo(timeLabel.snp.top).inset(-4)
            make.trailing.equalToSuperview().inset(70)
        }
        bubbleView.backgroundColor = UIColor(red:0.97, green:0.97, blue:0.97, alpha:1.00)
        bubbleView.layer.cornerRadius = 10
        
        setupMessage()
        
    }
}

final class NewChatCell: UITableViewCell {
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
        userPictureView.snp.makeConstraints { make in
            make.size.equalTo(48)
            make.top.leading.equalToSuperview().inset(16)
        }
        userPictureView.backgroundColor = .gray
        userPictureView.layer.cornerRadius = 48 / 2
        userPictureView.clipsToBounds = true
        userPictureView.contentMode = .scaleAspectFill
    }
    
    func setupNameLabel() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(userPictureView.snp.trailing).offset(16)
            make.top.equalTo(userPictureView.snp.top)
            make.trailing.equalToSuperview().inset(80)
        }
        titleLabel.font = .systemFont(ofSize: 16.0, weight: .bold)
    }
    
    func setupSeparatorView() {
        addSubview(separatorView)
        separatorView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.leading.equalToSuperview().inset(24)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(userPictureView.snp.bottom).offset(16)
        }
        separatorView.backgroundColor = UIColor(red:0.94, green:0.94, blue:0.94, alpha:1.00)
    }
    
    func setupCtaButton() {
        addSubview(ctaButton)
        ctaButton.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.leading)
            make.bottom.equalTo(userPictureView.snp.bottom)
        }
        ctaButton.setTitle("Start Chat", for: .normal)
        ctaButton.setTitleColor(.purple, for: .normal)
        ctaButton.titleLabel?.font = .systemFont(ofSize: 16.0, weight: .regular)
        ctaButton.isUserInteractionEnabled = false
    }
    
    func setupNewTag() {
        addSubview(newTag)
        newTag.snp.makeConstraints { make in
            make.centerY.equalTo(userPictureView.snp.centerY)
            make.trailing.equalToSuperview().inset(16)
        }
        newTag.setTitle("NEW", for: .normal)
        newTag.setTitleColor(.white, for: .normal)
        newTag.titleLabel?.font = .systemFont(ofSize: 12.0, weight: .bold)
        newTag.backgroundColor = .purple
        newTag.isUserInteractionEnabled = false
        newTag.layer.cornerRadius = 10
        newTag.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    }
}

final class ChatCell: UITableViewCell {
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
        userPictureView.snp.makeConstraints { make in
            make.size.equalTo(48)
            make.leading.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(16)
        }
        userPictureView.backgroundColor = .gray
        userPictureView.layer.cornerRadius = 48 / 2
        userPictureView.clipsToBounds = true
        userPictureView.contentMode = .scaleAspectFill
    }
    
    func setupNameLabel() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(userPictureView.snp.trailing).offset(16)
            make.top.equalTo(userPictureView.snp.top)
            make.trailing.equalToSuperview().inset(80)
        }
        titleLabel.font = .systemFont(ofSize: 16.0, weight: .bold)
    }
    
    func setupMessageLabel() {
        addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.leading)
            make.trailing.equalToSuperview().inset(8)
            make.bottom.equalTo(userPictureView.snp.bottom)
        }
        messageLabel.textColor = .gray
    }
    
    func setupSeparatorView() {
        addSubview(separatorView)
        separatorView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.leading.equalToSuperview().inset(24)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(userPictureView.snp.bottom).offset(16)
        }
        separatorView.backgroundColor = UIColor(red:0.94, green:0.94, blue:0.94, alpha:1.00)
    }
    
    func setupTimeLabel() {
        addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.top.equalTo(titleLabel.snp.top)
        }
        timeLabel.textColor = .gray
        timeLabel.font = .systemFont(ofSize: 12.0, weight: .regular)
    }
}

final class IconMenuCell: UITableViewCell {
    
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
        separatorView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.leading.equalToSuperview().inset(24)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(iconImageView.snp.bottom).offset(16)
        }
        separatorView.backgroundColor = UIColor(red:0.94, green:0.94, blue:0.94, alpha:1.00)
    }
    
    func setupIconImageView() {
        addSubview(iconImageView)
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(24)
            make.leading.equalToSuperview().inset(24)
            make.top.equalToSuperview().offset(24)
        }
    }
    
    func setupTitleLabel() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.centerY.equalTo(iconImageView)
        }
        titleLabel.text = "Label"
        titleLabel.textColor = UIColor(red:0.59, green:0.59, blue:0.59, alpha:1.00)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SimpleMenuCell: UITableViewCell {
    
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
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(32)
            make.top.equalToSuperview().offset(16)
        }
        titleLabel.text = "Label"
        titleLabel.textColor = .black
    }
    
    func setupSeparatorView() {
        addSubview(separatorView)
        separatorView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.leading.equalToSuperview().inset(24)
            make.bottom.equalToSuperview()
            make.height.equalTo(1)
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
        }
        separatorView.backgroundColor = UIColor(red:0.94, green:0.94, blue:0.94, alpha:1.00)
    }
    
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//        self.backgroundColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.00)
//        UIView.animate(withDuration: 1) {
//            self.backgroundColor = .white
//        }
//    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ProfileImagesCell: UITableViewCell {
    var slideshow = ImageSlideshow()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupImageSlideshow()
        
        slideshow.backgroundColor = UIColor.white
        slideshow.pageIndicatorPosition = .init(horizontal: .center, vertical: .bottom)
        slideshow.pageIndicator?.view.tintColor = .white
        slideshow.pageIndicator?.view.tintColor = UIColor.black.withAlphaComponent(0.5)
        slideshow.contentScaleMode = .scaleAspectFill
        
        layoutIfNeeded()
    }
    
    private func setupImageSlideshow() {
        addSubview(slideshow)
        let x = frame.width * 1.6
        slideshow.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(x)
            make.bottom.equalToSuperview().inset(16).priority(999)
        }
        slideshow.snp.setLabel("IMAGESLIDESHOW_VIEW")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class TitleWithDescriptionCell: UITableViewCell {
    var titleLabel = UILabel()
    var bodyLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 32, bottom: 0, right: 32))
        }
        titleLabel.textColor = .black
        titleLabel.textColor = UIColor(red:0.59, green:0.59, blue:0.59, alpha:1.00)
        
        addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(32)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-16)
        }
        bodyLabel.numberOfLines = 30
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}

final class HeaderCell: UITableViewCell {
    var titleLabel = UILabel()
    var bodyLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 32, bottom: 0, right: 32))
        }
        titleLabel.textColor = .black
        titleLabel.font = .systemFont(ofSize: 21, weight: .medium)
        titleLabel.numberOfLines = 4
        
        addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(32)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().inset(16)
        }
        bodyLabel.numberOfLines = 5
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
}

final class PremiumMenuCell: UITableViewCell {
    
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
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(32)
            make.top.equalToSuperview().offset(16)
        }
        titleLabel.text = "Get Premium"
        titleLabel.textColor = UIColor(red:0.05, green:0.79, blue:0.40, alpha:1.00)
        titleLabel.font = .boldSystemFont(ofSize: 21.0)
        
        addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.leading)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
        subtitleLabel.text = "Unlimited Matches"
        
        addSubview(premiumButton)
        premiumButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
        }
        premiumButton.backgroundColor = UIColor(red:0.05, green:0.79, blue:0.40, alpha:1.00)
        premiumButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        premiumButton.layer.cornerRadius = 16
        premiumButton.clipsToBounds = true
        premiumButton.setTitle("2.99", for: .normal)
    }
    
    func setupSeparatorView() {
        addSubview(separatorView)
        separatorView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.leading.equalToSuperview().inset(24)
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
