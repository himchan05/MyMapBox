//
//  ContentView.swift
//  MapPolygon
//
//  Created by himchan park on 2022/05/12.
//

import SwiftUI
import Mapbox

struct ContentView: View {
    var loc = CLLocationCoordinate2D(latitude: 36.3593, longitude: -232.0532)
 
    var body: some View {
        VStack {
            MapBoxMapView(location: loc)
                .frame(height: 250)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
