//
//  GeoData.swift
//  MapPolygon
//
//  Created by himchan park on 2022/05/12.
//

import SwiftUI

struct GeoData: Codable {
    var type: String
    var features: [Feature]
}

struct Feature: Codable {
    let type: String
    let properties: Properties
    let geometry: Geometry
}

struct Properties: Codable {
    let name: String?
    let sovereignt: String?
}

struct Geometry: Codable {
    let type: String
    let coordinates: [Coordinate]
}

enum Coordinate: Codable {
    case arrayOfDoubleArray([[Double]]) // [ [ [Double] ] ]
    case arrayOfTripleArray([[[Double]]]) // [ [ [ [Double] ] ] ]
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = try .arrayOfDoubleArray(container.decode([[Double]].self))
        } catch DecodingError.typeMismatch {
            do {
                self = try .arrayOfTripleArray(container.decode([[[Double]]].self))
            } catch DecodingError.typeMismatch {
                throw DecodingError.typeMismatch(Coordinate.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Coordinate type doesn't match triple"))
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .arrayOfDoubleArray(let arrayOfDoubleArray):
            try container.encode(arrayOfDoubleArray)
        case .arrayOfTripleArray(let arrayOfTripleArray):
            try container.encode(arrayOfTripleArray)
        }
    }
}
