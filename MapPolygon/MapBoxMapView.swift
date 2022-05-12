//
//  MapBoxMapView.swift
//  MapPolygon
//
//  Created by himchan park on 2022/05/12.
//

import SwiftUI
import Mapbox
import UIKit
import MapboxGeocoder

struct MapBoxMapView: UIViewRepresentable {
    
    var location: CLLocationCoordinate2D //Mapview Center Set by View Side
    var mapView: MGLMapView = MGLMapView(frame: .zero, styleURL: MGLStyle.streetsStyleURL)
    var country: [String] = [] // for visited country
    
    func makeUIView(context: UIViewRepresentableContext<MapBoxMapView>) -> MGLMapView {
        mapView.delegate = context.coordinator
        mapView.logoView.isHidden = true
        mapView.setCenter(location, zoomLevel: 11, animated: false)
  
        return mapView
    }

    func updateUIView(_ uiView: MGLMapView, context: UIViewRepresentableContext<MapBoxMapView>) {
            
    }
    
    func makeCoordinator() -> MapBoxMapView.Coordinator {
        return Coordinator(self)
    }
    
    final class Coordinator: NSObject, MGLMapViewDelegate {
        var control: MapBoxMapView
      
        init(_ control: MapBoxMapView) {
            self.control = control
        }
        
        // Wait until the map is loaded before adding to the map.
        func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
            loadGeoJson()
        }
        
        func loadGeoJson() {
            DispatchQueue.global().async {
                // Get the path for example.geojson in the app’s bundle.
                guard let jsonUrl = Bundle.main.url(forResource: "Geo", withExtension: "geojson") else {
                    preconditionFailure("Failed to load local GeoJSON file")
                }
                
                guard let jsonData = try? Data(contentsOf: jsonUrl) else {
                    preconditionFailure("Failed to parse GeoJSON file")
                }
                
                // my geojson bundle 에서 가져온 Data를 Decoding 해서 name으로 특정 나라를 filter해서 다시 data로 encoding 후 shape을 만듬 (특정 국가 렌더링 가능)
                do {
                    let geoData = try JSONDecoder().decode(GeoData.self, from: jsonData)
                    print("🪀 디코딩 성공")
                    
                    self.convertLatLongToAddress(latitude: 45.5076, longitude: -122.6736) // United States
//                    self.convertLatLongToAddress(latitude: 37.6658609, longitude: 127.0317675) // South Korea -> rename Korea
//                    self.convertLatLongToAddress(latitude: 53.45670300, longitude: -6.22280000) // Ireland
//                    self.convertLatLongToAddress(latitude: 34.81055600, longitude: 102.64472200) // China
//                    self.convertLatLongToAddress(latitude: 55.98333300, longitude: 37.22444400) // Russia
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        
                        var feature = [Feature]()
                        for country in self.control.country {
                            let vistedCountry = geoData.features.filter({ $0.properties.name == country || $0.properties.sovereignt == country }).first
                            feature.append(vistedCountry!)
                        }
                        
                        let NewgeoData = GeoData(type: "FeatureCollection", features: feature)

                        let data = try? JSONEncoder().encode(NewgeoData)
            
                        guard let data = data else { return }

                        DispatchQueue.main.async {
                            self.drawPolyline(geoJson: data)
                        }
                    }
                } catch (let err){
                    print(err.localizedDescription)
                }
            }
        }
        
        func drawPolyline(geoJson: Data) {
            // Add our GeoJSON data to the map as an MGLGeoJSONSource.
            // We can then reference this data from an MGLStyleLayer.
         
            // MGLMapView.style is optional, so you must guard against it not being set.
          
            guard let style = self.control.mapView.style else { return }
            
            guard let shapeFromGeoJSON = try? MGLShape(data: geoJson, encoding: String.Encoding.utf8.rawValue) else {
                fatalError("Could not generate MGLShape")
            }
            
            let source = MGLShapeSource(identifier: "polyline", shape: shapeFromGeoJSON, options: nil)
            style.addSource(source)
            
            // Create new layer for the line.
            let layer = MGLLineStyleLayer(identifier: "polyline", source: source)
           
            // Set the line join and cap to a rounded end.
            layer.lineJoin = NSExpression(forConstantValue: "round")
            layer.lineCap = NSExpression(forConstantValue: "round")
            
            // Set the line color to a constant blue color.
            layer.lineColor = NSExpression(forConstantValue: UIColor(red: 59/255, green: 178/255, blue: 208/255, alpha: 1))
            // Use `NSExpression` to smoothly adjust the line width from 2pt to 20pt between zoom levels 14 and 18. The `interpolationBase` parameter allows the values to interpolate along an exponential curve.
            layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
                                           [14: 2, 18: 20])
            style.addLayer(layer)
            
            // We can also add a second layer that will draw a stroke around the original line.
            let casingLayer = MGLLineStyleLayer(identifier: "polyline-case", source: source)
                 
            // Copy these attributes from the main line layer.
            casingLayer.lineJoin = layer.lineJoin
            casingLayer.lineCap = layer.lineCap
            // Line gap width represents the space before the outline begins, so should match the main line’s line width exactly.
            casingLayer.lineGapWidth = layer.lineWidth
            // Stroke color slightly darker than the line color.
            casingLayer.lineColor = NSExpression(forConstantValue: UIColor(red: 255/255, green: 1/255, blue: 1/255, alpha: 1))
            // Use `NSExpression` to gradually increase the stroke width between zoom levels 14 and 18.
            casingLayer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", [14: 1, 18: 4])
            style.insertLayer(casingLayer, below: layer)
         
            // Just for fun, let’s add another copy of the line with a dash pattern.
          
            let dashedLayer = MGLLineStyleLayer(identifier: "polyline-dash", source: source)

            dashedLayer.lineJoin = layer.lineJoin
            dashedLayer.lineCap = layer.lineCap
            dashedLayer.lineColor = NSExpression(forConstantValue: UIColor.white)
            dashedLayer.lineOpacity = NSExpression(forConstantValue: 0.5)
            dashedLayer.lineWidth = layer.lineWidth
            
            // Dash pattern in the format [dash, gap, dash, gap, ...]. You’ll want to adjust these values based on the line cap style.
            dashedLayer.lineDashPattern = NSExpression(forConstantValue: [0, 1.5])
            
            style.addLayer(dashedLayer)
            
            let polygon = MGLFillStyleLayer(identifier: "polygone", source: source)

            polygon.fillColor = NSExpression(forConstantValue: UIColor.green)
            polygon.fillOpacity = NSExpression(forConstantValue: 0.5)
            
            style.addLayer(polygon)
        }
        
        func convertLatLongToAddress(latitude: Double, longitude: Double) -> Void {
            var center : CLLocationCoordinate2D = CLLocationCoordinate2D()
            center.latitude = latitude
            center.longitude = longitude
            
            let geoCoder = CLGeocoder()
            let location = CLLocation(latitude: center.latitude, longitude: center.longitude)
            let locale = Locale(identifier: "En-us")
            
            geoCoder.reverseGeocodeLocation(location, preferredLocale: locale, completionHandler: { (placemarks, error) -> Void in
                
                // Place details
                let placeMark: CLPlacemark? = placemarks?[0]
                
                // Location name
                if let locationName = placeMark?.location {
                    print("😀 \(locationName)")
                }
                // Street address
                if let street = placeMark?.thoroughfare {
                    print("😀 \(street)")
                }
                // City
                if let city = placeMark?.locality {
                    print("😀 \(city)")
                }
                if let state = placeMark?.administrativeArea {
                    print("😀 \(state)")
                }
                if let zipCode = placeMark?.postalCode {
                    print("😀 \(zipCode)")
                }
                if let country = placeMark?.country {
                    print("😀 \(country)")
                    self.control.country.append(country)
                }
            })
        }
         
    }
    
}
