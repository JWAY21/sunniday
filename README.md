# SUNniDAY

Real-time UV tracking and vitamin D calculator for iOS.

[📖 Methodology](METHODOLOGY.md) | [🔒 Privacy Policy](PRIVACY.md)

SUNniDAY tells you the current UV index for your location, estimates how much
vitamin D your body is synthesising from the sun in real time, and warns you
before you burn — personalised to your skin type, clothing, and sunscreen.

## Features

- Real-time UV index from your location
- Vitamin D synthesis estimate, minute by minute
- Personal burn-limit countdown
- Skin type, clothing & sunscreen adjustments
- Cloud cover override to fine-tune readings
- Log past sun exposure sessions (with historical UV)
- Vitamin D history chart with a body-store trend line
- Sunrise/sunset and moon phase
- Apple Health integration
- Home screen widget
- No API keys required

## Support

Found a bug or have a feature request? Please
[open an issue](../../issues) — that's the fastest way to reach me.

## Requirements

- iOS 17.0+
- iPhone only
- Xcode 15+

## Setup

1. Clone the repo
2. Run `xcodegen generate` to create the Xcode project
3. Open `Sunday.xcodeproj`
4. Select your development team
5. Build and run

## APIs Used

- Open-Meteo for UV data (free, no key)
- Farmsense for moon phases (free, no key)

## Credits

SUNniDAY is based on the open-source **Sun Day** project by
[Jack Dorsey](https://github.com/jackjackbits/sunday), released into the
public domain. Huge thanks for the original app and its vitamin D methodology.

## License

Released into the public domain under the [Unlicense](LICENSE), the same terms
as the original project.
