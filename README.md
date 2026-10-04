# EmpireStateTowerLights
A fun little app to show what the lights mean on the Empire State Building at night.

## Features
- **Tonight**: a glowing illustration of the tower lit in tonight's colors, with last night and tomorrow a swipe away.
- **Calendar**: browse special lightings month by month, with details and a shareable card for each one.
- **Widgets**: Home Screen (small and medium) and Lock Screen (inline, circular, and rectangular), refreshed just after midnight New York time.
- **Siri and Shortcuts**: ask "What color is the Empire State Building tonight in Empire Tower Lights", or open the calendar.

## Project structure
Most code lives in the local `EmpireModule` Swift package:

| Module | Purpose |
| --- | --- |
| `Models` | `TowerLighting`, `CalendarDay`, `YearMonth`, `LightColor` |
| `TowerClient` | Fetches and parses esbnyc.com (`TowerParser`) |
| `DesignSystem` | Midnight Glow theme, night sky, glowing tower, cards, share card |
| `CurrentTowerFeature` / `MonthlyTowerFeature` / `AppFeature` | Composable Architecture features and views |

Run the tests with:

```sh
cd EmpireStateTowerLights/EmpireModule
xcodebuild test -scheme EmpireModule-Package -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
```

The parser tests run against saved copies of the ESB pages in `Tests/TowerClientTests/Fixtures`. If the website changes, save fresh copies there and update the tests.

## Contact
If you have any issues or questions about the app please reach out on:\
Twitter: https://www.twitter.com/tommyprezioso \
Email: tommyprezioso@gmail.com
