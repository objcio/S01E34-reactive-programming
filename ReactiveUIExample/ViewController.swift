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
        countryPicker.dataSource = countriesDataSource
        countryPicker.delegate = countriesDataSource
        
        let priceSignal = priceSlider.rx.value
            .map { floor(Double($0)) }
            
        priceSignal
            .map { "\($0) USD" }
            .bindTo(priceLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        let vatSignal = countriesDataSource.selectedIndex.asObservable()
            .distinctUntilChanged()
            .map { [unowned self] index in
                self.countriesDataSource.countries[index].lowercased()
            }.flatMap { [unowned self] country in
                self.webservice.load(vat(country: country)).map { Optional.some($0) }.startWith(nil)
            }.shareReplay(1)
        
        vatSignal
            .map { vat in
                vat.map { "\($0) %" } ?? "..."
            }
            .asDriver(onErrorJustReturn: "")
            .drive(vatLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        Observable.combineLatest(vatSignal, priceSignal) { vat, price -> Double? in
            guard let vat = vat else { return nil }
            return price * (1 + vat/100)
        }.map { total in
            total.map { "\($0) USD" } ?? "..."
        }.asDriver(onErrorJustReturn: "")
        .drive(totalLabel.rx.text)
        .addDisposableTo(disposeBag)
    }
}


