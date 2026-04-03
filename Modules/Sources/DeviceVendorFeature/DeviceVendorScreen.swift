//
//  DeviceVendorScreen.swift
//  ForPDA
//
//  Created by Xialtal on 2.04.26.
//

import SwiftUI
import ComposableArchitecture
import Models
import SharedUI
import NukeUI

@ViewAction(for: DeviceVendorFeature.self)
public struct DeviceVendorScreen: View {
    
    @Perception.Bindable public var store: StoreOf<DeviceVendorFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<DeviceVendorFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ScrollView {
                if let vendor = store.vendor {
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            InformationRow(title: "Actual", content: String(vendor.actualCount))
                            
                            InformationRow(title: "All", content: String(vendor.products.count))
                        }
                        
                        ChangeCategoryButton()
                    }
                    .padding(16)
                    
                    Products(vendor.products)
                }
            }
            .navigationTitle(Text(navigationTitleText()))
            .background(Color(.Background.primary))
            .overlay {
                if store.isLoading {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Products
    
    @ViewBuilder
    private func Products(_ products: [DeviceVendor.Product]) -> some View {
        ForEach(products) { product in
            if store.categorySelection == .all {
                ProductRow(product)
            } else if store.categorySelection == .actual, product.isActual {
                ProductRow(product)
            }
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private func ProductRow(_ product: DeviceVendor.Product) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                send(.productButtonTapped(product.tag))
            } label: {
                Text(verbatim: product.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(.Labels.primary))
            }
            .buttonStyle(.plain)
            
            HStack(spacing: 16) {
                LazyImage(url: product.imageUrl) { state in
                    Group {
                        if let image = state.image {
                            image.resizable().scaledToFill()
                        } else {
                            Color(.systemBackground)
                        }
                    }
                    .skeleton(with: state.isLoading, shape: .rectangle)
                }
                .padding(.top, 16)
                .frame(width: 74, height: 74)
                .frame(maxHeight: .infinity, alignment: .top)
                
                ProductSpecifications(product.entries)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 19)
        .background(
            Color(.Background.teritary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        )
    }
    
    @ViewBuilder
    private func ProductSpecifications(_ specifications: [DeviceVendor.Product.Entry]) -> some View {
        VStack(spacing: 6) {
            ForEach(specifications, id: \.name) { specification in
                HStack {
                    Text(verbatim: specification.name)
                        .foregroundStyle(Color(.Labels.teritary))
                    
                    Spacer()
                    
                    Text(verbatim: specification.value)
                        .foregroundStyle(Color(.Labels.primary))
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    // MARK: - Change Category Button
    
    @ViewBuilder
    private func ChangeCategoryButton() -> some View {
        Button {
            send(.changeCategoryButtonTapped(store.categorySelection == .all ? .actual : .all))
        } label: {
            Text(store.categorySelection == .all ? "Show actual" : "Show all", bundle: .module)
                .padding(6)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(tintColor)
        .frame(height: 48)
        .background(Color(.Background.primary))
        .animation(.default, value: store.categorySelection)
    }
    
    // MARK: - Information Row
    
    @ViewBuilder
    private func InformationRow(title: LocalizedStringKey, content: String) -> some View {
        VStack {
            Text(title, bundle: .module)
                .font(.footnote)
                .foregroundStyle(Color(.Labels.teritary))
            
            Text(verbatim: content)
                .font(.body)
                .foregroundStyle(Color(.Labels.primary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .background(
            Color(.Background.teritary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        )
    }
    
    // MARK: - Helpers
    
    private func navigationTitleText() -> String {
        return if let vendor = store.vendor {
            "\(vendor.name) (\(vendor.categoryName))"
        } else {
            String(localized: "Loading...", bundle: .module)
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        DeviceVendorScreen(
            store: Store(
                initialState: DeviceVendorFeature.State(
                    type: .phone,
                    vendorName: "apple"
                )
            ) {
                DeviceVendorFeature()
            }
        )
    }
}
