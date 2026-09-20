# ShortMix

複数の動画を選ぶだけで、60秒の縦型ショート動画を自動生成するクロスプラットフォームアプリ（Web/PWA・iOS・Android、Flutter製）。

## 開発環境

- Flutter 3.47.5 (stable) / Dart 3.13.4 で開発・確認済み。
- `flutter create` で Web/iOS/Android の3ターゲットを生成済み。
- このリポジトリを開くマシンに iOS 開発を行うなら Xcode + CocoaPods、Android 実機ビルドを行うなら Android SDK が別途必要（このセッションのコンテナには両方とも未導入・ネットワークポリシー上導入不可のため、iOS/Androidの実機ビルド確認は未実施）。

## 実行方法（Web/PWA）

```bash
flutter pub get
flutter run -d chrome
```

本番ビルド:

```bash
flutter build web --release --no-web-resources-cdn
```

`--no-web-resources-cdn` を付けることで CanvasKit を `www.gstatic.com` から取得せず `build/web/canvaskit/` に同梱されたものを使う。外部CDNに依存しないため、CSP制限下やオフライン起動時にも安定して動作する（仕様書 35章「オフライン」対応の一部）。

注意: 日本語などCanvasKitに同梱されていないグリフは、初回表示時に `fonts.gstatic.com` からフォールバックフォントを取得する（Flutter Web標準の挙動）。通常のインターネット接続があれば問題なく動作するが、完全オフライン環境やそのCDNをブロックするネットワークでは日本語グリフが表示されない場合がある。

## ディレクトリ構成

```text
lib/
├── screens/        # home / clip_selection / editor / preview / export
├── widgets/        # video_thumbnail, video_list, transition_selector, processing_progress
├── models/         # VideoClip, Transition, ShortMixProject
├── algorithms/      # duration_adjuster, clip_selector, crop_calculator（プラットフォーム非依存の純Dart）
└── services/
    ├── media_picker/       # file_picker ベースの動画選択（Web/iOS/Android共通）
    └── video_processing/   # VideoProcessingService 抽象 + web/ios/android実装
```

`services/video_processing/platform_video_processing_service.dart` が conditional export により
Web では `web/web_video_processing_service.dart`、iOS/Androidでは実行時に `Platform.isIOS`/`isAndroid`
で振り分ける `native_video_processing_service.dart` を選択する。共通コード（screens/widgets/algorithms）は
ffmpeg.wasm や AVFoundation などプラットフォーム固有APIを一切importしない（仕様書41章）。

## 現在のステータス

- **Phase 1（プロジェクト作成）**: 完了。Web/iOS/Androidの3ターゲットでプロジェクト生成済み。
  `flutter build web` は動作確認済み。iOS/Androidは実機・SDKがない環境のため、プロジェクト構造の
  生成とDartコードのコンパイル可能性（`flutter analyze`）までを確認。
- **Phase 2（PWA UI基盤）**: 進行中。Home → 動画選択（複数選択・並べ替え・削除）→
  自動編集（トランジション設定・60秒調整アルゴリズムの計算結果表示）→ プレビュー画面（構成の確認）
  までの画面遷移が実装・動作確認済み。
- **Phase 3（Web動画処理 / ffmpeg.wasm）**: 未着手。`WebVideoProcessingService` はインターフェースのみで
  `UnimplementedError` を投げる。現時点の最新版は `@ffmpeg/ffmpeg@0.12.15` / `@ffmpeg/core@0.12.10`（2026-09時点で確認）。
- **Phase 7/8（iOS/Android動画処理）**: 未着手。`ffmpeg_kit_flutter` は開発元により2025年に開発終了
  （最終リリース2023-09）しているため採用しない。Phase開始時に当時メンテナンスされているライブラリを
  再調査する（仕様書50章）。

## 60秒自動調整アルゴリズム（実装済み・純Dart）

`lib/algorithms/duration_adjuster.dart` が比例配分方式（仕様書18章）を実装。素材合計が60秒未満の場合は
無理に引き伸ばさずそのまま出力する（19章）。`clip_selector.dart` が各動画の中央付近を使用区間として
選択する（20章）。どちらも動画エンジンに依存しない純粋なDartロジックのため、Web/iOS/Androidで完全に
共通利用でき、`flutter test` で検証できる。
