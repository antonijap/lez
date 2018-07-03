//
//  DeleteRow.swift
//  Lez
//
//  Created by Antonija on 25/05/2018.
//  Copyright © 2018 Antonija Pek. All rights reserved.
//

import Foundation
import UIKit
import Eureka

// Custom Cell with value type: Bool
// The cell is defined using a .xib, so we can set outlets :)
final class DeleteCell: Cell<UIButton>, CellType {
    
    var button = UIButton()
    
    public override func setup() {
        addSubview(button)
        button.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().inset(8)
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().inset(8)
        }
        button.setTitle("Delete Account", for: .normal)
        button.addTarget(self, action: #selector(self.buttonTapped(uid:completion:)), for: .primaryActionTriggered)
        button.setTitleColor(.red, for: .normal)
    }
    
    @objc func buttonTapped(uid: String, completion: (_ uid: String) -> Void) {
        completion(uid)
    }
}

// The custom Row also has the cell: CustomCell and its correspond value
final class DeleteCellRow: Row<DeleteCell>, RowType {
    required public init(tag: String?) {
        super.init(tag: tag)
    }
}
