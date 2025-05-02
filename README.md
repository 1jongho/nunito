# nunito

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## iOS 개발 시 주의사항

이 프로젝트는 iOS 14.0 이상을 대상으로 합니다. 다음 설정을 확인하세요:

1. Podfile의 iOS 버전: `platform :ios, '14.0'`
2. AppFrameworkInfo.plist의 MinimumOSVersion: `14.0`
3. Xcode에서 Runner 프로젝트 설정의 iOS 배포 타겟: `14.0`

## 폴더 역할

- Services: 컨트롤러 + 서비스 | (Firebase 기능 접근 및 비즈니스 로직)
- Models: 데이터 구조 정의
