//
//  ViewController.swift
//  BendScaler
//
//  Created by Ataberk on 17.03.2021.
//

import UIKit
import MapKit
import CoreLocation
import Layoutless
import AVFoundation
import SwiftyJSON

struct buttons {
    var direction_b: Bool
    var start_b: Bool
}

struct Nodes{
    var poly_step: Int
    var latt: Double
    var long: Double
    var next_latt: Double
    var next_long: Double
}

struct Bends{
    var degree: Double
    var tangent: Double
    var length: Double
    var first_leg: Double
    var second_leg: Double
    var grade: Int
    var advisory_speed: Int
    var city: Bool
}

struct weatherResponse: Codable {
    let weather: [weatherDescription]
}
struct weatherDescription: Codable{
    let main: String
    let description: String
}

class ViewController: UIViewController {
    var button_info = buttons(direction_b: false, start_b: false)
    var steps: [MKRoute.Step] = []
    var stepCounter = 0
    var bendCounter = 0
    var warningCounter = 0
    var route: MKRoute?
    var showMapRoute = false
    var navigationStarted = false
    let locationDistance: Double = 1000
    var nodes = [Nodes]()
    var bends = [Bends]()
    var speecher = AVSpeechSynthesizer()
    var city = false
    var weather_int = 0
    var weather_main = ""
    var weather_description = ""
    var timer = 300
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        locationManager.startUpdatingLocation()
    }
    lazy var textField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter your destination"
        tf.borderStyle = .bezel
        tf.textAlignment = .center
        tf.textColor = .white
        tf.autocorrectionType = .no
        return tf
    }()
    
    lazy var getDirectionButton: UIButton = {
        let route_image = UIImage(named: "route_icon") as UIImage?
        let button = UIButton()
        button.setImage(route_image, for: .normal)
        button.addTarget(self, action: #selector(getDirectionButtonTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var startStopButton: UIButton = {
        let button = UIButton()
        button.setTitle("START", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 36)
        button.addTarget(self, action: #selector(startStopButtonTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var profileButton: UIButton = {
        let settings_image = UIImage(named: "settings_icon") as UIImage?
        let button = UIButton()
        button.setImage(settings_image, for: .normal)
        button.addTarget(self,action: #selector(openProfileView),for:.touchUpInside)
        return button
    }()
    
     var speed_info: UILabel = {
        let info = UILabel()
        info.text = ""
        info.textColor = .white
        info.textAlignment = .center
        info.font = .boldSystemFont(ofSize: 20)
        return info
    }()
    
    lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        return mapView
    }()
    
    @objc fileprivate func getDirectionButtonTapped() {
        button_info.start_b = false
        startStopButton.setTitle("START", for: .normal)
        guard let text = textField.text
        else{
            return
        }
        showMapRoute = true
        textField.endEditing(true)
       
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(text){ (placemarks, err) in
            if let err = err{
                print(err.localizedDescription)
                return
            }
            guard let placemarks = placemarks,
                  let placemark = placemarks.first,
                  let location = placemark.location
            else{return}
            let destinationCoordinate = location.coordinate
            self.mapRoute(destinationCoordinate: destinationCoordinate)
        }
    }
    
    @objc fileprivate func startStopButtonTapped() {
        if !navigationStarted{
            showMapRoute = true
            if let location = locationManager.location{
                let center = location.coordinate
                centerViewToUserLocation(center: center)
            }
        }
        else{
            if let route = route {
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16), animated: true)
                self.steps.removeAll()
                self.stepCounter = 0
            }
        }
        navigationStarted.toggle()
        if route != nil{
            startStopButton.setTitle(navigationStarted ? "STOP" : "START", for: .normal)
            button_info.start_b = true
        }

    }
    
    @objc func openProfileView(){
        let profileVC : ProfileViewController = ProfileViewController()
        self.present(profileVC, animated: true, completion: nil)
    }
        
    fileprivate func setupViews() {
        view.backgroundColor = .systemBackground
        stack(.vertical,spacing: 5)(
            speed_info,
            mapView,
            stack(.horizontal, spacing: 1)(
                textField
            ).insetting(by: 2),
            stack(.horizontal,spacing: 30)(
                getDirectionButton,
                startStopButton,
                profileButton).insetting(leftBy: 50, rightBy: 70, topBy: 0, bottomBy: -10)
        ).fillingParent(relativeToSafeArea: true).layout(in: view)
    }
    
    lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        let status = locationManager.authorizationStatus
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            handleAuthorizationStatus(locationManager: locationManager, status: status)
        }
        else{
            print("Enable Location Services")
        }
        return locationManager
    }()
    
    fileprivate func centerViewToUserLocation(center: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: center, latitudinalMeters: locationDistance, longitudinalMeters: locationDistance)
        mapView.setRegion(region, animated: true)
    }
    
    fileprivate func centerViewToUserLocationDrive(center: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: center, latitudinalMeters: locationDistance/3, longitudinalMeters: locationDistance/3.5)
        mapView.setRegion(region, animated: true)
    }
    
    fileprivate func handleAuthorizationStatus(locationManager: CLLocationManager, status: CLAuthorizationStatus) {
        switch status{
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            //
            break
        case .denied:
            //
            break
        case .authorizedAlways:
            //
            break
        case .authorizedWhenInUse:
            if let center = locationManager.location?.coordinate{
                centerViewToUserLocation(center: center)
            }
            break
        @unknown default:
            break
        }
    }
    
    fileprivate func mapRoute(destinationCoordinate: CLLocationCoordinate2D) {
        nodes = []
        self.mapView.overlays.forEach {
            if !($0 is MKUserLocation) {
                self.mapView.removeOverlay($0)
            }
        }
        
        guard let sourceCoordinate = locationManager.location?.coordinate else{return}
        let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        let destinationItem = MKMapItem(placemark: destinationPlacemark)
        
        let routeRequest = MKDirections.Request()
        routeRequest.source = sourceItem
        routeRequest.destination = destinationItem
        routeRequest.transportType = .automobile
        
        let directions = MKDirections(request: routeRequest)
        directions.calculate{ (response, err) in
            if let err = err{
                print(err.localizedDescription)
                return
            }
            guard let response = response,let route = response.routes.first
            else{
                return
            }
            
            self.route = route
            var coord_X: Double
            var coord_Y: Double
            var next_X: Double
            var next_Y: Double
            let counter = route.steps.count
            for i in 0...counter-1{
                let pointS = route.steps[i].polyline
                for j in 0...pointS.pointCount - 1{
                    //print("point count of step:",i,"----> ",pointS.pointCount)
                    next_Y = pointS.points()[j+1].coordinate.latitude
                    next_X = pointS.points()[j+1].coordinate.longitude
                    coord_Y = pointS.points()[j].coordinate.latitude
                    coord_X = pointS.points()[j].coordinate.longitude

                    if(i==0){
                        self.nodes.append(Nodes(poly_step:i, latt: coord_Y, long: coord_X, next_latt: next_Y, next_long: next_X))
                    }
                    else if(i>0 && j>0){
                        self.nodes.append(Nodes(poly_step:i, latt: coord_Y, long: coord_X, next_latt: next_Y, next_long: next_X))
                    }
                    else{
                    }
                }
            }
            print("Total Node Count:",self.nodes.count)
            //var node_ct=nodes.count
            //self.add_annotation(index: &node_ct,node: &nodes)
            self.mapView.addOverlay(route.polyline)
            //self.mapView.addOverlay(route.steps[0].polyline)
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16), animated: true)
            self.getBends(node: &self.nodes)
        }
    }
    
    
    fileprivate func getBends(node: inout [Nodes]) {
        bends = []
        var bend_ct = node.count - 2
        for i in 0...bend_ct-1{
            let node1_x = node[i].long
            let node1_y = node[i].latt
            let node2_x = node[i+1].long
            let node2_y = node[i+1].latt
            let node3_x = node[i+2].long
            let node3_y = node[i+2].latt
            let leg1 = self.meter_calculator(lat1: node1_y , lon1: node1_x, lat2: node2_y, lon2: node2_x)
            let leg2 = self.meter_calculator(lat1: node2_y , lon1: node2_x, lat2: node3_y, lon2: node3_x)
            let m1 = (node2_y - node1_y) / (node2_x-node1_x)
            let m2 = (node3_y - node2_y) / (node3_x-node2_x)
            let tangent = abs((m1 - m2) / (1+(m1*m2)))
            let degree = 180 - (atan(tangent) * (180 / Double.pi))
            let advisory_speed = self.speed_advisor(tangent: tangent, degree: degree, leg1: leg1, leg2: leg2)
            let scale = self.scaler(bend_scale: Double(advisory_speed))
            bends.append(Bends(degree: degree, tangent: tangent, length: (leg1+leg2),first_leg: leg1, second_leg: leg2, grade: scale, advisory_speed: Int(advisory_speed), city: city))
            //if bends[i].grade>1 {
                print("bend:",i+1,bends[i])
            //}
        }
        
        self.add_bend_annotation(index: &bend_ct,bend: &bends,node: &node)
    }
    
    private func add_annotation(index: inout Int,node: inout [Nodes]){
        self.mapView.removeAnnotations(self.mapView.annotations)
        for index in 0...index-1 {
            let annotation = MKPointAnnotation()  // <-- new instance here
            //print("node:",index,node[index])
            annotation.coordinate = CLLocationCoordinate2D(latitude: node[index].latt, longitude: node[index].long)
            annotation.title = "Point \(index+1)"
            self.mapView.addAnnotation(annotation)
        }
    }
    
    private func add_bend_annotation(index: inout Int,bend: inout [Bends],node: inout [Nodes]){
        self.mapView.removeAnnotations(self.mapView.annotations)
        //print("I m annotation func:",index)
        for index in 0...index-1 {
            let annotation = MKPointAnnotation()  // <-- new instance here
            //print("node:",index,node[index])
            annotation.coordinate = CLLocationCoordinate2D(latitude: node[index+1].latt, longitude: node[index+1].long)
            annotation.title = "Bend: \(index+1)"
            switch bend[index].grade{
            case 5:
                annotation.subtitle = "5"
            case 4:
                annotation.subtitle = "4"
            case 3:
                annotation.subtitle = "3"
            case 2:
                annotation.subtitle = "2"
            case 1:
                annotation.subtitle = "1"
            default:
                annotation.subtitle = "0"
            }
            //if bend[index].grade > 1 {
                self.mapView.addAnnotation(annotation)
            //}
        }
    }
    
    func meter_calculator(lat1: Double, lon1: Double, lat2:Double,lon2:Double)->Double {
        let R = 6378.137; // Radius of earth in KM
        let dLat = lat2 * .pi / 180 - lat1 * .pi / 180;
        let dLon = lon2 * .pi / 180 - lon1 * .pi / 180;
        let a = sin(dLat/2) * sin(dLat/2) +
            cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
            sin(dLon/2) * sin(dLon/2);
        let c = 2 * atan2(sqrt(a), sqrt(1-a));
        let d = R * c;
        return d * 1000; // meters
    }
    
    
    func speed_advisor(tangent: Double, degree: Double, leg1: Double, leg2:Double) -> Double {
        //V^2 = 127xR(e/100+f)
        var first_leg = leg1
        var second_leg = leg2
        if leg1>20{
            first_leg = 20
        }
        if leg2>20{
            second_leg = 20
        }
        let cos_formula = 2 * first_leg * second_leg * (cos(degree * .pi / 180))
        let c = sqrt((first_leg * first_leg) + (second_leg * second_leg) - cos_formula)
        let area = abs((first_leg*second_leg*sin(degree * .pi / 180))/2)
        let a = (2 * area) / c
        let r = ((4 * a * a) + (c * c)) / (8 * a)
        let e = 0.02
        let f = 0.70
        let v = sqrt(127 * (r*(e+f)))
        print("V is: ",v,"e is: ",e,"f is: ",f)
        if !(v.isNaN){
            return v
            }
        else{
            return 120.0
            }
    }
    
    func scaler(bend_scale: Double) -> Int{
        var scale = 0
        if bend_scale <= 30{
            scale = 5
        }
        else if bend_scale<=55 && bend_scale>30{
            scale = 4
        }
        else if bend_scale<=80 && bend_scale>55{
            scale = 3
        }
        else if bend_scale<=105 && bend_scale>80{
            scale = 2
        }
        else{
            scale = 1
        }
        //CAR TYPE
        
        return scale;
    }
    
    func speedInfo(curr_x: Double, curr_y: Double){
        //x = Vo t + 1/2 a . t2  
        let dist = meter_calculator(lat1: nodes[bendCounter+3].latt, lon1: nodes[bendCounter+3].long, lat2: curr_y, lon2: curr_x)
        if(dist<60 && dist>5){
            DispatchQueue.main.async{ [self] in
                var bend_curr_speed = (bends[bendCounter+2].advisory_speed)
                var bend_before_speed = (bends[bendCounter+1].advisory_speed)
                //advisory_speed = speedDecider(curr_speed: bend_curr_speed, bend_before_speed:)
                if city == true && bend_curr_speed > 60{
                    bend_curr_speed = 60
                    bend_before_speed = 60
                }
                if city == false && bend_curr_speed > 120{
                    bend_curr_speed = 120
                    bend_before_speed = 120
                }
                if bends[bendCounter+2].grade>=1{
                    self.speed_info.text = "For Bend \(bendCounter+3) Advisory Speed: \(bend_curr_speed)"
                    if bend_curr_speed != bend_before_speed{
                        if bend_curr_speed < bend_before_speed  {
                            let text = "Advisory Speed: \(bend_curr_speed)"
                            let utterance = AVSpeechUtterance(string: text)
                            utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
                            utterance.rate = 0.6
                            let synthesizer = AVSpeechSynthesizer()
                            synthesizer.speak(utterance)
                        }
                    }
                }
                bendCounter+=1
            }
        }
    }

    func isCity(address: String) -> Bool{
        if address.contains("Sk.") || address.contains("Cd.") || address.contains("Blv.") || address.contains("Sokağı") || address.contains("Caddesi") || address.contains("Bulvarı"){
            return true
        }
        if address.contains("Yolu") || address.contains("Otoyolu") {
            return false
        }
        else{
            return false
        }
    }
    
    @objc func howIsWeather(current_x: Double, current_y: Double){
        let url = "https://api.openweathermap.org/data/2.5/weather?lat=\(current_y)&lon=\(current_x)&appid=6e8ee7768582e04c387a39a0627fe722"
                URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: { data, response, error in
                    guard let data = data, error == nil else {
                        print("something went wrong")
                        return
                    }
                    var json: weatherResponse?
                    do {
                        json = try JSONDecoder().decode(weatherResponse.self, from: data)
                        self.weather_main = (json?.weather[0].main)!
                        self.weather_description = (json?.weather[0].description)!
                    }
                    catch {
                        print("error: \(error)")
                    }

                    guard json != nil else {
                            return
                    }
                }).resume()
        if weather_main == "Snow"{
            weather_int = 0
        }
        else if weather_main == "Thunderstorm" || weather_main == "Drizzle" || weather_main == "Rain"{
            weather_int = 1
        }
        else{
            weather_int = 2
        }
        print("weather: ", weather_int)
    }
 
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "MyMarker")
        if (annotation.isKind(of: MKUserLocation.self)){
                return nil
            }
        switch annotation.subtitle {
        case "5":
            annotationView.markerTintColor = .red
        case "4":
            annotationView.markerTintColor = .orange
        case "3":
            annotationView.markerTintColor = .yellow
        case "2":
            annotationView.markerTintColor = .blue
        case "1":
            annotationView.markerTintColor = .green
        default:
            annotationView.markerTintColor = .white
        }
        return annotationView
    }

}


extension ViewController: CLLocationManagerDelegate{
    //EV = 41,064354 - 28,986823  //
    // NEAR HOME = 41,065342 -- 28,986472
    //ANADOLU OTOYOLU = 40,709608, 30,145393
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !showMapRoute {
            if let location = locations.last{
                let center = location.coordinate
                location.geocode { [self] address_name, error in
                    guard let address_name = address_name, error == nil else { return }
                    city = isCity(address: String(address_name.description))
                }
                centerViewToUserLocation(center: center)
            }
        }
        if button_info.start_b == true{
            let location = locations.last
            location!.geocode { [self] address_name, error in
                guard let address_name = address_name, error == nil else { return }
                city = isCity(address: String(address_name.description))
            }
            let x = location!.coordinate.longitude
            let y = location!.coordinate.latitude
            if timer == 300{
                howIsWeather(current_x: x,current_y: y)
                timer = 300
            }
            speedInfo(curr_x: x, curr_y: y)
            guard let center = location?.coordinate else { return }
            centerViewToUserLocationDrive(center: center)
            timer -= 1
        }
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationStatus(locationManager: locationManager, status: locationManager.authorizationStatus)
    }
}

extension ViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = .systemBlue
        renderer.lineWidth = 2.5
        return renderer
    }
}

extension CLLocation {
    func geocode(completion: @escaping (_ placemark: [CLPlacemark]?, _ error: Error?) -> Void)  {
        CLGeocoder().reverseGeocodeLocation(self, completionHandler: completion)
    }
}
