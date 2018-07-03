//
//  SliderCell.swift
//  Lez
//
//  Created by Antonija on 14/05/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import Eureka
import UIKit
import RangeSeekSlider

// Custom Cell with value type: Bool
// The cell is defined using a .xib, so we can set outlets :)
final class RangeSliderCell: Cell<AgeRange>, CellType {
    
    var slider: RangeSeekSlider!
    
    public override func setup() {
        super.setup()
        slider = RangeSeekSlider()
        slider.delegate = self
        
        addSubview(slider)
        slider.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().inset(16)
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().inset(8)
        }
        slider.minValue = 18
        slider.maxValue = 60
        slider.minDistance = 2
        slider.colorBetweenHandles = .black
        slider.tintColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.00)
        slider.handleColor = UIColor(red:0.45, green:0.96, blue:0.84, alpha:1.00)
        slider.minLabelColor = .black
        slider.maxLabelColor = .black
        slider.handleDiameter = 24
        slider.handleImage = UIImage(named: "Handle")
        slider.selectedHandleDiameterMultiplier = 1.0
        slider.step = 1.0
        slider.enableStep = true
        backgroundColor = .clear
    }
}

extension RangeSliderCell: RangeSeekSliderDelegate {
    public func rangeSeekSlider(_ slider: RangeSeekSlider, didChange minValue: CGFloat, maxValue: CGFloat) {
        row.value = AgeRange(from: Int(minValue), to: Int(maxValue))
    }
}

// The custom Row also has the cell: CustomCell and its correspond value
final class RangeSliderRow: Row<RangeSliderCell>, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        // We set the cellProvider to load the .xib corresponding to our cell
//        cellProvider = CellProvider<RangeSliderCell>(nibName: "RangeSliderCell")
    }
}
