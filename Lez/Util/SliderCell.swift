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
public class RangeSliderCell: Cell<Bool>, CellType {
//    var slider: RangeSeekSlider!
    public override func setup() {
        super.setup()
        let slider = RangeSeekSlider()
        addSubview(slider)
        slider.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        slider.minValue = 18
        slider.maxValue = 99
        slider.minDistance = 2
        slider.colorBetweenHandles = .black
        slider.tintColor = UIColor(red:0.90, green:0.90, blue:0.90, alpha:1.00)
        slider.handleColor = UIColor(red:0.45, green:0.96, blue:0.84, alpha:1.00)
        slider.minLabelColor = .black
        slider.maxLabelColor = .black
        slider.handleDiameter = 23
    }
}

// The custom Row also has the cell: CustomCell and its correspond value
public final class RangeSliderRow: Row<RangeSliderCell>, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
        // We set the cellProvider to load the .xib corresponding to our cell
//        cellProvider = CellProvider<RangeSliderCell>(nibName: "RangeSliderCell")
    }
}
