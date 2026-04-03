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
import SFSafeSymbols

@ViewAction(for: DeviceVendorFeature.self)
public struct DeviceVendorScreen: View {
    
    @Perception.Bindable public var store: StoreOf<DeviceVendorFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<DeviceVendorFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                List {
                    switch store.content {
                    case .index:
                        DeviceTypes()
                    case .brands:
                        if let brands = store.brands {
                            Brands(brands)
                        }
                    case .vendor:
                        if let vendor = store.vendor {
                            Vendor(vendor)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
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
    
    // MARK: - Device Types
    
    @ViewBuilder
    private func DeviceTypes() -> some View {
        Section {
            ForEach(DeviceType.allCases) { type in
                Row(symbol: type.icon, title: type.title, type: .navigation) {
                    send(.typeButtonTapped(type))
                }
            }
        }
        .listRowBackground(Color(.Background.teritary))
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    // MARK: - Brands
    
    @ViewBuilder
    private func Brands(_ brands: DeviceBrands) -> some View {
        Header(
            actualCount: brands.actualCount,
            allCount: brands.brands.count
        )
        
        BrandsList(brands.brands, type: brands.type)
    }
    
    @ViewBuilder
    private func BrandsList(_ brands: [DeviceBrands.Brand], type: DeviceType) -> some View {
        Section {
            ForEach(brands) { brand in
                WithPerceptionTracking {
                    if store.categorySelection == .all {
                        Row(title: LocalizedStringKey(brand.name), type: .navigation) {
                            send(.vendorButtonTapped(brand.tag, type))
                        }
                    } else if store.categorySelection == .actual, brand.isActual {
                        Row(title: LocalizedStringKey(brand.name), type: .navigation) {
                            send(.vendorButtonTapped(brand.tag, type))
                        }
                    }
                }
            }
        }
        .listRowBackground(Color(.Background.teritary))
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    // MARK: - Vendor
    
    @ViewBuilder
    private func Vendor(_ vendor: DeviceVendor) -> some View {
        Header(
            actualCount: vendor.actualCount,
            allCount: vendor.products.count
        )
        
        VendorProducts(vendor.products)
    }
    
    // MARK: - Products
    
    @ViewBuilder
    private func VendorProducts(_ products: [DeviceVendor.Product]) -> some View {
        Section {
            ForEach(products) { product in
                WithPerceptionTracking {
                    if store.categorySelection == .all {
                        VendorProductRow(product)
                    } else if store.categorySelection == .actual, product.isActual {
                        VendorProductRow(product)
                    }
                }
            }
        }
        .listRowBackground(Color(.Background.teritary))
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    @ViewBuilder
    private func VendorProductRow(_ product: DeviceVendor.Product) -> some View {
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
                
                VendorProductSpecifications(product.entries)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 19)
        .background(
            Color(.Background.teritary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
    }
    
    @ViewBuilder
    private func VendorProductSpecifications(_ specifications: [DeviceVendor.Product.Entry]) -> some View {
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
        WithPerceptionTracking {
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
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header(actualCount: Int, allCount: Int) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                InformationRow(title: "Actual", content: String(actualCount))
                
                InformationRow(title: "All", content: String(allCount))
            }
            
            ChangeCategoryButton()
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    // MARK: - Row
    
    enum RowType {
        case basic
        case navigation
    }
    
    @ViewBuilder
    private func Row(symbol: SFSymbol? = nil, title: LocalizedStringKey, type: RowType, action: @escaping () -> Void = {}) -> some View {
        HStack(spacing: 0) { // Hacky HStack to enable tap animations
            Button {
                action()
            } label: {
                HStack(spacing: 0) {
                    if let symbol {
                        Image(systemSymbol: symbol)
                            .font(.title2)
                            .foregroundStyle(tintColor)
                            .frame(width: 36)
                            .padding(.trailing, 12)
                    }
                    
                    Text(title, bundle: .module)
                        .font(.body)
                        .foregroundStyle(Color(.Labels.primary))
                    
                    Spacer(minLength: 8)
                    
                    switch type {
                    case .basic:
                        EmptyView()
                        
                    case .navigation:
                        Image(systemSymbol: .chevronRight)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(.Labels.quintuple))
                    }
                }
                .contentShape(Rectangle())
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .buttonStyle(.plain)
        .frame(height: 60)
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
        return switch store.content {
        case .index:
            String(localized: "Devices", bundle: .module)
        case .brands:
            if let brand = store.brands {
                brand.typeName
            } else {
                String(localized: "Loading...", bundle: .module)
            }
        case .vendor:
            if let vendor = store.vendor {
                "\(vendor.name) (\(vendor.categoryName))"
            } else {
                String(localized: "Loading...", bundle: .module)
            }
        }
    }
}

// MARK: - Previews

#Preview("Index") {
    NavigationStack {
        DeviceVendorScreen(
            store: Store(
                initialState: DeviceVendorFeature.State(
                    content: .index
                )
            ) {
                DeviceVendorFeature()
            }
        )
    }
}

#Preview("Phone Brands") {
    NavigationStack {
        DeviceVendorScreen(
            store: Store(
                initialState: DeviceVendorFeature.State(
                    content: .brands(.phone)
                )
            ) {
                DeviceVendorFeature()
            }
        )
    }
}

#Preview("Phone Vendor") {
    NavigationStack {
        DeviceVendorScreen(
            store: Store(
                initialState: DeviceVendorFeature.State(
                    content: .vendor("apple", type: .phone)
                )
            ) {
                DeviceVendorFeature()
            }
        )
    }
}
