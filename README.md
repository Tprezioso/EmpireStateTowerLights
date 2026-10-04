# EmpireStateTowerLights
A fun little app to show what the lights mean on the Empire State Building at night.

## Features
- **Tonight**: a glowing illustration of the tower lit in tonight's colors, with last night and tomorrow a swipe away.
- **Calendar**: browse special lightings month by month, with details and a shareable card for each one.
- **Widgets**: Home Screen (small and medium) and Lock Screen (inline, circular, and rectangular), refreshed just after midnight New York time.
- **Siri and Shortcuts**: ask "What color is the Empire State Building tonight in Empire Tower Lights", or open the calendar.
- **Apple Watch**: turn the Digital Crown to page through last night, tonight, and tomorrow, browse the calendar, and add watch face complications.
- **App icons**: seven free icons, from Midnight to Pride, in the About sheet (tap the sparkles button).
- **Tip jar**: optional consumable tips. For local testing, the run scheme uses `EmpireStateTowerLights/Tips.storekit`.

## Project structure
Most code lives in the local `EmpireModule` Swift package:

| Module | Purpose |
| --- | --- |
| `Models` | `TowerLighting`, `CalendarDay`, `YearMonth`, `LightColor` |
| `TowerClient` | Fetches and parses esbnyc.com (`TowerParser`) |
| `DesignSystem` | Midnight Glow theme, night sky, glowing tower, cards, share card |
| `AboutFeature` | About sheet: icon picker, StoreKit 2 tip jar, credits |
| `TowerWidgetKit` | Widget timeline and Lock Screen/complication views shared by iPhone and Watch |
| `WatchFeature` | Apple Watch app UI |
| `CurrentTowerFeature` / `MonthlyTowerFeature` / `AppFeature` | Composable Architecture features and views |

Run the tests with:

```sh
cd EmpireStateTowerLights/EmpireModule
xcodebuild test -scheme EmpireModule-Package -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
```

The parser tests run against saved copies of the ESB pages in `Tests/TowerClientTests/Fixtures`. If the website changes, save fresh copies there and update the tests.

## Credits
Tower lighting schedule and photos courtesy of the [Empire State Building](https://www.esbnyc.com/about/tower-lights). Tower Lights is an independent app and is not affiliated with or endorsed by the Empire State Building or Empire State Realty Trust.

## Contact
If you have any issues or questions about the app please reach out on:\
Twitter: https://www.twitter.com/tommyprezioso \
Email: tommyprezioso@gmail.com
