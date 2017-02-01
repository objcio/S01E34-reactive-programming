//
//  ViewController.swift
//  ReactiveUIExample
//
//  Created by Florian Kugler on 24-01-2017.
//  Copyright © 2017 objc.io. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Webservice {
    func load<A>(_ resource: Resource<A>) -> Observable<A> {
        return Observable.create { observer in
            print("start loading")
            self.load(resource) { result in
                sleep(1)
                switch result {
                case .error(let error):
                    observer.onError(error)
                case .success(let value):
                    observer.onNext(value)
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
}

class ViewController: UIViewController {
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceSlider: UISlider!
    @IBOutlet weak var countryPicker: UIPickerView!
    @IBOutlet weak var vatLabel: UILabel!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var buyButton: UIButton!
    
    let webservice = Webservice()
    let countriesDataSource = CountriesDataSource()
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        countryPicker.dataSource = self.countriesDataSource
        countryPicker.delegate = self.countriesDataSource
        
        let priceSignal = priceSlider.rx.value
            .asDriver()
            .map { floor(Double($0)) }
            
        priceSignal
            .map { "\($0) USD" }
            .drive(priceLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        let countriesDataSource = self.countriesDataSource
        let webservice = self.webservice
        let vatSignal = countriesDataSource.selectedIndex.asDriver()
            .distinctUntilChanged()
            .map { index in
                countriesDataSource.countries[index].lowercased()
            }.flatMap { country in
                webservice.load(vat(country: country)).map { Optional.some($0) }.startWith(nil)
                    .asDriver(onErrorJustReturn: nil)
            }
        
        vatSignal
            .map { vat in
                vat.map { "\($0) %" } ?? "..."
            }
            .drive(vatLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        Driver.combineLatest(vatSignal, priceSignal) { (vat: Double?, price: Double) -> Double? in
            guard let vat = vat else { return nil }
            return price * (1 + vat/100)
        }.map { total in
                total.map { "\($0) USD" } ?? "..."
        }.drive(totalLabel.rx.text)
        .addDisposableTo(disposeBag)
    }
}


