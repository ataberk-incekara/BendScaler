//
//  ProfileViewController.swift
//  BendScaler
//
//  Created by Ataberk on 24.04.2021.
//

import UIKit
import Layoutless


struct Settings{
    // Not assigned = 0 ,Car = 1, Truck = 2
    static var carType = 0
}

class ProfileViewController: UIViewController {
    lazy var textField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "SETTINGS"
        tf.borderStyle = .roundedRect
        tf.textAlignment = .center
        return tf
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    fileprivate func setupViews() {
        view.backgroundColor = .systemBackground
        
        stack(.vertical)(
            textField
        ).fillingParent(relativeToSafeArea: true).layout(in: view)
    }
}
