//
//  StationsView.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Presentation/Stations/StationsView.swift
import SwiftUI

struct StationsView: View {
    @StateObject private var viewModel = StationsViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fond
                Color.black.edgesIgnoringSafeArea(.all)
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text(errorMessage)
                            .foregroundColor(.white)
                            .padding()
                        
                        Button("Réessayer") {
                            Task {
                                await viewModel.loadStations()
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else {
                    List {
                        ForEach(viewModel.stations) { station in
                            NavigationLink(destination: PlayerView(station: station)) {
                                StationRow(station: station)
                            }
                            .listRowBackground(Color.black)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Radio Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Radio Play")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .task {
                if viewModel.stations.isEmpty {
                    await viewModel.loadStations()
                }
            }
            .refreshable {
                await viewModel.loadStations()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.dark)
    }
}

struct StationRow: View {
    let station: Station
    
    var body: some View {
        HStack {
            // Logo de la radio
            AsyncImage(url: URL(string: station.logoURL ?? "")) { phase in
                switch phase {
                case .empty:
                    Color.gray
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                case .failure:
                    Image(systemName: "radio")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(15)
                        .frame(width: 60, height: 60)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(station.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(station.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
    }
}