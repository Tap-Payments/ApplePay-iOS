import UIKit

protocol TapApplePaySettingsDelegate: AnyObject {
    func didUpdateConfig(_ config: [String: Any])
}

/// A simple programmatic settings screen for tweaking the Apple Pay config at runtime.
class TapApplePaySettingsViewController: UITableViewController {
    
    weak var delegate: TapApplePaySettingsDelegate?
    var config: [String: Any] = [:]
    
    // Editable field identifiers
    private enum Row: Int, CaseIterable {
        case publicKey
        case merchantId
        case amount
        case currency
        case customerEmail
        case customerPhone
        case locale
        case theme
        case edges
        case scope
        case type
        case supportedBrands
        case supportedCards
        case supportedRegions
        case supportedCountries
        case shippingContactFields
        case couponCode
        // Shipping Method 1
        case shipping1Label
        case shipping1Detail
        case shipping1Amount
        case shipping1Identifier
        // Shipping Method 2
        case shipping2Label
        case shipping2Detail
        case shipping2Amount
        case shipping2Identifier
        // Item
        case itemLabel
        case itemAmount
        case paymentTiming
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Apply",
            style: .done,
            target: self,
            action: #selector(applyTapped)
        )
    }
    
    // MARK: - Table
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Row.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        let row = Row(rawValue: indexPath.row)!
        cell.textLabel?.text = label(for: row)
        cell.detailTextLabel?.text = value(for: row)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = Row(rawValue: indexPath.row)!
        presentEditor(for: row)
    }
    
    // MARK: - Labels / values
    
    private func label(for row: Row) -> String {
        switch row {
        case .publicKey:     return "Public Key"
        case .merchantId:    return "Merchant ID"
        case .amount:        return "Amount"
        case .currency:      return "Currency"
        case .customerEmail: return "Customer Email"
        case .customerPhone: return "Customer Phone"
        case .locale:        return "Locale"
        case .theme:         return "Theme"
        case .edges:         return "Edges"
        case .scope:         return "Scope"
        case .type:          return "Type"
        case .supportedBrands:        return "Supported Brands"
        case .supportedCards:         return "Supported Cards"
        case .supportedRegions:       return "Supported Regions"
        case .supportedCountries:     return "Supported Countries"
        case .shippingContactFields:  return "Shipping Contact Fields"
        case .couponCode:             return "Coupon Code"
        case .shipping1Label:         return "Shipping 1 - Label"
        case .shipping1Detail:        return "Shipping 1 - Detail"
        case .shipping1Amount:        return "Shipping 1 - Amount"
        case .shipping1Identifier:    return "Shipping 1 - Identifier"
        case .shipping2Label:         return "Shipping 2 - Label"
        case .shipping2Detail:        return "Shipping 2 - Detail"
        case .shipping2Amount:        return "Shipping 2 - Amount"
        case .shipping2Identifier:    return "Shipping 2 - Identifier"
        case .itemLabel:              return "Item - Label"
        case .itemAmount:             return "Item - Amount"
        case .paymentTiming:          return "Item - Payment Timing"
        }
    }
    
    private func value(for row: Row) -> String {
        switch row {
        case .publicKey:
            return config["publicKey"] as? String ?? ""
        case .merchantId:
            return (config["merchant"] as? [String: Any])?["id"] as? String ?? ""
        case .amount:
            return String((config["transaction"] as? [String: Any])?["amount"] as? Double ?? 1.0)
        case .currency:
            return (config["transaction"] as? [String: Any])?["currency"] as? String ?? "SAR"
        case .customerEmail:
            return ((config["customer"] as? [String: Any])?["contact"] as? [String: Any])?["email"] as? String ?? ""
        case .customerPhone:
            let phone = (((config["customer"] as? [String: Any])?["contact"] as? [String: Any])?["phone"] as? [String: Any])
            return "\(phone?["countryCode"] as? String ?? "")\(phone?["number"] as? String ?? "")"
        case .locale:
            return (config["interface"] as? [String: Any])?["locale"] as? String ?? "en"
        case .theme:
            return (config["interface"] as? [String: Any])?["theme"] as? String ?? "dark"
        case .edges:
            return (config["interface"] as? [String: Any])?["edges"] as? String ?? "curved"
        case .scope:
            return config["scope"] as? String ?? "AppleToken"
        case .type:
            return (config["interface"] as? [String: Any])?["type"] as? String ?? "buy"
        case .supportedBrands:
            let brands = ((config["acceptance"] as? [String: Any])?["supportedBrands"] as? [String]) ?? []
            return brands.joined(separator: ", ")
        case .supportedCards:
            let cards = ((config["acceptance"] as? [String: Any])?["supportedCards"] as? [String]) ?? []
            return cards.joined(separator: ", ")
        case .supportedRegions:
            let regions = ((config["acceptance"] as? [String: Any])?["supportedRegions"] as? [String]) ?? []
            return regions.joined(separator: ", ")
        case .supportedCountries:
            let countries = ((config["acceptance"] as? [String: Any])?["supportedCountries"] as? [String]) ?? []
            return countries.joined(separator: ", ")
        case .shippingContactFields:
            let fields = ((config["features"] as? [String: Any])?["shippingContactFields"] as? [String]) ?? []
            return fields.joined(separator: ", ")
        case .couponCode:
            return (config["transaction"] as? [String: Any])?["couponCode"] as? String ?? ""
        case .shipping1Label:
            let shipping = ((config["transaction"] as? [String: Any])?["shipping"] as? [[String: Any]]) ?? []
            return shipping.count > 0 ? (shipping[0]["label"] as? String ?? "") : ""
        case .shipping1Detail:
            let shipping = ((config["transaction"] as? [String: Any])?["shipping"] as? [[String: Any]]) ?? []
            return shipping.count > 0 ? (shipping[0]["detail"] as? String ?? "") : ""
        case .shipping1Amount:
            let shipping = ((config["transaction"] as? [String: Any])?["shipping"] as? [[String: Any]]) ?? []
            return shipping.count > 0 ? (shipping[0]["amount"] as? String ?? "") : ""
        case .shipping1Identifier:
            let shipping = ((config["transaction"] as? [String: Any])?["shipping"] as? [[String: Any]]) ?? []
            return shipping.count > 0 ? (shipping[0]["identifier"] as? String ?? "") : ""
        case .shipping2Label:
            let shipping = ((config["transaction"] as? [String: Any])?["shipping"] as? [[String: Any]]) ?? []
            return shipping.count > 1 ? (shipping[1]["label"] as? String ?? "") : ""
        case .shipping2Detail:
            let shipping = ((config["transaction"] as? [String: Any])?["shipping"] as? [[String: Any]]) ?? []
            return shipping.count > 1 ? (shipping[1]["detail"] as? String ?? "") : ""
        case .shipping2Amount:
            let shipping = ((config["transaction"] as? [String: Any])?["shipping"] as? [[String: Any]]) ?? []
            return shipping.count > 1 ? (shipping[1]["amount"] as? String ?? "") : ""
        case .shipping2Identifier:
            let shipping = ((config["transaction"] as? [String: Any])?["shipping"] as? [[String: Any]]) ?? []
            return shipping.count > 1 ? (shipping[1]["identifier"] as? String ?? "") : ""
        case .itemLabel:
            let items = ((config["transaction"] as? [String: Any])?["items"] as? [[String: Any]]) ?? []
            return items.count > 0 ? (items[0]["label"] as? String ?? "") : ""
        case .itemAmount:
            let items = ((config["transaction"] as? [String: Any])?["items"] as? [[String: Any]]) ?? []
            return items.count > 0 ? (items[0]["amount"] as? String ?? "") : ""
        case .paymentTiming:
            let items = ((config["transaction"] as? [String: Any])?["items"] as? [[String: Any]]) ?? []
            return items.count > 0 ? (items[0]["paymentTiming"] as? String ?? "immediate") : "immediate"
        }
    }
    // MARK: - Inline editor
    
    private func presentEditor(for row: Row) {
        let currentValue = value(for: row)
        
        // Multi-select checkbox fields
        if isMultiSelectField(row) {
            presentMultiSelectEditor(for: row)
            return
        }
        
        // For fields with fixed options show an action sheet picker
        if let options = options(for: row) {
            let sheet = UIAlertController(title: label(for: row), message: nil, preferredStyle: .actionSheet)
            for option in options {
                sheet.addAction(.init(title: option, style: .default) { _ in
                    self.applyValue(option, for: row)
                })
            }
            sheet.addAction(.init(title: "Cancel", style: .cancel))
            present(sheet, animated: true)
            return
        }
        
        // Free-text editor
        let alert = UIAlertController(title: label(for: row), message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = currentValue
            tf.clearButtonMode = .always
        }
        alert.addAction(.init(title: "Cancel", style: .cancel))
        alert.addAction(.init(title: "OK", style: .default) { _ in
            let text = alert.textFields?.first?.text ?? currentValue
            self.applyValue(text, for: row)
        })
        present(alert, animated: true)
    }
    
    private func isMultiSelectField(_ row: Row) -> Bool {
        switch row {
        case .supportedBrands, .supportedCards, .supportedRegions, .supportedCountries, .shippingContactFields:
            return true
        default:
            return false
        }
    }
    
    private func presentMultiSelectEditor(for row: Row) {
        guard let allOptions = options(for: row) else { return }
        
        let currentValues = getCurrentValues(for: row)
        let vc = MultiSelectBottomSheetViewController(
            title: label(for: row),
            options: allOptions,
            selectedValues: currentValues
        ) { [weak self] selectedValues in
            self?.applyMultiSelectValue(selectedValues, for: row)
        }
        
        let navController = UINavigationController(rootViewController: vc)
        navController.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = navController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }
        present(navController, animated: true)
    }
    
    private func getCurrentValues(for row: Row) -> [String] {
        switch row {
        case .supportedBrands:
            return ((config["acceptance"] as? [String: Any])?["supportedBrands"] as? [String]) ?? []
        case .supportedCards:
            return ((config["acceptance"] as? [String: Any])?["supportedCards"] as? [String]) ?? []
        case .supportedRegions:
            return ((config["acceptance"] as? [String: Any])?["supportedRegions"] as? [String]) ?? []
        case .supportedCountries:
            return ((config["acceptance"] as? [String: Any])?["supportedCountries"] as? [String]) ?? []
        case .shippingContactFields:
            return ((config["features"] as? [String: Any])?["shippingContactFields"] as? [String]) ?? []
        default:
            return []
        }
    }
    
    private func applyMultiSelectValue(_ values: [String], for row: Row) {
        switch row {
        case .supportedBrands:
            set(value: values, atPath: ["acceptance", "supportedBrands"])
        case .supportedCards:
            set(value: values, atPath: ["acceptance", "supportedCards"])
        case .supportedRegions:
            set(value: values, atPath: ["acceptance", "supportedRegions"])
        case .supportedCountries:
            set(value: values, atPath: ["acceptance", "supportedCountries"])
        case .shippingContactFields:
            set(value: values, atPath: ["features", "shippingContactFields"])
        default:
            break
        }
        tableView.reloadData()
    }
    
    private func options(for row: Row) -> [String]? {
        switch row {
        case .locale:      return ["en", "ar"]
        case .theme:       return ["dark", "light"]
        case .edges:       return ["curved", "straight"]
        case .scope:       return ["AppleToken", "TapToken"]
        case .type:        return ["book", "buy", "check-out", "pay", "plain", "subscribe"]
        case .supportedBrands:    return ["amex", "mada", "masterCard", "visa", "chinaUnionPay", "discover", "electron", "jcb", "maestro"]
        case .supportedCards:     return ["credit", "debit"]
        case .supportedRegions:   return ["LOCAL", "REGIONAL", "GLOBAL"]
        case .supportedCountries: return ["AF", "AL", "DZ", "AS", "AD", "AO", "AI", "AQ", "AG", "AR", "AM", "AW", "AU", "AT", "AZ", "BS", "BH", "BD", "BB", "BY", "BE", "BZ", "BJ", "BM", "BT", "BO", "BQ", "BA", "BW", "BV", "BR", "IO", "BN", "BG", "BF", "BI", "CV", "KH", "CM", "CA", "KY", "CF", "TD", "CL", "CN", "CX", "CC", "CO", "KM", "CD", "CG", "CK", "CR", "HR", "CU", "CW", "CY", "CZ", "CI", "DK", "DJ", "DM", "DO", "EC", "EG", "SV", "GQ", "ER", "EE", "SZ", "ET", "FK", "FO", "FJ", "FI", "FR", "GF", "PF", "TF", "GA", "GM", "GE", "DE", "GH", "GI", "GR", "GL", "GD", "GP", "GU", "GT", "GG", "GN", "GW", "GY", "HT", "HM", "VA", "HN", "HK", "HU", "IS", "IN", "ID", "IR", "IQ", "IE", "IM", "IL", "IT", "JM", "JP", "JE", "JO", "KZ", "KE", "KI", "KP", "KR", "KW", "KG", "LA", "LV", "LB", "LS", "LR", "LY", "LI", "LT", "LU", "MO", "MG", "MW", "MY", "MV", "ML", "MT", "MH", "MQ", "MR", "MU", "YT", "MX", "FM", "MD", "MC", "MN", "ME", "MS", "MA", "MZ", "MM", "NA", "NR", "NP", "NL", "NC", "NZ", "NI", "NE", "NG", "NU", "NF", "MP", "NO", "OM", "PK", "PW", "PS", "PA", "PG", "PY", "PE", "PH", "PN", "PL", "PT", "PR", "QA", "MK", "RO", "RU", "RW", "RE", "BL", "SH", "KN", "LC", "MF", "PM", "VC", "WS", "SM", "ST", "SA", "SN", "RS", "SC", "SL", "SG", "SX", "SK", "SI", "SB", "SO", "ZA", "GS", "SS", "ES", "LK", "SD", "SR", "SJ", "SE", "CH", "SY", "TW", "TJ", "TZ", "TH", "TL", "TG", "TK", "TO", "TT", "TN", "TR", "TM", "TC", "TV", "UG", "UA", "AE", "GB", "UM", "US", "UY", "UZ", "VU", "VE", "VN", "VG", "VI", "WF", "EH", "YE", "ZM", "ZW", "AX"]
        case .shippingContactFields: return ["name", "phone", "email"]
        case .paymentTiming: return ["immediate", "recurring", "deferred", "automaticReload"]
        case .couponCode, .publicKey, .merchantId, .amount, .currency, .customerEmail, .customerPhone, .edges, .shipping1Label, .shipping1Detail, .shipping1Amount, .shipping1Identifier, .shipping2Label, .shipping2Detail, .shipping2Amount, .shipping2Identifier, .itemLabel, .itemAmount:
            return nil
        }
    }
    
    private func applyValue(_ value: String, for row: Row) {
        switch row {
        case .publicKey:
            config["publicKey"] = value
        case .merchantId:
            set(value: value, atPath: ["merchant", "id"])
            set(value: value, atPath: ["merchant", "identifier"])
        case .amount:
            set(value: Double(value) ?? 1.0, atPath: ["transaction", "amount"])
        case .currency:
            set(value: value, atPath: ["transaction", "currency"])
        case .customerEmail:
            set(value: value, atPath: ["customer", "contact", "email"])
        case .customerPhone:
            break // phone editing kept simple — use free text for number only
        case .locale:
            set(value: value, atPath: ["interface", "locale"])
        case .theme:
            set(value: value, atPath: ["interface", "theme"])
        case .edges:
            set(value: value, atPath: ["interface", "edges"])
        case .scope:
            config["scope"] = value
        case .couponCode:
            if value.isEmpty {
                var transaction = config["transaction"] as? [String: Any] ?? [:]
                transaction.removeValue(forKey: "couponCode")
                config["transaction"] = transaction
            } else {
                set(value: value, atPath: ["transaction", "couponCode"])
            }
        case .shipping1Label, .shipping1Detail, .shipping1Amount, .shipping1Identifier:
            updateShipping(index: 0, field: row, value: value)
        case .shipping2Label, .shipping2Detail, .shipping2Amount, .shipping2Identifier:
            updateShipping(index: 1, field: row, value: value)
        case .itemLabel, .itemAmount, .paymentTiming:
            updateItem(field: row, value: value)
        case .supportedBrands, .supportedCards, .supportedRegions, .supportedCountries, .shippingContactFields:
            break // handled by applyMultiSelectValue
        case .type:
            set(value: value, atPath: ["interface", "type"])
        }
        tableView.reloadData()
    }
    
    // MARK: - Deep set helper
    
    private func updateShipping(index: Int, field: Row, value: String) {
        var transaction = config["transaction"] as? [String: Any] ?? [:]
        var shipping = (transaction["shipping"] as? [[String: Any]]) ?? []
        
        // Ensure array has enough elements
        while shipping.count <= index {
            shipping.append([:])
        }
        
        let fieldKey: String
        switch field {
        case .shipping1Label, .shipping2Label: fieldKey = "label"
        case .shipping1Detail, .shipping2Detail: fieldKey = "detail"
        case .shipping1Amount, .shipping2Amount: fieldKey = "amount"
        case .shipping1Identifier, .shipping2Identifier: fieldKey = "identifier"
        case .publicKey, .merchantId, .amount, .currency, .customerEmail, .customerPhone, .locale, .theme, .edges, .scope, .type, .supportedBrands, .supportedCards, .supportedRegions, .supportedCountries, .shippingContactFields, .couponCode, .itemLabel, .itemAmount, .paymentTiming:
            return
        }
        
        if value.isEmpty {
            shipping[index].removeValue(forKey: fieldKey)
        } else {
            shipping[index][fieldKey] = value
        }
        
        // Remove empty shipping entries
        shipping.removeAll { $0.isEmpty }
        
        if shipping.isEmpty {
            transaction.removeValue(forKey: "shipping")
        } else {
            transaction["shipping"] = shipping
        }
        
        config["transaction"] = transaction
    }
    
    private func updateItem(field: Row, value: String) {
        var transaction = config["transaction"] as? [String: Any] ?? [:]
        var items = (transaction["items"] as? [[String: Any]]) ?? [[:]]
        
        let fieldKey: String
        switch field {
        case .itemLabel: fieldKey = "label"
        case .itemAmount: fieldKey = "amount"
        case .paymentTiming: fieldKey = "paymentTiming"
        case .publicKey, .merchantId, .amount, .currency, .customerEmail, .customerPhone, .locale, .theme, .edges, .scope, .type, .supportedBrands, .supportedCards, .supportedRegions, .supportedCountries, .shippingContactFields, .couponCode, .shipping1Label, .shipping1Detail, .shipping1Amount, .shipping1Identifier, .shipping2Label, .shipping2Detail, .shipping2Amount, .shipping2Identifier:
            return
        }
        
        if value.isEmpty {
            items[0].removeValue(forKey: fieldKey)
        } else {
            items[0][fieldKey] = value
        }
        
        if items[0].isEmpty {
            transaction.removeValue(forKey: "items")
        } else {
            transaction["items"] = items
        }
        
        config["transaction"] = transaction
    }
    
    private func set(value: Any, atPath path: [String]) {
        guard !path.isEmpty else { return }
        if path.count == 1 {
            config[path[0]] = value
            return
        }
        var nested = config[path[0]] as? [String: Any] ?? [:]
        setNested(value: value, in: &nested, path: Array(path.dropFirst()))
        config[path[0]] = nested
    }
    
    private func setNested(value: Any, in dict: inout [String: Any], path: [String]) {
        if path.count == 1 {
            let key = path[0]
            // Handle array indices like "0", "1", etc.
            if let arrayIndex = Int(key), var array = dict.first(where: { ($0.value as? [Any]) != nil })?.value as? [[String: Any]], arrayIndex < array.count {
                // This is complex, so we'll just set it as a string key
                dict[key] = value
            } else {
                dict[key] = value
            }
            return
        }
        let key = path[0]
        var nested = dict[key] as? [String: Any] ?? [:]
        setNested(value: value, in: &nested, path: Array(path.dropFirst()))
        dict[key] = nested
    }
    
    // MARK: - Apply
    
    @objc private func applyTapped() {
        delegate?.didUpdateConfig(config)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Multi-Select Bottom Sheet View Controller

class MultiSelectBottomSheetViewController: UITableViewController {
    let headerTitle: String
    let options: [String]
    var selectedValues: [String]
    let onSelection: ([String]) -> Void
    
    init(title: String, options: [String], selectedValues: [String], onSelection: @escaping ([String]) -> Void) {
        self.headerTitle = title
        self.options = options
        self.selectedValues = selectedValues
        self.onSelection = onSelection
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.headerTitle
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Add",
            style: .done,
            target: self,
            action: #selector(addTapped)
        )
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        let option = options[indexPath.row]
        let isSelected = selectedValues.contains(option)
        
        cell.textLabel?.text = option
        cell.accessoryType = isSelected ? .checkmark : .none
        cell.tintColor = .systemBlue
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let option = options[indexPath.row]
        if selectedValues.contains(option) {
            selectedValues.removeAll { $0 == option }
        } else {
            selectedValues.append(option)
        }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func addTapped() {
        onSelection(selectedValues)
        dismiss(animated: true)
    }
}
