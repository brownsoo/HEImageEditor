import SwiftUI
import SwiftData

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Coupon Card View (Apple Wallet Style)

struct CouponCardView: View {
    let coupon: Coupon
    
    private var cardGradients: [Color] {
        let brandName = coupon.brand.lowercased()
        if brandName.contains("스타벅스") || brandName.contains("starbucks") || brandName.contains("스벅") {
            return [Color(hex: "006241"), Color(hex: "00402b")]
        } else if brandName.contains("투썸") || brandName.contains("twosome") {
            return [Color(hex: "d50032"), Color(hex: "8b001a")]
        } else if brandName.contains("올리브영") || brandName.contains("olive young") || brandName.contains("올영") {
            return [Color(hex: "9ebb11"), Color(hex: "79920d")]
        } else if brandName.contains("카카오") || brandName.contains("kakao") {
            return [Color(hex: "fee500"), Color(hex: "e0c500")]
        } else if brandName.contains("배스킨") || brandName.contains("베스킨") || brandName.contains("baskin") || brandName.contains("br") {
            return [Color(hex: "ff007f"), Color(hex: "00a3e0")]
        } else if brandName.contains("메가") || brandName.contains("mega") {
            return [Color(hex: "ffd600"), Color(hex: "cca200")]
        } else if brandName.contains("컴포즈") || brandName.contains("compose") {
            return [Color(hex: "ffd600"), Color(hex: "1a1a1a")]
        } else if brandName.contains("이디야") || brandName.contains("ediya") {
            return [Color(hex: "002e7a"), Color(hex: "001845")]
        } else if brandName.contains("백다방") || brandName.contains("빽다방") || brandName.contains("paik") {
            return [Color(hex: "004b93"), Color(hex: "ffd000")]
        } else {
            // Default elegant gray metal
            return [Color(hex: "2e3436"), Color(hex: "1c2021")]
        }
    }
    
    private var textColor: Color {
        let brandName = coupon.brand.lowercased()
        if brandName.contains("카카오") || brandName.contains("kakao") || brandName.contains("메가") || brandName.contains("mega") {
            return .black
        }
        return .white
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(coupon.brand)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(textColor)
                        .lineLimit(1)
                    
                    Text("COUPON PASS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(textColor.opacity(0.6))
                        .tracking(1.5)
                }
                
                Spacer()
                
                // Expiration D-Day Badge
                if coupon.isUsed {
                    Text("사용 완료")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(20)
                } else if coupon.isExpired {
                    Text("기간 만료")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(20)
                } else {
                    let dDay = coupon.daysRemaining
                    Text(dDay == 0 ? "D-Day" : "D-\(dDay)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(dDay <= 3 ? Color.red.opacity(0.8) : (dDay <= 7 ? Color.orange.opacity(0.8) : Color.green.opacity(0.8)))
                        .cornerRadius(20)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer()
            
            // Barcode Indicator graphic
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        ForEach(0..<25) { index in
                            Rectangle()
                                .fill(textColor.opacity(index % 3 == 0 ? 0.3 : 0.7))
                                .frame(width: CGFloat([1, 2, 3].randomElement() ?? 2), height: 28)
                        }
                    }
                    if let code = coupon.barcodeValue, !code.isEmpty {
                        Text(code)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(textColor.opacity(0.7))
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Footer Row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("사용기한")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(textColor.opacity(0.6))
                    
                    Text(coupon.expirationDate, style: .date)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(textColor)
                }
                
                Spacer()
                
                if let memo = coupon.memo, !memo.isEmpty {
                    Text(memo)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textColor.opacity(0.8))
                        .lineLimit(1)
                        .frame(maxWidth: 150, alignment: .trailing)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(height: 180)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(gradient: Gradient(colors: cardGradients), startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.35), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}

// MARK: - Zoomable Image View (Pinch & Zoom Modal)

struct ZoomableImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = lastScale * value
                        }
                        .onEnded { _ in
                            if scale < 1.0 {
                                withAnimation(.spring()) {
                                    scale = 1.0
                                }
                            }
                            lastScale = scale
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                )
            
            // Close Button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Coupon Detail View (Apple Wallet Detail Card)

struct CouponDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let coupon: Coupon
    @Binding var isPresented: Bool
    
    @State private var showingEditSheet = false
    @State private var showingFullImage = false
    
    // Edit Form State
    @State private var editBrand = ""
    @State private var editBarcode = ""
    @State private var editDate = Date()
    @State private var editMemo = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Card View displayed at the top
                    CouponCardView(coupon: coupon)
                        .padding(.top, 16)
                    
                    // Barcode render (If value exists)
                    if let barcodeVal = coupon.barcodeValue, !barcodeVal.isEmpty {
                        VStack(spacing: 12) {
                            Text("매장 리더기에 이 바코드를 스캔하세요")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            // High Contrast white box
                            VStack(spacing: 8) {
                                if let barcodeImg = BarcodeGenerator.generateBarcode(from: barcodeVal, type: coupon.barcodeType) {
                                    Image(uiImage: barcodeImg)
                                        .resizable()
                                        .interpolation(.none)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: coupon.barcodeType == "qr" ? 140 : 80)
                                        .padding(.vertical, 8)
                                } else {
                                    Text("바코드를 생성할 수 없습니다")
                                        .foregroundColor(.red)
                                }
                                
                                Text(barcodeVal)
                                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .tracking(2.0)
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 4)
                        }
                        .padding(.horizontal, 16)
                    } else {
                        VStack(spacing: 12) {
                            Text("스캔 가능한 바코드가 등록되지 않았습니다")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                prepopulateEditFields()
                                showingEditSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("바코드 번호 추가")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(20)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                    }
                    
                    // Information Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("사용기한")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(coupon.expirationDate, style: .date)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(coupon.isExpired ? .red : .primary)
                        }
                        
                        Divider()
                        
                        HStack(alignment: .top) {
                            Text("메모")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(coupon.memo ?? "입력된 메모가 없습니다.")
                                .font(.system(size: 14))
                                .foregroundColor((coupon.memo ?? "").isEmpty ? .secondary : .primary)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 220, alignment: .trailing)
                        }
                    }
                    .padding(16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // View original image
                        Button(action: { showingFullImage = true }) {
                            HStack {
                                Image(systemName: "photo")
                                Text("원본 쿠폰 이미지 보기")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                        }
                        
                        // Toggle Used state
                        Button(action: {
                            withAnimation(.spring()) {
                                coupon.isUsed.toggle()
                                try? modelContext.save()
                                isPresented = false
                            }
                        }) {
                            HStack {
                                Image(systemName: coupon.isUsed ? "arrow.uturn.backward.circle" : "checkmark.circle")
                                Text(coupon.isUsed ? "다시 사용 가능하게 설정" : "사용 완료로 표시 (보관함 이동)")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(coupon.isUsed ? Color.orange : Color.blue)
                            .cornerRadius(12)
                        }
                        
                        // Delete Button
                        Button(action: {
                            CouponImageStore.shared.deleteImage(name: coupon.imageName)
                            modelContext.delete(coupon)
                            try? modelContext.save()
                            isPresented = false
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("쿠폰 완전히 삭제")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.red.opacity(0.08))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(coupon.brand)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("닫기") { isPresented = false },
                trailing: Button("편집") {
                    prepopulateEditFields()
                    showingEditSheet = true
                }
            )
            .sheet(isPresented: $showingEditSheet) {
                // Edit Sheet
                NavigationView {
                    Form {
                        Section(header: Text("기본 정보")) {
                            TextField("브랜드/사용처", text: $editBrand)
                            TextField("바코드 번호", text: $editBarcode)
                                .keyboardType(.numberPad)
                            DatePicker("사용기한", selection: $editDate, displayedComponents: .date)
                        }
                        
                        Section(header: Text("메모")) {
                            TextField("간단한 메모 입력", text: $editMemo)
                        }
                    }
                    .navigationTitle("상세 정보 수정")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(
                        leading: Button("취소") { showingEditSheet = false },
                        trailing: Button("저장") {
                            coupon.brand = editBrand.trimmingCharacters(in: .whitespacesAndNewlines)
                            coupon.barcodeValue = editBarcode.trimmingCharacters(in: .whitespacesAndNewlines)
                            coupon.expirationDate = editDate
                            coupon.memo = editMemo.trimmingCharacters(in: .whitespacesAndNewlines)
                            // Re-detect barcode type if modified
                            if !editBarcode.isEmpty {
                                coupon.barcodeType = editBarcode.count <= 8 ? "qr" : "code128"
                            } else {
                                coupon.barcodeType = nil
                            }
                            try? modelContext.save()
                            showingEditSheet = false
                        }
                        .disabled(editBrand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    )
                }
            }
            .fullScreenCover(isPresented: $showingFullImage) {
                if let uiImage = CouponImageStore.shared.loadImage(name: coupon.imageName) {
                    ZoomableImageView(image: uiImage, isPresented: $showingFullImage)
                }
            }
        }
    }
    
    private func prepopulateEditFields() {
        editBrand = coupon.brand
        editBarcode = coupon.barcodeValue ?? ""
        editDate = coupon.expirationDate
        editMemo = coupon.memo ?? ""
    }
}

// MARK: - Coupon Confirm & Add View

struct CouponAddConfirmView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    
    @State private var brand = ""
    @State private var barcodeValue = ""
    @State private var expirationDate = Date()
    @State private var memo = ""
    @State private var barcodeType: String? = nil
    
    @State private var isOCRLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Cropped Image Thumbnail Preview
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 220)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.15), radius: 5)
                        .padding(.top, 16)
                    
                    if isOCRLoading {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("이미지 분석 중... (사용처, 유효기간, 바코드 추출)")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 10)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("분석이 완료되었습니다. 내용을 수정 및 확인하세요.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Form fields
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("사용처 / 브랜드")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.secondary)
                            TextField("예: 스타벅스, 올리브영", text: $brand)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("사용기한")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.secondary)
                            DatePicker("사용기한 선택", selection: $expirationDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("바코드 번호 (선택)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.secondary)
                            TextField("숫자 또는 문자 입력", text: $barcodeValue)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("메모 (선택)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.secondary)
                            TextField("예: 선물받은 쿠폰, 텀블러 쿠폰", text: $memo)
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Save Button
                    Button(action: saveCoupon) {
                        Text("쿠폰 지갑에 등록")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            .padding(.bottom, 24)
                    }
                    .disabled(brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("쿠폰 등록 정보 확인")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("취소") { isPresented = false })
            .onAppear {
                performOCR()
            }
        }
    }
    
    private func performOCR() {
        Task {
            let ocrResult = await CouponOCRProcessor.processImage(image)
            
            // UI updates must happen on main thread
            await MainActor.run {
                if let detectedBrand = ocrResult.brand {
                    self.brand = detectedBrand
                }
                if let detectedBarcode = ocrResult.barcodeValue {
                    self.barcodeValue = detectedBarcode
                    self.barcodeType = ocrResult.barcodeType
                }
                if let detectedDate = ocrResult.expirationDate {
                    self.expirationDate = detectedDate
                }
                self.isOCRLoading = false
            }
        }
    }
    
    private func saveCoupon() {
        let trimmedBrand = brand.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBarcode = barcodeValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let imageName = "\(UUID().uuidString).jpg"
        let success = CouponImageStore.shared.saveImage(image, name: imageName)
        
        if success {
            // Deduce barcode type if not set
            let type: String?
            if !trimmedBarcode.isEmpty {
                type = barcodeType ?? (trimmedBarcode.count <= 8 ? "qr" : "code128")
            } else {
                type = nil
            }
            
            let newCoupon = Coupon(
                imageName: imageName,
                brand: trimmedBrand,
                expirationDate: expirationDate,
                barcodeValue: trimmedBarcode.isEmpty ? nil : trimmedBarcode,
                barcodeType: type,
                isUsed: false,
                memo: trimmedMemo.isEmpty ? nil : trimmedMemo
            )
            
            modelContext.insert(newCoupon)
            try? modelContext.save()
            isPresented = false
        }
    }
}

// MARK: - Source Type Wrapper

struct SourceTypeItem: Identifiable {
    let id = UUID()
    let sourceType: UIImagePickerController.SourceType
}

// MARK: - Main Coupon Wallet View

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    
    // SwiftData Queries
    @Query(filter: #Predicate<Coupon> { !$0.isUsed }, sort: \Coupon.expirationDate, order: .forward) private var activeCoupons: [Coupon]
    @Query(filter: #Predicate<Coupon> { $0.isUsed }, sort: \Coupon.expirationDate, order: .reverse) private var usedCoupons: [Coupon]
    
    @State private var showingDetailSheet = false
    @State private var selectedCoupon: Coupon? = nil
    
    // Add flow state
    @State private var activeSourceItem: SourceTypeItem? = nil
    @State private var imageToConfirm: UIImage? = nil
    @State private var showingConfirmSheet = false
    @State private var showingAddMenu = false
    
    // Segmented selection
    @State private var selectedTab = 0 // 0: 활성 쿠폰 (지갑), 1: 사용 완료 쿠폰 (보관소)
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    Text("모바일 쿠폰 지갑")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                    
                    Button(action: { showingAddMenu.toggle() }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                    }
                    .confirmationDialog("쿠폰 사진 추가", isPresented: $showingAddMenu, titleVisibility: .visible) {
                        Button("카메라로 촬영하기") {
                            activeSourceItem = SourceTypeItem(sourceType: .camera)
                        }
                        Button("앨범에서 사진 가져오기") {
                            activeSourceItem = SourceTypeItem(sourceType: .photoLibrary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Tabs Segment Control
                Picker("", selection: $selectedTab) {
                    Text("보관 중 (\(activeCoupons.count))").tag(0)
                    Text("사용 완료 (\(usedCoupons.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                if selectedTab == 0 {
                    // Active Wallet (Stacked overlapping cards)
                    if activeCoupons.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "wallet.pass")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary.opacity(0.6))
                            Text("지갑에 활성화된 쿠폰이 없습니다.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("우측 상단 + 버튼을 눌러 추가하세요.")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary.opacity(0.8))
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ScrollView {
                            // Apple Wallet negative spacing layout
                            VStack(spacing: -130) {
                                ForEach(activeCoupons) { coupon in
                                    CouponCardView(coupon: coupon)
                                        .onTapGesture {
                                            selectedCoupon = coupon
                                            showingDetailSheet = true
                                        }
                                        .scrollTransition(.interactive) { content, phase in
                                            content
                                                .scaleEffect(phase.isIdentity ? 1.0 : 0.96)
                                        }
                                }
                            }
                            .padding(.top, 16)
                            .padding(.bottom, 140) // Allow scrolling past final card overlap
                        }
                    }
                } else {
                    // Used/Expired list (non-overlapping grayscale cards for clarity)
                    if usedCoupons.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "archivebox")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary.opacity(0.6))
                            Text("사용 완료된 쿠폰이 없습니다.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(usedCoupons) { coupon in
                                    CouponCardView(coupon: coupon)
                                        .grayscale(0.8)
                                        .opacity(0.6)
                                        .onTapGesture {
                                            selectedCoupon = coupon
                                            showingDetailSheet = true
                                        }
                                }
                            }
                            .padding(.top, 16)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
        }
        .sheet(item: $activeSourceItem) { item in
            PhotoSelectionView(sourceType: item.sourceType) { croppedImage in
                self.imageToConfirm = croppedImage
                self.activeSourceItem = nil
                // Open confirmation form sheet on brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.showingConfirmSheet = true
                }
            } onCancel: {
                self.activeSourceItem = nil
            }
            .edgesIgnoringSafeArea(.all)
        }
        .sheet(isPresented: $showingConfirmSheet) {
            if let img = imageToConfirm {
                CouponAddConfirmView(image: img, isPresented: $showingConfirmSheet)
            }
        }
        .sheet(isPresented: $showingDetailSheet) {
            if let coupon = selectedCoupon {
                CouponDetailView(coupon: coupon, isPresented: $showingDetailSheet)
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
