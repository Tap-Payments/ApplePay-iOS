import UIKit

/// Displays the raw success charge / token JSON returned by the Apple Pay flow.
class TapApplePayOnSuccessViewController: UIViewController {

    var resultString: String = ""

    private let textView = UITextView()
    private let copyButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Payment Success"
        view.backgroundColor = .systemBackground
        setupLayout()
        textView.text = resultString
    }

    private func setupLayout() {
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.backgroundColor = UIColor.secondarySystemBackground
        textView.layer.cornerRadius = 8
        textView.translatesAutoresizingMaskIntoConstraints = false

        copyButton.setTitle("Copy to Clipboard", for: .normal)
        copyButton.addTarget(self, action: #selector(copyTapped), for: .touchUpInside)
        copyButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(textView)
        view.addSubview(copyButton)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            copyButton.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 12),
            copyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            copyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            copyButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    @objc private func copyTapped() {
        UIPasteboard.general.string = resultString
        copyButton.setTitle("Copied!", for: .normal)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.copyButton.setTitle("Copy to Clipboard", for: .normal)
        }
    }
}
