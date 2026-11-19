import AppIntents
import UIKit

/// Shortcuts action that runs the same sync + backup job as the iOS background refresh task.
/// Runs in the background without opening the app; queued uploads continue in the background URLSession.
@available(iOS 16.0, *)
struct BackupPhotosIntent: AppIntent {
  static let title: LocalizedStringResource = "Back up new photos"
  static let description = IntentDescription(
    "Syncs with your Immich server and queues new photos and videos for upload. Uploads continue in the background after the action finishes."
  )

  @MainActor
  func perform() async throws -> some IntentResult {
    // The foreground app runs its own backup; running the worker too would duplicate uploads
    if UIApplication.shared.applicationState == .active {
      return .result()
    }

    // 20s matches the background refresh task and fits the time iOS gives intents running in the background.
    // nil means a background task is already running the same job, so there is nothing more to do.
    guard let success = await BackgroundWorkerApiImpl.runFromIntent(maxSeconds: 20) else {
      return .result()
    }
    if !success {
      throw BackupIntentError.failed
    }
    return .result()
  }
}

@available(iOS 16.0, *)
private enum BackupIntentError: Error, CustomLocalizedStringResourceConvertible {
  case failed

  var localizedStringResource: LocalizedStringResource {
    "The backup could not be completed. Queued uploads may still continue in the background."
  }
}
