//
//  CountriesDataSource.swift
//  ReactiveUIExample
//
//  Created by Florian Kugler on 24-01-2017.
//  Copyright © 2017 objc.io. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

final class CountriesDataSource: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    let countries = ["Germany", "Netherlands"]
    let selectedIndex = Variable<Int>(0)
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return countries.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return countries[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedIndex.value = row
    }
}

