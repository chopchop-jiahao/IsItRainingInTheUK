//
//  WeatherLoaderTests.swift
//  IsItRainingInTheUKTests
//
//  Created by Jiahao on 06/12/2025.
//

import XCTest
import IsItRainingInTheUK

protocol HTTPSession {
    func data(from url: URL) async throws -> Data
}

class MockSession: HTTPSession {
    var stubs = [URL: Data]()
    
    func data(from url: URL) async throws -> Data {
        guard let data = stubs[url] else {
            throw URLError(.badServerResponse)
        }
        
        return data
    }
}

protocol WeatherLoader {
    func load(for location: Location) async -> OpenWeatherMapData?
}

class WeatherService: WeatherLoader {
    let session: HTTPSession
    
    init(session: HTTPSession) {
        self.session = session
    }
    
    func load(for location: Location) async -> OpenWeatherMapData? {
        do {
            let data = try await session.data(from: getURL(for: location))
            
            return try JSONDecoder().decode(OpenWeatherMapData.self, from: data)
        } catch {
            return nil
        }
    }
    
    public func getURL(for location: Location) -> URL {
        return URL(string: OpenWeatherMapAPI.baseURL)!.appending(queryItems: [
            URLQueryItem(name: "lat", value: "\(location.latitude)"),
            URLQueryItem(name: "lon", value: "\(location.longtitude)"),
            URLQueryItem(name: "exclude", value: "minutely,daily,alerts"),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "appid", value: OpenWeatherMapAPI.key)
        ])
    }
}

// Test load delivers API error when it returns error
// Test load delivers error when failing to convert JSON data
// Test load delivers error on non-200 HTTP response
// Test load delivers error on invalid url
// Test load will call API if there's no cache
// Test load will call API if cache expires
// Test load will not call API if cache's not expired
final class WeatherLoaderTests: XCTestCase {
    
    func test_load_deliversWeatherData() async throws {
        let (session, sut) = makeSUT()
        let url = sut.getURL(for: cheltenham)
        let testData = makeData()
        let expectedData = model(from: testData)
        session.stubs[url] = testData
        
        let data = await sut.load(for: cheltenham)
        
        XCTAssertEqual(expectedData, data)
    }
    
    // Helpers
    private func makeSUT() -> (session: MockSession, WeatherService) {
        let session = MockSession()
        
        return (session, WeatherService(session: session))
    }
    
    private var cheltenham: Location {
        Location(latitude: 50.90, longtitude: -2.06)
    }
    
    private func makeData() -> Data {
        return testJson.data(using: .utf8)!
    }
    
    private func model(from data: Data) -> OpenWeatherMapData {
        return try! JSONDecoder().decode(OpenWeatherMapData.self, from: data)
    }
    
    private var testJson: String {
        """
        {"lat":50.9,"lon":-2.06,"timezone":"Europe/London","timezone_offset":0,"current":{"dt":1765036447,"sunrise":1765007733,"sunset":1765037004,"temp":10.91,"feels_like":10.22,"pressure":1000,"humidity":83,"dew_point":8.14,"uvi":0,"clouds":90,"visibility":10000,"wind_speed":8.42,"wind_deg":255,"wind_gust":14.48,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10d"}],"rain":{"1h":0.34}},"hourly":[{"dt":1765033200,"temp":10.85,"feels_like":10.18,"pressure":1000,"humidity":84,"dew_point":8.26,"uvi":0.07,"clouds":89,"visibility":10000,"wind_speed":8.44,"wind_deg":252,"wind_gust":14.79,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10d"}],"pop":0.37,"rain":{"1h":0.11}},{"dt":1765036800,"temp":10.91,"feels_like":10.22,"pressure":1000,"humidity":83,"dew_point":8.14,"uvi":0,"clouds":90,"visibility":10000,"wind_speed":8.42,"wind_deg":255,"wind_gust":14.48,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10d"}],"pop":0.25,"rain":{"1h":0.12}},{"dt":1765040400,"temp":10.67,"feels_like":9.96,"pressure":1000,"humidity":83,"dew_point":7.91,"uvi":0,"clouds":90,"visibility":10000,"wind_speed":7.63,"wind_deg":254,"wind_gust":14.27,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04n"}],"pop":0.11},{"dt":1765044000,"temp":10.09,"feels_like":9.35,"pressure":1000,"humidity":84,"dew_point":7.51,"uvi":0,"clouds":89,"visibility":10000,"wind_speed":6.72,"wind_deg":250,"wind_gust":14.24,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10n"}],"pop":0.22,"rain":{"1h":0.32}},{"dt":1765047600,"temp":8.82,"feels_like":5.65,"pressure":1001,"humidity":85,"dew_point":6.44,"uvi":0,"clouds":96,"visibility":10000,"wind_speed":6.28,"wind_deg":250,"wind_gust":13.94,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04n"}],"pop":0},{"dt":1765051200,"temp":8.13,"feels_like":5.08,"pressure":1002,"humidity":87,"dew_point":6.1,"uvi":0,"clouds":98,"visibility":10000,"wind_speed":5.42,"wind_deg":247,"wind_gust":12.97,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04n"}],"pop":0},{"dt":1765054800,"temp":7.02,"feels_like":3.77,"pressure":1004,"humidity":88,"dew_point":6.19,"uvi":0,"clouds":83,"visibility":10000,"wind_speed":5.21,"wind_deg":244,"wind_gust":13.46,"weather":[{"id":803,"main":"Clouds","description":"broken clouds","icon":"04n"}],"pop":0},{"dt":1765058400,"temp":7.06,"feels_like":4,"pressure":1004,"humidity":91,"dew_point":6.91,"uvi":0,"clouds":87,"visibility":10000,"wind_speed":4.81,"wind_deg":238,"wind_gust":12.57,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04n"}],"pop":0},{"dt":1765062000,"temp":6.87,"feels_like":4.24,"pressure":1004,"humidity":94,"dew_point":7.66,"uvi":0,"clouds":87,"visibility":10000,"wind_speed":3.84,"wind_deg":232,"wind_gust":11.09,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04n"}],"pop":0},{"dt":1765065600,"temp":6.58,"feels_like":3.83,"pressure":1004,"humidity":94,"dew_point":8.3,"uvi":0,"clouds":89,"visibility":10000,"wind_speed":3.95,"wind_deg":227,"wind_gust":10.95,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04n"}],"pop":0},{"dt":1765069200,"temp":7.24,"feels_like":5.16,"pressure":1004,"humidity":95,"dew_point":8.43,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":3.06,"wind_deg":214,"wind_gust":8.94,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04n"}],"pop":0},{"dt":1765072800,"temp":7.81,"feels_like":5.36,"pressure":1003,"humidity":96,"dew_point":9.32,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":3.9,"wind_deg":208,"wind_gust":10.2,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04n"}],"pop":0},{"dt":1765076400,"temp":8.27,"feels_like":5.99,"pressure":1003,"humidity":95,"dew_point":9.86,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":3.78,"wind_deg":217,"wind_gust":9.49,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04n"}],"pop":0},{"dt":1765080000,"temp":8.57,"feels_like":6.32,"pressure":1002,"humidity":98,"dew_point":10.11,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":3.84,"wind_deg":177,"wind_gust":8.99,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04n"}],"pop":0},{"dt":1765083600,"temp":9.34,"feels_like":6.72,"pressure":1001,"humidity":99,"dew_point":10.54,"uvi":0,"clouds":100,"wind_speed":5.11,"wind_deg":178,"wind_gust":11.45,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10n"}],"pop":0.72,"rain":{"1h":0.64}},{"dt":1765087200,"temp":8.77,"feels_like":5.67,"pressure":1000,"humidity":98,"dew_point":10.77,"uvi":0,"clouds":100,"visibility":395,"wind_speed":6.04,"wind_deg":177,"wind_gust":11.83,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10n"}],"pop":1,"rain":{"1h":0.68}},{"dt":1765090800,"temp":11.17,"feels_like":10.9,"pressure":1000,"humidity":98,"dew_point":10.9,"uvi":0,"clouds":100,"wind_speed":5.84,"wind_deg":164,"wind_gust":11.82,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10n"}],"pop":1,"rain":{"1h":0.16}},{"dt":1765094400,"temp":12.12,"feels_like":11.95,"pressure":1000,"humidity":98,"dew_point":11.84,"uvi":0,"clouds":100,"visibility":291,"wind_speed":4.75,"wind_deg":208,"wind_gust":12.37,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10d"}],"pop":1,"rain":{"1h":0.43}},{"dt":1765098000,"temp":12.85,"feels_like":12.72,"pressure":1000,"humidity":97,"dew_point":12.47,"uvi":0.01,"clouds":100,"visibility":642,"wind_speed":6.72,"wind_deg":226,"wind_gust":14.49,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04d"}],"pop":0.8},{"dt":1765101600,"temp":13.06,"feels_like":12.93,"pressure":1000,"humidity":96,"dew_point":12.5,"uvi":0.02,"clouds":100,"visibility":10000,"wind_speed":7.91,"wind_deg":221,"wind_gust":16.52,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10d"}],"pop":1,"rain":{"1h":0.48}},{"dt":1765105200,"temp":13.08,"feels_like":12.95,"pressure":1000,"humidity":96,"dew_point":12.43,"uvi":0.04,"clouds":100,"visibility":10000,"wind_speed":9.17,"wind_deg":222,"wind_gust":17.64,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10d"}],"pop":1,"rain":{"1h":0.82}},{"dt":1765108800,"temp":13.1,"feels_like":12.95,"pressure":999,"humidity":95,"dew_point":12.36,"uvi":0.06,"clouds":100,"visibility":10000,"wind_speed":10.13,"wind_deg":221,"wind_gust":19.25,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10d"}],"pop":1,"rain":{"1h":0.23}},{"dt":1765112400,"temp":13.12,"feels_like":12.99,"pressure":999,"humidity":96,"dew_point":12.45,"uvi":0.04,"clouds":100,"visibility":9734,"wind_speed":10.65,"wind_deg":222,"wind_gust":18.88,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10d"}],"pop":0.88,"rain":{"1h":0.18}},{"dt":1765116000,"temp":13.25,"feels_like":13.09,"pressure":999,"humidity":94,"dew_point":12.28,"uvi":0.04,"clouds":100,"visibility":10000,"wind_speed":10.56,"wind_deg":231,"wind_gust":17.93,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04d"}],"pop":0.25},{"dt":1765119600,"temp":13.24,"feels_like":12.97,"pressure":1000,"humidity":90,"dew_point":11.66,"uvi":0.03,"clouds":100,"visibility":10000,"wind_speed":9.72,"wind_deg":239,"wind_gust":17.8,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04d"}],"pop":0.01},{"dt":1765123200,"temp":12.78,"feels_like":12.39,"pressure":1000,"humidity":87,"dew_point":10.7,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":8.51,"wind_deg":247,"wind_gust":15.15,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04d"}],"pop":0},{"dt":1765126800,"temp":11.73,"feels_like":11.2,"pressure":1002,"humidity":86,"dew_point":9.5,"uvi":0,"clouds":96,"visibility":10000,"wind_speed":8.31,"wind_deg":261,"wind_gust":15.02,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04n"}],"pop":0},{"dt":1765130400,"temp":11.2,"feels_like":10.54,"pressure":1004,"humidity":83,"dew_point":8.41,"uvi":0,"clouds":97,"visibility":10000,"wind_speed":7.75,"wind_deg":265,"wind_gust":15.34,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04n"}],"pop":0},{"dt":1765134000,"temp":9.68,"feels_like":6.75,"pressure":1005,"humidity":89,"dew_point":7.97,"uvi":0,"clouds":98,"visibility":10000,"wind_speed":6.25,"wind_deg":254,"wind_gust":13.79,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04n"}],"pop":0},{"dt":1765137600,"temp":9.29,"feels_like":6.54,"pressure":1006,"humidity":91,"dew_point":7.93,"uvi":0,"clouds":53,"visibility":10000,"wind_speed":5.43,"wind_deg":237,"wind_gust":12.89,"weather":[{"id":803,"main":"Clouds","description":"broken clouds","icon":"04n"}],"pop":0},{"dt":1765141200,"temp":9.34,"feels_like":6.61,"pressure":1007,"humidity":94,"dew_point":8.37,"uvi":0,"clouds":50,"visibility":10000,"wind_speed":5.41,"wind_deg":226,"wind_gust":12.78,"weather":[{"id":802,"main":"Clouds","description":"scattered clouds","icon":"03n"}],"pop":0},{"dt":1765144800,"temp":9.8,"feels_like":7.07,"pressure":1007,"humidity":95,"dew_point":9.11,"uvi":0,"clouds":65,"visibility":10000,"wind_speed":5.76,"wind_deg":225,"wind_gust":13.22,"weather":[{"id":803,"main":"Clouds","description":"broken clouds","icon":"04n"}],"pop":0},{"dt":1765148400,"temp":10.26,"feels_like":9.82,"pressure":1007,"humidity":95,"dew_point":9.47,"uvi":0,"clouds":72,"visibility":10000,"wind_speed":5.7,"wind_deg":229,"wind_gust":12.73,"weather":[{"id":803,"main":"Clouds","description":"broken clouds","icon":"04n"}],"pop":0},{"dt":1765152000,"temp":10.64,"feels_like":10.21,"pressure":1008,"humidity":94,"dew_point":9.8,"uvi":0,"clouds":77,"visibility":10000,"wind_speed":6.1,"wind_deg":218,"wind_gust":13.01,"weather":[{"id":803,"main":"Clouds","description":"broken clouds","icon":"04n"}],"pop":0},{"dt":1765155600,"temp":10.96,"feels_like":10.59,"pressure":1008,"humidity":95,"dew_point":10.11,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":6.66,"wind_deg":217,"wind_gust":13.55,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04n"}],"pop":0},{"dt":1765159200,"temp":11.31,"feels_like":10.95,"pressure":1008,"humidity":94,"dew_point":10.37,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":6.89,"wind_deg":213,"wind_gust":13.71,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04n"}],"pop":0},{"dt":1765162800,"temp":11.66,"feels_like":11.28,"pressure":1008,"humidity":92,"dew_point":10.49,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":6.84,"wind_deg":213,"wind_gust":14.35,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04n"}],"pop":0},{"dt":1765166400,"temp":11.94,"feels_like":11.44,"pressure":1007,"humidity":86,"dew_point":9.67,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":6.58,"wind_deg":217,"wind_gust":14.19,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04n"}],"pop":0},{"dt":1765170000,"temp":12.13,"feels_like":11.59,"pressure":1007,"humidity":84,"dew_point":9.52,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":7.07,"wind_deg":227,"wind_gust":13.85,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04n"}],"pop":0},{"dt":1765173600,"temp":11.81,"feels_like":11.32,"pressure":1008,"humidity":87,"dew_point":9.72,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":5.9,"wind_deg":235,"wind_gust":12.02,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10n"}],"pop":0.2,"rain":{"1h":0.14}},{"dt":1765177200,"temp":11.2,"feels_like":10.75,"pressure":1008,"humidity":91,"dew_point":9.78,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":5.07,"wind_deg":231,"wind_gust":11.55,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10n"}],"pop":1,"rain":{"1h":0.26}},{"dt":1765180800,"temp":10.9,"feels_like":10.45,"pressure":1009,"humidity":92,"dew_point":9.59,"uvi":0,"clouds":100,"visibility":10000,"wind_speed":5.14,"wind_deg":229,"wind_gust":12.45,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10d"}],"pop":1,"rain":{"1h":0.57}},{"dt":1765184400,"temp":10.81,"feels_like":10.37,"pressure":1009,"humidity":93,"dew_point":9.65,"uvi":0.01,"clouds":100,"visibility":10000,"wind_speed":5.27,"wind_deg":221,"wind_gust":12.18,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10d"}],"pop":1,"rain":{"1h":0.36}},{"dt":1765188000,"temp":10.89,"feels_like":10.44,"pressure":1010,"humidity":92,"dew_point":9.72,"uvi":0.04,"clouds":100,"visibility":10000,"wind_speed":5.8,"wind_deg":217,"wind_gust":11.61,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10d"}],"pop":1,"rain":{"1h":0.57}},{"dt":1765191600,"temp":10.7,"feels_like":10.28,"pressure":1010,"humidity":94,"dew_point":9.73,"uvi":0.13,"clouds":100,"visibility":10000,"wind_speed":5.29,"wind_deg":215,"wind_gust":10.68,"weather":[{"id":500,"main":"Rain","description":"light rain","icon":"10d"}],"pop":1,"rain":{"1h":0.18}},{"dt":1765195200,"temp":11.03,"feels_like":10.62,"pressure":1010,"humidity":93,"dew_point":9.89,"uvi":0.21,"clouds":100,"visibility":10000,"wind_speed":6.01,"wind_deg":215,"wind_gust":11.54,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04d"}],"pop":0.8},{"dt":1765198800,"temp":11.26,"feels_like":10.84,"pressure":1010,"humidity":92,"dew_point":9.99,"uvi":0.21,"clouds":100,"visibility":10000,"wind_speed":5.68,"wind_deg":216,"wind_gust":10.63,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04d"}],"pop":0},{"dt":1765202400,"temp":11.21,"feels_like":10.81,"pressure":1010,"humidity":93,"dew_point":10.16,"uvi":0.08,"clouds":100,"visibility":10000,"wind_speed":5.59,"wind_deg":214,"wind_gust":10.43,"weather":[{"id":804,"main":"Clouds","description":"overcast clouds","icon":"04d"}],"pop":0}]}
        """
    }
}

