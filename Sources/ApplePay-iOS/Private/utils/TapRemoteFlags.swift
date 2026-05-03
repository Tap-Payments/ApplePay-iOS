import Foundation

// MARK: - Constants

private let rtdbBaseUrl       = "https://apple-pay-ios-default-rtdb.europe-west1.firebasedatabase.app"
private let rtdbFlagPath      = "config/legacy"

private let cacheTTLSeconds: TimeInterval     = 300  // 5 minutes
private let fetchTimeoutSeconds: TimeInterval = 2.0
private let cacheValueKey     = "tap.sdk.remoteFlags.legacy"
private let cacheTimestampKey = "tap.sdk.remoteFlags.legacy.ts"

// MARK: - TapRemoteFlags

/// Fetches the `config/legacy` boolean from Firebase Realtime Database.
/// - Single GET request — no authentication required (RTDB rules: read=true, write=false).
/// - Cache-first: serves the last persisted value immediately if < 5 min old,
///   then refreshes in the background. On first launch (no cache) waits up to
///   2 s; falls back to `false` (web path) on any error or timeout.
internal final class TapRemoteFlags {

    internal static let shared = TapRemoteFlags()
    private init() {}

    // MARK: - Public

    /// Fire-and-forget prefetch — call this as early as possible (e.g. AppDelegate or
    /// when the view is added to the hierarchy) to warm the cache before `initApplePay` runs.
    internal func prefetch() {
        guard cachedValue() == nil else { return }  // already warm
        fetchFlag { _ in }
    }

    /// Calls `completion` with the remote `legacy` flag value.
    /// Always called on the **main thread**.
    internal func fetchLegacyFlag(completion: @escaping (Bool) -> Void) {
        // Cache hit → return immediately, then refresh in background
        if let cached = cachedValue() {
            completion(cached)
            refreshInBackground()
            return
        }

        // No cache → fetch with timeout, fall back to legacy
        fetchWithTimeout(completion: completion)
    }

    // MARK: - Background refresh (fire-and-forget)

    private func refreshInBackground() {
        fetchFlag { _ in /* result is cached; no UI update needed */ }
    }

    // MARK: - Fetch with timeout

    private func fetchWithTimeout(completion: @escaping (Bool) -> Void) {
        var completed = false
        let lock = NSLock()

        let finish: (Bool) -> Void = { value in
            lock.lock()
            defer { lock.unlock() }
            guard !completed else { return }
            completed = true
            DispatchQueue.main.async { completion(value) }
        }

        // Timeout fallback → legacy
        DispatchQueue.global().asyncAfter(deadline: .now() + fetchTimeoutSeconds) {
            finish(true)
        }

        fetchFlag { result in
            switch result {
            case .success(let value): finish(value)
            case .failure:           finish(true)
            }
        }
    }

    // MARK: - Fetch Flag

    private func fetchFlag(completion: @escaping (Result<Bool, Error>) -> Void) {
        let urlString = "\(rtdbBaseUrl)/\(rtdbFlagPath).json"
        guard let url = URL(string: urlString) else {
            completion(.failure(RemoteFlagError.invalidURL))
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            if let error {
                completion(.failure(error))
                return
            }
            guard let data else {
                completion(.failure(RemoteFlagError.noData))
                return
            }
            // RTDB returns a bare JSON value: `true` or `false` — requires .allowFragments
            guard let value = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Bool else {
                completion(.failure(RemoteFlagError.parseError))
                return
            }
            self?.persistValue(value)
            completion(.success(value))
        }.resume()
    }

    // MARK: - Cache

    private func cachedValue() -> Bool? {
        let defaults = UserDefaults.standard
        guard
            let timestamp = defaults.object(forKey: cacheTimestampKey) as? Date,
            Date().timeIntervalSince(timestamp) < cacheTTLSeconds,
            let _ = defaults.object(forKey: cacheValueKey)
        else { return nil }
        return defaults.bool(forKey: cacheValueKey)
    }

    private func persistValue(_ value: Bool) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: cacheValueKey)
        defaults.set(Date(), forKey: cacheTimestampKey)
    }
}

// MARK: - Errors

private enum RemoteFlagError: Error {
    case invalidURL
    case noData
    case parseError
}
