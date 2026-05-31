import Foundation
import SwiftData
import UIKit
import Vision
import CoreImage.CIFilterBuiltins

// MARK: - SwiftData Model

@Model
final class Coupon {
    @Attribute(.unique) var id: UUID
    var imageName: String
    var brand: String
    var expirationDate: Date
    var barcodeValue: String?
    var barcodeType: String? // "qr" or "code128"
    var isUsed: Bool
    var createdDate: Date
    var memo: String?
    var isNotificationEnabled: Bool
    
    init(
        id: UUID = UUID(),
        imageName: String,
        brand: String,
        expirationDate: Date,
        barcodeValue: String? = nil,
        barcodeType: String? = nil,
        isUsed: Bool = false,
        createdDate: Date = Date(),
        memo: String? = nil,
        isNotificationEnabled: Bool = false
    ) {
        self.id = id
        self.imageName = imageName
        self.brand = brand
        self.expirationDate = expirationDate
        self.barcodeValue = barcodeValue
        self.barcodeType = barcodeType
        self.isUsed = isUsed
        self.createdDate = createdDate
        self.memo = memo
        self.isNotificationEnabled = isNotificationEnabled
    }
    
    var isExpired: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expDay = calendar.startOfDay(for: expirationDate)
        return expDay < today && !isUsed
    }
    
    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expDay = calendar.startOfDay(for: expirationDate)
        let components = calendar.dateComponents([.day], from: today, to: expDay)
        return components.day ?? 0
    }
}

// MARK: - Coupon Image Storage Manager

class CouponImageStore {
    static let shared = CouponImageStore()
    
    private let fileManager = FileManager.default
    
    private var directoryURL: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let couponDir = documentsDirectory.appendingPathComponent("coupon_images", isDirectory: true)
        
        if !fileManager.fileExists(atPath: couponDir.path) {
            try? fileManager.createDirectory(at: couponDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        return couponDir
    }
    
    func saveImage(_ image: UIImage, name: String) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return false }
        let fileURL = directoryURL.appendingPathComponent(name)
        do {
            try data.write(to: fileURL)
            return true
        } catch {
            print("Failed to save coupon image: \(error)")
            return false
        }
    }
    
    func loadImage(name: String) -> UIImage? {
        let fileURL = directoryURL.appendingPathComponent(name)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    func deleteImage(name: String) {
        let fileURL = directoryURL.appendingPathComponent(name)
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
        }
    }
}

// MARK: - OCR & Barcode Service (Vision)

class CouponOCRProcessor {
    struct OCRResult {
        let brand: String?
        let expirationDate: Date?
        let barcodeValue: String?
        let barcodeType: String?
    }
    
    static func processImage(_ image: UIImage) async -> OCRResult {
        guard let cgImage = image.cgImage else {
            return OCRResult(brand: nil, expirationDate: nil, barcodeValue: nil, barcodeType: nil)
        }
        
        // 1. Barcode Detection
        var detectedBarcode: String? = nil
        var detectedBarcodeType: String? = nil
        
        let barcodeRequest = VNDetectBarcodesRequest()
        let barcodeHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try barcodeHandler.perform([barcodeRequest])
            if let results = barcodeRequest.results, let firstBarcode = results.first {
                detectedBarcode = firstBarcode.payloadStringValue
                let symbology = firstBarcode.symbology
                if symbology == .qr {
                    detectedBarcodeType = "qr"
                } else {
                    detectedBarcodeType = "code128"
                }
            }
        } catch {
            print("Barcode detection failed: \(error)")
        }
        
        // 2. Text Recognition (OCR)
        var recognizedTexts: [String] = []
        let textRequest = VNRecognizeTextRequest { request, error in
            guard let results = request.results as? [VNRecognizedTextObservation] else { return }
            for observation in results {
                if let candidate = observation.topCandidates(1).first {
                    recognizedTexts.append(candidate.string)
                }
            }
        }
        textRequest.recognitionLevel = .accurate
        textRequest.recognitionLanguages = ["ko-KR", "en-US"]
        
        let textHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try textHandler.perform([textRequest])
        } catch {
            print("Text recognition failed: \(error)")
        }
        
        // 3. Extract metadata with heuristics
        let parsedDate = parseExpirationDate(from: recognizedTexts)
        let parsedBrand = parseBrand(from: recognizedTexts)
        
        return OCRResult(
            brand: parsedBrand,
            expirationDate: parsedDate,
            barcodeValue: detectedBarcode,
            barcodeType: detectedBarcodeType
        )
    }
    
    private static func parseExpirationDate(from texts: [String]) -> Date? {
        let patterns = [
            #"\d{4}[.-/]\d{2}[.-/]\d{2}"#, // 2026.05.31, 2026-05-31, 2026/05/31
            #"\d{2}[.-/]\d{2}[.-/]\d{2}"#, // 26.05.31
            #"\d{4}년\s*\d{1,2}월\s*\d{1,2}일"#, // 2026년 5월 31일
            #"\d{2}년\s*\d{1,2}월\s*\d{1,2}일"#, // 26년 5월 31일
            #"\d{8}"# // 20260531
        ]
        
        var dateLines: [String] = []
        var otherLines: [String] = []
        
        let dateKeywords = ["기한", "유효", "만료", "까지", "VALID", "EXP", "DATE"]
        for line in texts {
            let upperLine = line.uppercased()
            if dateKeywords.contains(where: { upperLine.contains($0) }) {
                dateLines.append(line)
            } else {
                otherLines.append(line)
            }
        }
        
        let orderedLines = dateLines + otherLines
        
        for line in orderedLines {
            for pattern in patterns {
                if let range = line.range(of: pattern, options: .regularExpression) {
                    let dateStr = String(line[range])
                    if let date = convertToDate(dateStr) {
                        return date
                    }
                }
            }
        }
        return nil
    }
    
    private static func convertToDate(_ str: String) -> Date? {
        let cleanStr = str.replacingOccurrences(of: " ", with: "")
        
        let formatters = [
            "yyyy.MM.dd",
            "yyyy-MM-dd",
            "yyyy/MM/dd",
            "yy.MM.dd",
            "yy-MM-dd",
            "yy/MM/dd",
            "yyyy년MM월dd일",
            "yy년MM월dd일",
            "yyyyMMdd"
        ]
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        
        for format in formatters {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: cleanStr) {
                let calendar = Calendar.current
                let year = calendar.component(.year, from: date)
                if year < 100 {
                    if let correctedDate = calendar.date(byAdding: .year, value: 2000, to: date) {
                        return correctedDate
                    }
                }
                return date
            }
        }
        return nil
    }
    
    private static func parseBrand(from texts: [String]) -> String? {
        let brandKeywords: [String: [String]] = [
            "스타벅스": ["스타벅스", "STARBUCKS", "스벅"],
            "투썸플레이스": ["투썸", "TWOSOME"],
            "올리브영": ["올리브영", "OLIVE YOUNG", "올영"],
            "배스킨라빈스": ["배스킨라빈스", "베스킨라빈스", "BASKIN", "BR", "배스킨"],
            "설빙": ["설빙", "SULBING"],
            "던킨": ["던킨", "DUNKIN"],
            "이디야": ["이디야", "EDIYA"],
            "메가커피": ["메가커피", "MEGA COFFEE", "메가 MGC"],
            "컴포즈커피": ["컴포즈", "COMPOSE COFFEE"],
            "빽다방": ["빽다방", "PAIK"],
            "버거킹": ["버거킹", "BURGER KING"],
            "맥도날드": ["맥도날드", "MCDONALD"],
            "롯데리아": ["롯데리아", "LOTTERIA"],
            "KFC": ["KFC"],
            "서브웨이": ["서브웨이", "SUBWAY"],
            "파리바게뜨": ["파리바게뜨", "파리바게트", "PARIS BAGUETTE"],
            "뚜레쥬르": ["뚜레쥬르", "TOUS LES JOURS"],
            "CU": ["CU", "씨유"],
            "GS25": ["GS25", "지에스"],
            "세븐일레븐": ["세븐일레븐", "SEVEN ELEVEN"],
            "카카오톡": ["카카오", "KAKAO", "선물하기"]
        ]
        
        for line in texts {
            let upperLine = line.uppercased()
            for (brand, keywords) in brandKeywords {
                for keyword in keywords {
                    if upperLine.contains(keyword.uppercased()) {
                        return brand
                    }
                }
            }
        }
        
        for line in texts {
            let patterns = [
                #"사용처\s*:\s*([^\s]+)"#,
                #"교환처\s*:\s*([^\s]+)"#,
                #"발행처\s*:\s*([^\s]+)"#
            ]
            for pattern in patterns {
                if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                    let nsString = line as NSString
                    let results = regex.matches(in: line, options: [], range: NSRange(location: 0, length: nsString.length))
                    if let match = results.first, match.numberOfRanges > 1 {
                        let brandName = nsString.substring(with: match.range(at: 1))
                        return brandName.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
            }
        }
        
        for line in texts {
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanLine.count > 1 && cleanLine.count < 10 {
                let isAlpha = cleanLine.range(of: "^[a-zA-Z가-힣\\s]+$", options: .regularExpression) != nil
                let isDateKw = ["유효", "기간", "기한", "쿠폰", "상품권", "교환권", "사용"].contains(where: { cleanLine.contains($0) })
                if isAlpha && !isDateKw {
                    return cleanLine
                }
            }
        }
        return nil
    }
}

// MARK: - Barcode & QR Generator (CIFilter)

struct BarcodeGenerator {
    static func generateBarcode(from string: String, type: String?) -> UIImage? {
        let data = string.data(using: .ascii)
        
        let filter: CIFilter
        if type?.lowercased().contains("qr") == true {
            let qrFilter = CIFilter.qrCodeGenerator()
            qrFilter.message = data ?? Data()
            qrFilter.correctionLevel = "M"
            filter = qrFilter
        } else {
            let code128Filter = CIFilter.code128BarcodeGenerator()
            code128Filter.message = data ?? Data()
            code128Filter.quietSpace = 10
            filter = code128Filter
        }
        
        guard let outputImage = filter.outputImage else { return nil }
        
        let scaleX = CGFloat(400) / outputImage.extent.width
        let scaleY = type?.lowercased().contains("qr") == true ? scaleX : CGFloat(120) / outputImage.extent.height
        
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Local Notification Manager

final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    /// Requests notification authorization from the user
    func requestAuthorization() async -> Bool {
        do {
            let authorized = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            print("Notification authorization status: \(authorized)")
            return authorized
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    /// Check current authorization status
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    /// Schedules notifications for a coupon (D-3 and D-1 at 9:00 AM)
    func scheduleNotification(for coupon: Coupon) {
        // Cancel any existing notifications for this coupon first
        cancelNotification(for: coupon)
        
        guard !coupon.isUsed, !coupon.isExpired, coupon.isNotificationEnabled else {
            print("Skipping notification schedule for '\(coupon.brand)': isUsed=\(coupon.isUsed), isExpired=\(coupon.isExpired), enabled=\(coupon.isNotificationEnabled)")
            return
        }
        
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        
        // Start of day of the expiration date
        let expirationStartOfDay = calendar.startOfDay(for: coupon.expirationDate)
        
        let reminders = [
            (daysBefore: 3, idSuffix: "_d3", body: "사용 기한이 3일 남았습니다. 잊지 말고 사용하세요!"),
            (daysBefore: 1, idSuffix: "_d1", body: "사용 기한이 하루 남았습니다! 오늘 꼭 사용하세요.")
        ]
        
        for reminder in reminders {
            // Subtract days
            guard let alertDate = calendar.date(byAdding: .day, value: -reminder.daysBefore, to: expirationStartOfDay),
                  let finalAlertDate = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: alertDate) else {
                continue
            }
            
            // Only schedule if the calculated time is in the future
            if finalAlertDate > Date() {
                let content = UNMutableNotificationContent()
                content.title = "쿠폰 만료 임박: \(coupon.brand)"
                content.body = reminder.body
                content.sound = .default
                
                // Keep expiration date on the notification if needed
                content.userInfo = ["couponId": coupon.id.uuidString]
                
                let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: finalAlertDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                
                let identifier = "\(coupon.id.uuidString)\(reminder.idSuffix)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                center.add(request) { error in
                    if let error = error {
                        print("Failed to schedule notification for \(coupon.brand) (ID: \(identifier)): \(error.localizedDescription)")
                    } else {
                        print("Successfully scheduled notification for \(coupon.brand) at \(finalAlertDate) (ID: \(identifier))")
                    }
                }
            } else {
                print("Skipping reminder (\(reminder.daysBefore) days before) for \(coupon.brand) because alert date \(finalAlertDate) is in the past.")
            }
        }
        
        // Log currently pending notifications for debugging
        printPendingNotifications()
    }
    
    /// Cancels all pending notifications for a coupon
    func cancelNotification(for coupon: Coupon) {
        let center = UNUserNotificationCenter.current()
        let identifiers = [
            "\(coupon.id.uuidString)_d3",
            "\(coupon.id.uuidString)_d1"
        ]
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        print("Cancelled pending notifications for \(coupon.brand) (IDs: \(identifiers))")
    }
    
    /// Debug helper to print all pending notification requests
    func printPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("--- Pending Notification Requests (\(requests.count)) ---")
            for request in requests {
                let triggerInfo: String
                if let trigger = request.trigger as? UNCalendarNotificationTrigger, let nextDate = trigger.nextTriggerDate() {
                    triggerInfo = "Trigger Date: \(nextDate)"
                } else {
                    triggerInfo = "Trigger: \(String(describing: request.trigger))"
                }
                print("- ID: \(request.identifier) | Title: \(request.content.title) | \(triggerInfo)")
            }
            print("--------------------------------------------------")
        }
    }
}
