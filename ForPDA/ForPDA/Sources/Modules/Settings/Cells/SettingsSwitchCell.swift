//
//  SettingsSwitchCell.swift
//  ForPDA
//
//  Created by Subvert on 22.06.2023.
//

import UIKit

final class SettingsSwitchCell: UITableViewCell {
    
    // MARK: - Views
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: UIFont.labelFontSize - 1, weight: .medium)
        label.textColor = label.textColor.withAlphaComponent(0.8)
        return label
    }()
    
    private lazy var mySwitch: UISwitch = {
        let mySwitch = UISwitch()
        mySwitch.addTarget(self, action: #selector(mySwitchTapped(_:)), for: .valueChanged)
        return mySwitch
    }()
    
    // MARK: - Properties
    
    var switchTapped: ((Bool) -> Void)?
    
    // MARK: - Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        addSubviews()
        makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: - Actions
    
    @objc private func mySwitchTapped(_ sender: UISwitch) {
        switchTapped?(sender.isOn)
    }
    
    // MARK: - Public Functions
    
    func set(with model: SwitchOption) {
        titleLabel.text = model.title
        mySwitch.isOn = model.isOn
    }
    
    func forceSwitch(to state: Bool) {
        mySwitch.isOn = state
    }
    
    // MARK: - Layout
    
    private func addSubviews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(mySwitch)
    }
    
    private func makeConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().inset(16)
        }
        
        mySwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
        }
    }
}
