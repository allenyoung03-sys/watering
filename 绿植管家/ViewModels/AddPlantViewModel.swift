//
//  AddPlantViewModel.swift
//  绿植管家
//

import Combine
import PhotosUI
import SwiftUI

@MainActor
class AddPlantViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var searchText = ""
    @Published var isIdentifying = false
    @Published var identificationError: String?
    @Published var identificationResult: PlantIdentificationResult?
    @Published var showResult = false

    private let identificationService = PlantIdentificationService.shared

    func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else {
            selectedImage = nil
            return
        }
        if let data = try? await item.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            selectedImage = image
        } else {
            selectedImage = nil
        }
    }

    func identifyFromImage() async {
        guard let image = selectedImage else { return }
        isIdentifying = true
        identificationError = nil
        defer { isIdentifying = false }
        do {
            let result = try await identificationService.identifyPlant(image: image)
            identificationResult = result
            showResult = true
        } catch {
            identificationError = error.localizedDescription
            handleError(error, context: "图片识别植物")
        }
    }

    func searchByName() async {
        let name = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        isIdentifying = true
        identificationError = nil
        defer { isIdentifying = false }
        do {
            let results = try await identificationService.searchPlant(name: name)
            if let first = results.first {
                identificationResult = first
                showResult = true
            } else {
                identificationError = "未找到植物"
                handleAppError(.validationError("未找到匹配的植物"), context: "搜索植物")
            }
        } catch {
            identificationError = error.localizedDescription
            handleError(error, context: "搜索植物")
        }
    }

    func clearAndDismiss() {
        selectedItem = nil
        selectedImage = nil
        searchText = ""
        identificationResult = nil
        showResult = false
        identificationError = nil
    }
}
