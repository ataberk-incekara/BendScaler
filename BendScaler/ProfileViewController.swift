//
//  ProfileViewController.swift
//  BendScaler
//
//  Created by Ataberk on 24.04.2021.
//

import UIKit
import Layoutless
import SwiftUI


struct Settings{
    // car = 0 ,van = 1, Truck = 2
    var carType: Int
}

var settings = Settings.init(carType: 0)

class ProfileViewController: UIViewController {
    
    lazy var textField: UILabel = {
        let tf = UILabel()
        tf.text = "SETTINGS"
        tf.font = .boldSystemFont(ofSize: 44)
        tf.textColor = .systemGray
        tf.textAlignment = .center
        tf.backgroundColor = .black
        return tf
    }()
    
    lazy var vehicleText: UILabel = {
        let vt = UILabel()
        vt.text = "Choose Vehicle Type"
        vt.font = .boldSystemFont(ofSize: 18)
        vt.textColor = .systemGray
        vt.textAlignment = .left
        vt.backgroundColor = .black
        return vt
    }()
     
    lazy var carSettings: UIButton = {
        let cs = UIButton()
        let car = UIImage(named: "car") as UIImage?
        cs.setImage(car, for: .normal)
        if settings.carType == 0{
            cs.backgroundColor = .systemOrange
        }
        else{
            cs.backgroundColor = .systemGray
        }
        cs.frame.size = CGSize(width: 100, height: 100)
        cs.addTarget(self, action: #selector(carSettingsTabbed), for: .touchUpInside)
        return cs
    }()
    lazy var vanSettings: UIButton = {
        let vs = UIButton()
        let van = UIImage(named: "van") as UIImage?
        vs.setImage(van, for: .normal)
        if settings.carType == 1{
            vs.backgroundColor = .systemOrange
        }
        else{
            vs.backgroundColor = .systemGray
        }
        vs.frame.size = CGSize(width: 100, height: 100)
        vs.addTarget(self, action: #selector(vanSettingsTabbed), for: .touchUpInside)
        return vs
    }()
    
    lazy var truckSettings: UIButton = {
        let ts = UIButton()
        let truck = UIImage(named: "truck") as UIImage?
        ts.setImage(truck, for: .normal)
        if settings.carType == 2{
            ts.backgroundColor = .systemOrange
        }
        else{
            ts.backgroundColor = .systemGray
        }
        ts.frame.size = CGSize(width: 100, height: 100)
        ts.addTarget(self, action: #selector(truckSettingsTabbed), for: .touchUpInside)
        return ts
    }()
    
    @objc fileprivate func carSettingsTabbed() {
        carSettings.backgroundColor = .systemOrange
        vanSettings.backgroundColor = .gray
        truckSettings.backgroundColor = .gray
        settings.carType = 0
    }
    
    @objc fileprivate func vanSettingsTabbed() {
        carSettings.backgroundColor = .gray
        vanSettings.backgroundColor = .systemOrange
        truckSettings.backgroundColor = .gray
        settings.carType = 1
    }
    
    @objc fileprivate func truckSettingsTabbed() {
        carSettings.backgroundColor = .gray
        vanSettings.backgroundColor = .gray
        truckSettings.backgroundColor = .systemOrange
        settings.carType = 2
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    fileprivate func setupViews() {
        view.backgroundColor = .black
        Layoutless.stack(.vertical,spacing: 50)(
            textField,
            vehicleText.insetting(leftBy: 20, rightBy: 0, topBy: 40, bottomBy: -150),
            Layoutless.stack(.horizontal, distribution: .fillEqually)(
                carSettings,vanSettings,truckSettings
            ).insetting(leftBy: 20, rightBy: 20, topBy: 0, bottomBy: 450)
        ).fillingParent(relativeToSafeArea: true).layout(in: view)
    }
}
