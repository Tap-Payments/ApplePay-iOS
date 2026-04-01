# ApplePay-iOS

A comprehensive Apple Pay integration library for iOS applications that simplifies secure payment processing with Apple Pay, including 3D Secure support and comprehensive callback handling.

## Overview

ApplePay-iOS provides a complete solution for integrating Apple Pay payments into your iOS application. It handles the complexity of Apple Pay integration while providing a simple, intuitive API for developers.

**Key Features:**
- ✅ Native Apple Pay integration
- ✅ Secure tokenization with SwiftyRSA encryption
- ✅ Comprehensive callback system
- ✅ Flexible configuration options
- ✅ Support for multiple payment scenarios (one-time, recurring, etc.)
- ✅ Customizable UI with dark/light theme support

## Requirements

- **iOS 16.0+** (minimum deployment target)
- **Swift 5.0+**
- **Xcode 14.0+**

## Installation

### Swift Package Manager

1. Open your project's settings
2. Navigate to `Package Dependencies`
3. Add a new package
4. Paste the repository URL: `https://github.com/Tap-Payments/ApplePay-iOS.git`
5. Select your target and add the package

### CocoaPods

Add this to your `Podfile`:

```ruby
pod 'ApplePay-iOS'
pod install
```

## Quick Start

### 1. Import the Framework

```swift
import ApplePay_iOS
```

### 2. Create Configuration Dictionary

Create a configuration dictionary with your Tap public key and payment details:

```swift
let config: [String: Any] = [
    // REQUIRED
    "publicKey": "pk_test_********",
    "scope": "AppleToken",
    "merchant": [
        "id": "********"
    ],
    
    // OPTIONAL
    "interface": [
        "locale": "en",
        "theme": "light",
        "edges": "curved",
        "type": "buy"
    ],
    
    // REQUIRED
    "customer": [
        "name": [
            [
                "lang": "en",
                "first": "John",
                "last": "Smith"
            ]
        ],
        "contact": [
            "email": "john.smith@example.com",
            "phone": [
                "countryCode": "+1",
                "number": "5551234567"
            ]
        ]
    ],
    
    // REQUIRED
    "acceptance": [
        "supportedBrands": ["visa", "masterCard"],
        "supportedCards": ["credit", "debit"]
    ],
    
    // REQUIRED
    "transaction": [
        "amount": "20.00",
        "currency": "KWD"
    ]
]
```

### 3. Create Apple Pay View

```swift
import UIKit
import ApplePay_iOS

class ViewController: UIViewController {
    
    private let applePayView = ApplePayView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add to view hierarchy
        view.addSubview(applePayView)
        applePayView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set up constraints
        NSLayoutConstraint.activate([
            applePayView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            applePayView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            applePayView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            applePayView.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        // Initialize with config and delegate
        applePayView.initApplePay(configDict: config, delegate: self)
    }
}
```

### 4. Implement Delegate Callbacks

Conform to the `ApplePayDelegate` protocol to handle payment events:

```swift
extension ViewController: ApplePayDelegate {
    
    /// Called when the Apple Pay view is ready
    func onReady() {
        print("Apple Pay view is ready")
    }
    
    /// Called when the user clicks the Apple Pay button
    func onClick() {
        print("Apple Pay button clicked")
    }
    
    /// Called when the user cancels the payment
    func onCanceled() {
        print("Payment was cancelled by user")
    }
    
    /// Called when a payment is successful
    func onSuccess(data: String) {
        print("Payment successful: \(data)")
    }
    
    /// Called when an error occurs
    func onError(data: String) {
        print("Error occurred: \(data)")
    }
    
    /// Called when merchant validation is required
    func onMerchantValidation(data: String) {
        print("Merchant validation required: \(data)")
    }
    
    /// Called when an order is created
    func onOrderCreated(data: String) {
        print("Order created: \(data)")
    }
    
    /// Called when a charge is created
    func onChargeCreated(data: String) {
        print("Charge created: \(data)")
    }
}
```

## Configuration Parameters

### Core Configuration

| Parameter | Description | Required | Type | Example |
|-----------|-------------|----------|------|---------|
| `publicKey` | Your Tap public API key for authentication | ✅ | String | `"pk_test_********"` |
| `scope` | Token scope type ('AppleToken' or 'TapToken') | ✅ | String | `"AppleToken"` |
| `merchant` | Merchant account information with ID | ✅ | Dictionary | `["id": "********"]` |

### Transaction Configuration (REQUIRED)

```swift
"transaction": [
    // REQUIRED: Transaction amount as string
    "amount": "20.00",
    
    // REQUIRED: ISO 4217 currency code (e.g., KWD, USD, AED)
    "currency": "KWD",
    
    // OPTIONAL: Coupon code for discount
    "couponCode": "SAVE10",
    
    // OPTIONAL: Shipping options for the transaction
    "shipping": [
        [
            // REQUIRED: Shipping method label
            "label": "Standard Shipping",
            // REQUIRED: Shipping description
            "detail": "5–7 business days",
            // REQUIRED: Shipping cost
            "amount": "1.00",
            // REQUIRED: Unique identifier
            "identifier": "std"
        ]
    ],
    
    // OPTIONAL: Line items breakdown
    "items": [
        [
            // REQUIRED: Item type ('final' or 'pending')
            "type": "final",
            // REQUIRED: Item label/description
            "label": "Product Order",
            // REQUIRED: Item amount
            "amount": "20.00",
            // REQUIRED: Payment timing ('immediate', 'recurring', 'deferred', 'automaticReload')
            "paymentTiming": "immediate"
        ]
    ]
]
```

### Customer Configuration (REQUIRED)

```swift
"customer": [
    // OPTION 1: Use customer ID (if customer already exists in system)
    // "id": "cust_123",
    
    // OPTION 2: Provide customer details (omit ID if using this)
    // REQUIRED: Customer name information (array of objects for multi-language support)
    "name": [
        [
            // REQUIRED: Language code ('en', 'ar', 'fr')
            "lang": "en",
            // REQUIRED: First name
            "first": "John",
            // REQUIRED: Last name
            "last": "Smith",
            // OPTIONAL: Middle name
            "middle": "David"
        ]
    ],
    
    // REQUIRED: At least email OR phone (or both)
    "contact": [
        // OPTIONAL: Email address (required if phone not provided)
        "email": "john.smith@example.com",
        
        // OPTIONAL: Phone number (required if email not provided)
        "phone": [
            // REQUIRED IF PHONE PROVIDED: Country code with + prefix
            "countryCode": "+1",
            // REQUIRED IF PHONE PROVIDED: Phone number
            "number": "5551234567"
        ]
    ]
]
```

### Interface Configuration (OPTIONAL)

```swift
"interface": [
    // OPTIONAL: Display language ('en' or 'ar', defaults to 'en')
    "locale": "en",
    
    // OPTIONAL: Theme mode ('light', 'dark', or 'dynamic', defaults to 'light')
    "theme": "light",
    
    // OPTIONAL: Button edges style ('curved' or 'flat', defaults to 'curved')
    "edges": "curved",
    
    // OPTIONAL: Button type ('book', 'buy', 'check-out', 'pay', 'plain', 'subscribe')
    "type": "buy"
]
```

### Acceptance Configuration (REQUIRED)

```swift
"acceptance": [
    // REQUIRED: Supported card brands/networks
    // Options: 'amex', 'mada', 'masterCard', 'visa', 'chinaUnionPay', 'discover', 'electron', 'jcb', 'maestro'
    "supportedBrands": ["visa", "masterCard"],
    
    // REQUIRED: Supported card types
    // Options: 'credit', 'debit'
    // "supportedCards": ["debit"],
    "supportedCards": ["credit"],
    
    // OPTIONAL: Supported regions for payments
    // Options: 'LOCAL' (within country), 'REGIONAL' (regional area), 'GLOBAL' (worldwide)
    "supportedRegions": ["LOCAL", "REGIONAL"],
    
    // OPTIONAL: Supported countries (ISO 3166-1 alpha-2 codes)
    // Examples: AE, KW, SA, QA, BH, OM, EG, JO, LB, US, GB, FR, DE, etc.
    // For complete list of all supported country codes, refer to ISO 3166-1 alpha-2 standard
    "supportedCountries": ["AE", "KW", "SA", "QA", "BH", "OM", "EG", "JO", "LB"]
]
```

### Features Configuration (OPTIONAL)

```swift
"features": [
    // OPTIONAL: Allow coupon code entry (defaults to false)
    "supportsCouponCode": true,
    
    // OPTIONAL: Shipping contact fields to collect from user
    // Options: "name" (customer name), "phone" (phone number), "email" (email address)
    // Can be empty array [] to not collect any fields
    // Example with all fields: ["name", "phone", "email"]
    // Example with specific fields: ["phone", "email"]
    "shippingContactFields": ["name", "phone", "email"]
]
```

## Advanced Usage

### Recurring Payments

For subscription or recurring payment scenarios:

```swift
"transaction": [
    "items": [
        [
            "type": "final",
            "label": "Monthly Subscription",
            "amount": "9.99",
            "paymentTiming": "recurring",
            "scheduledPayment": [
                "recurringStartDate": ISO8601DateFormatter().string(from: Date()),
                "recurringIntervalUnit": "month",
                "recurringIntervalCount": 1
            ]
        ]
    ]
]
```

### Deferred Payments

For payments scheduled for a future date:

```swift
"scheduledPayment": [
    "deferredPaymentDate": ISO8601DateFormatter().string(from: Date(timeIntervalSinceNow: 86400))
]
```

### Shipping Configuration

```swift
"transaction": [
    "shipping": [
        [
            "label": "Standard",
            "detail": "5–7 days",
            "amount": "1.00",
            "identifier": "std"
        ],
        [
            "label": "Express",
            "detail": "2–3 days",
            "amount": "5.00",
            "identifier": "exp"
        ]
    ]
]
```

## Callback Responses

### onSuccess Response Example

```json
{
    "id": "tok_4WUP3423199C4Vp18rY9y554",
    "created": 1697656174554,
    "object": "token",
    "type": "CARD",
    "card": {
        "id": "card_U8Wb34231992m7q185g9i558",
        "brand": "VISA",
        "last_four": "4242",
        "exp_month": 2,
        "exp_year": 44
    }
}
```

### onError Response Example

```json
{
    "error": {
        "code": "PAYMENT_FAILED",
        "message": "The payment could not be processed"
    }
}
```

## Error Handling

Always implement error handling in your delegate:

```swift
func onError(data: String) {
    if let jsonData = data.data(using: .utf8) {
        if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            if let error = json["error"] as? [String: Any] {
                let code = error["code"] as? String ?? "Unknown"
                let message = error["message"] as? String ?? "Unknown error"
                print("Error \(code): \(message)")
            }
        }
    }
}
```

## Example Application

A complete example application is included in the `TapApplePayExample` folder demonstrating:

- Basic Apple Pay integration
- Configuration management
- Real-time event logging
- Dynamic settings adjustments
- Success and error handling

Run the example app to see the SDK in action:

```bash
open TapApplePayExample/TapApplePayExample.xcodeproj
```

## Dependencies

- **SwiftyRSA** (>= 1.0.0) - For secure RSA encryption of sensitive data
- **SharedDataModels-iOS** (>= 0.0.1) - Shared data models and utilities

## Security Considerations

✅ **Best Practices:**
- Never expose your secret keys in your app (only use public keys)
- Always validate payment responses on your backend
- Use HTTPS for all communication
- Never log sensitive payment data
- Keep dependencies updated for security patches

## Troubleshooting

### Apple Pay not appearing
- Ensure you're testing on a physical device with Apple Pay configured
- Verify your merchant identifier is correct
- Check that your app signing certificate is properly configured

### Payment failures
- Verify your Tap API keys are correct
- Check that your public key corresponds to your merchant account
- Ensure the customer has Apple Pay set up on their device

### Configuration errors
- Validate all required fields are present in the configuration dictionary
- Check for typos in parameter keys (they are case-sensitive)
- Ensure currency codes are valid ISO 4217 codes

## Support & Documentation

- **Developer Documentation**: [docs.tap.company](https://developers.tap.company)
- **API Reference**: [Tap API Documentation](https://developers.tap.company/docs)
- **Issue Tracker**: [GitHub Issues](https://github.com/Tap-Payments/ApplePay-iOS/issues)

## License

MIT License - See LICENSE file for details

## Contributing

We welcome contributions! Please feel free to submit pull requests with bug fixes, feature additions, or documentation improvements.

## Version History

### 1.0.0
- Initial release
- Apple Pay integration
- Comprehensive callback system
---

**Built with ❤️ by Tap Payments**
