//
//  AddCustomStationView.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 03/10/2025.
//


//
//  AddCustomStationView.swift
//  RadioPlay
//
//  Created by Martin Parmentier
//

import SwiftUI

struct AddCustomStationView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: StationsViewModel
    
    @State private var stationName = ""
    @State private var stationSubtitle = ""
    @State private var streamURL = ""
    @State private var logoURL = ""
    @State private var selectedCategories: Set<String> = []
    
    @State private var showValidation = false
    @State private var validationMessage = ""
    @State private var isTestingStream = false
    @State private var streamIsValid = false
    
    // Catégories disponibles
    private let availableCategories = ["Actualités", "Musique", "Sport", "Culture", "Généraliste", "Information"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fond
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.05, green: 0.05, blue: 0.15)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // En-tête avec icône
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.blue.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                            }
                            .shadow(color: Color.blue.opacity(0.4), radius: 20, x: 0, y: 10)
                            
                            Text("Ajouter une radio")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Personnalisez votre expérience")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                        
                        // Formulaire
                        VStack(spacing: 20) {
                            // Nom de la station
                            CustomTextField(
                                icon: "radio",
                                placeholder: "Nom de la station",
                                text: $stationName
                            )
                            
                            // Slogan/Description
                            CustomTextField(
                                icon: "text.quote",
                                placeholder: "Slogan ou description",
                                text: $stationSubtitle
                            )
                            
                            // URL du stream
                            VStack(alignment: .leading, spacing: 8) {
                                CustomTextField(
                                    icon: "link",
                                    placeholder: "URL du flux (http://...)",
                                    text: $streamURL,
                                    keyboardType: .URL
                                )
                                
                                // Bouton test du stream
                                if !streamURL.isEmpty {
                                    Button(action: testStreamURL) {
                                        HStack {
                                            if isTestingStream {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(0.8)
                                            } else {
                                                Image(systemName: streamIsValid ? "checkmark.circle.fill" : "play.circle")
                                            }
                                            
                                            Text(isTestingStream ? "Test en cours..." : (streamIsValid ? "Stream valide ✓" : "Tester le flux"))
                                                .font(.subheadline)
                                        }
                                        .foregroundColor(streamIsValid ? .green : .blue)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    .disabled(isTestingStream)
                                }
                            }
                            
                            // URL du logo (optionnel)
                            CustomTextField(
                                icon: "photo",
                                placeholder: "URL du logo (optionnel)",
                                text: $logoURL,
                                keyboardType: .URL
                            )
                            
                            // Catégories
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "tag")
                                        .foregroundColor(.blue)
                                    Text("Catégories")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                
                                FlowLayout(spacing: 8) {
                                    ForEach(availableCategories, id: \.self) { category in
                                        CategoryChip(
                                            title: category,
                                            isSelected: selectedCategories.contains(category),
                                            action: {
                                                if selectedCategories.contains(category) {
                                                    selectedCategories.remove(category)
                                                } else {
                                                    selectedCategories.insert(category)
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            
                            // Message d'aide
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text("Le flux doit être au format MP3, AAC ou OGG")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 20)
                        
                        // Bouton de validation
                        Button(action: saveCustomStation) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Ajouter la station")
                                    .fontWeight(.semibold)
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: canSave ? [Color.blue, Color.blue.opacity(0.8)] : [Color.gray, Color.gray.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .shadow(color: canSave ? Color.blue.opacity(0.4) : Color.clear, radius: 15, x: 0, y: 8)
                        }
                        .disabled(!canSave)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .alert("Validation", isPresented: $showValidation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Computed Properties
    
    private var canSave: Bool {
        !stationName.isEmpty &&
        !stationSubtitle.isEmpty &&
        !streamURL.isEmpty &&
        isValidURL(streamURL)
    }
    
    // MARK: - Methods
    
    private func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }
    
    private func testStreamURL() {
        guard isValidURL(streamURL) else {
            validationMessage = "URL invalide"
            showValidation = true
            return
        }
        
        isTestingStream = true
        streamIsValid = false
        
        // Test simple de l'URL
        Task {
            do {
                guard let url = URL(string: streamURL) else { return }
                let (_, response) = try await URLSession.shared.data(from: url)
                
                await MainActor.run {
                    if let httpResponse = response as? HTTPURLResponse,
                       (200...299).contains(httpResponse.statusCode) {
                        streamIsValid = true
                        validationMessage = "Le flux est accessible !"
                    } else {
                        validationMessage = "Le flux n'est pas accessible"
                    }
                    isTestingStream = false
                    showValidation = true
                }
            } catch {
                await MainActor.run {
                    validationMessage = "Erreur lors du test: \(error.localizedDescription)"
                    isTestingStream = false
                    showValidation = true
                }
            }
        }
    }
    
    private func saveCustomStation() {
        let customStation = CustomStation(
            name: stationName,
            subtitle: stationSubtitle,
            streamURL: streamURL,
            logoURL: logoURL.isEmpty ? nil : logoURL,
            categories: Array(selectedCategories)
        )
        
        viewModel.addCustomStation(customStation)
        
        // Feedback haptique
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        dismiss()
    }
}

// MARK: - Custom TextField

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.blue : Color.white.opacity(0.1))
                )
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}