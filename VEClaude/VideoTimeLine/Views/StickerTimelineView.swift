//
//  StickerTimelineView.swift
//  VEClaude
//
//  Created by Claude on 25/8/25.
//

import UIKit
import AVFoundation

class StickerTimelineView: UIView {
    
    // MARK: - Properties
    private(set) var scrollView: UIScrollView!
    private(set) var contentView: UIView!
    private(set) var stickerContentView: UIView!
    
    private(set) var stickerViews: [StickerRangeView] = []
    
    var widthPerSecond: CGFloat = 60
    var totalDuration: CGFloat = 0 {
        didSet {
            updateContentSize()
        }
    }
    
    private var contentWidthConstraint: NSLayoutConstraint?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .systemGray6
        
        setupScrollView()
        setupContentView()
        setupStickerContentView()
        addDefaultSticker()
    }
    
    private func setupScrollView() {
        scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupContentView() {
        contentView = UIView()
        contentView.backgroundColor = .clear
        scrollView.addSubview(contentView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentWidthConstraint = contentView.widthAnchor.constraint(equalToConstant: 300) // Initial width
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            contentWidthConstraint!
        ])
    }
    
    private func setupStickerContentView() {
        stickerContentView = UIView()
        stickerContentView.backgroundColor = .clear
        contentView.addSubview(stickerContentView)
        
        stickerContentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stickerContentView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            stickerContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stickerContentView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stickerContentView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5)
        ])
    }
    
    private func addDefaultSticker() {
        let defaultSticker = StickerRangeView()
        defaultSticker.setupAsDefault()
        addStickerView(defaultSticker, at: CMTime.zero, duration: CMTime(seconds: 3.0, preferredTimescale: 600))
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        let inset = bounds.width * 0.5
        scrollView.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
    }
    
    // MARK: - Public Methods
    func updateDuration(_ duration: CGFloat) {
        totalDuration = duration
    }
    
    func addStickerView(_ stickerView: StickerRangeView, at startTime: CMTime, duration: CMTime) {
        stickerViews.append(stickerView)
        stickerContentView.addSubview(stickerView)
        
        let startPosition = CGFloat(startTime.seconds) * widthPerSecond
        let width = CGFloat(duration.seconds) * widthPerSecond
        
        stickerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stickerView.topAnchor.constraint(equalTo: stickerContentView.topAnchor),
            stickerView.bottomAnchor.constraint(equalTo: stickerContentView.bottomAnchor),
            stickerView.leadingAnchor.constraint(equalTo: stickerContentView.leadingAnchor, constant: startPosition),
            stickerView.widthAnchor.constraint(equalToConstant: width)
        ])
        
        stickerView.startTime = startTime
        stickerView.duration = duration
    }
    
    func removeStickerView(_ stickerView: StickerRangeView) {
        if let index = stickerViews.firstIndex(of: stickerView) {
            stickerViews.remove(at: index)
            stickerView.removeFromSuperview()
        }
    }
    
    func removeAllStickerViews() {
        stickerViews.forEach { $0.removeFromSuperview() }
        stickerViews.removeAll()
    }
    
    private func updateContentSize() {
        let contentWidth = max(totalDuration * widthPerSecond, 300) // Minimum width of 300
        contentWidthConstraint?.constant = contentWidth
    }
}

// MARK: - StickerRangeView
class StickerRangeView: UIView {
    
    var startTime: CMTime = CMTime.zero
    var duration: CMTime = CMTime.zero
    
    private var backgroundView: UIView!
    private var iconImageView: UIImageView!
    private var titleLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        setupBackgroundView()
        setupIconImageView()
        setupTitleLabel()
        setupGestures()
    }
    
    private func setupBackgroundView() {
        backgroundView = UIView()
        backgroundView.backgroundColor = .systemBlue.withAlphaComponent(0.7)
        backgroundView.layer.cornerRadius = 8
        backgroundView.layer.borderWidth = 1
        backgroundView.layer.borderColor = UIColor.systemBlue.cgColor
        addSubview(backgroundView)
        
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupIconImageView() {
        iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .white
        
        // Create a default sticker icon using SF Symbols
        if let stickerImage = UIImage(systemName: "face.smiling") {
            iconImageView.image = stickerImage
        }
        
        backgroundView.addSubview(iconImageView)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor, constant: -8),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    private func setupTitleLabel() {
        titleLabel = UILabel()
        titleLabel.text = "Sticker"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 10, weight: .medium)
        titleLabel.textAlignment = .center
        backgroundView.addSubview(titleLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -4)
        ])
    }
    
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }
    
    @objc private func handleTap() {
        // Handle sticker selection
        setSelected(true)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        // Handle sticker dragging/repositioning
        switch gesture.state {
        case .began:
            setSelected(true)
        case .changed:
            let translation = gesture.translation(in: superview)
            transform = CGAffineTransform(translationX: translation.x, y: 0)
        case .ended, .cancelled:
            // Snap to timeline position
            UIView.animate(withDuration: 0.2) {
                self.transform = .identity
            }
        default:
            break
        }
    }
    
    func setupAsDefault() {
        // Configure as default sticker
        if let stickerImage = UIImage(systemName: "star.fill") {
            iconImageView.image = stickerImage
        }
        titleLabel.text = "Default"
        backgroundView.backgroundColor = .systemOrange.withAlphaComponent(0.7)
        backgroundView.layer.borderColor = UIColor.systemOrange.cgColor
    }
    
    func setSelected(_ selected: Bool) {
        UIView.animate(withDuration: 0.2) {
            if selected {
                self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                self.backgroundView.layer.borderWidth = 2
            } else {
                self.transform = .identity
                self.backgroundView.layer.borderWidth = 1
            }
        }
    }
}