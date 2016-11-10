//
//  MainViewController.swift
//  HotCold
//
//  Created by Jack Frysinger on 2/7/15.
//  Copyright (c) 2015 Jack Frysinger. All rights reserved.
//

import UIKit
import CoreLocation
import SwiftyJSON

class MainViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, CLLocationManagerDelegate {
    
    private func coordinate() -> CLLocationCoordinate2D? {
        return locationManager.location?.coordinate
    }
    
    let model = HotColdModel()

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var myPickerView: UIPickerView!
    @IBOutlet weak var goButtonOutlet: UIButton!
    @IBOutlet weak var radiusSlider: UISlider!
    
    private var locationManager = CLLocationManager()
    
    private let placeTypeOptions = ["Restaurants", "Historical Landmarks", "Museums", "Parks"]
    private let placeTypeRequest = ["restaurant", "history", "museum", "park", "geocache"]
    private let radiusOptions = [0.1, 0.5, 1.0, 5.0, 10.0, 25.0, 50.0]
    
    private var radiusIndex = 0
    
    private var radius: Double {
        get {
            let x = Double(self.radiusSlider.value)
            return (x < 0.5) ? (4.8*x + 2.4*x*x) : (46.5714*x*x + 24.1429*x - 20.7143)
        }
    }
    
    @IBAction func radiusValueChanged(_ sender: AnyObject) {
        self.updateUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateUI()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        print("requesting in viewdidload")
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func updateUI() {
        let r = String(format: "%0.1f", self.radius)
        self.descriptionLabel.text = "\(self.placeTypeOptions[myPickerView.selectedRow(inComponent: 0)])\nwithin \(r) miles"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        let url = URL(string: "https://nz5bypr9rk.execute-api.us-east-1.amazonaws.com/prod/LambdaFunctionOverHttps/?locType=\(placeTypeRequest[myPickerView.selectedRow(inComponent: 0)])&userLat=\((coordinate()?.latitude)!)&userLong=\((coordinate()?.longitude)!)&radius=\(self.radius)")
        
        let d = URLSession.shared.dataTask(with: url!, completionHandler: {(data, r, error) in self.cont(d: data, segue: segue)})
        d.resume()
    }
    
    private func cont(d: Data?, segue: UIStoryboardSegue) {
        if let dta = d {
            let json = JSON(data: dta)
        
            let alat = json["latitude"].double!
            let along = json["longitude"].double!
            let name = json["name"].stringValue
            let link = json["link"].stringValue
            
            let vc = segue.destination as! ColorViewController
            vc.endLocation = CLLocation(latitude: alat, longitude: along)
            vc.startLocation = CLLocation(latitude: (coordinate()?.latitude)!, longitude: (coordinate()?.longitude)!)
            vc.name = name
            vc.link = link
            print("Destination: \(alat) \(along)")
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.placeTypeOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.placeTypeOptions[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.updateUI()
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return pickerView.frame.size.width * 0.8
    }
}
