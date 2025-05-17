//
//  StationsRepositoryTests.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// RadioPlayTests/StationsRepositoryTests.swift
import XCTest
@testable import RadioPlay

class StationsRepositoryTests: XCTestCase {
    var repository: StationsRepository!
    
    override func setUp() {
        super.setUp()
        repository = StationsRepository()
    }
    
    override func tearDown() {
        repository = nil
        super.tearDown()
    }
    
    func testLoadStations() async {
        // Arrange
        
        // Act
        let stations = await repository.loadStations()
        
        // Assert
        XCTAssertFalse(stations.isEmpty, "Stations should not be empty")
    }
}

// RadioPlayTests/FavoritesRepositoryTests.swift
import XCTest
@testable import RadioPlay

class FavoritesRepositoryTests: XCTestCase {
    var repository: FavoritesRepository!
    
    override func setUp() {
        super.setUp()
        repository = FavoritesRepository()
        // Clear favorites for testing
        repository.saveFavorites([])
    }
    
    override func tearDown() {
        repository = nil
        super.tearDown()
    }
    
    func testAddFavorite() {
        // Arrange
        let stationId = "test_station_1"
        
        // Act
        repository.addFavorite(stationId)
        
        // Assert
        XCTAssertTrue(repository.isFavorite(stationId), "Station should be in favorites")
    }
    
    func testRemoveFavorite() {
        // Arrange
        let stationId = "test_station_1"
        repository.addFavorite(stationId)
        
        // Act
        repository.removeFavorite(stationId)
        
        // Assert
        XCTAssertFalse(repository.isFavorite(stationId), "Station should not be in favorites")
    }
}