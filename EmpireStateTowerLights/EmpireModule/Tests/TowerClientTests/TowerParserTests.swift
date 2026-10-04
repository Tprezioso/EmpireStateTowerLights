import Foundation
import Models
@testable import TowerClient
import XCTest

final class TowerParserTests: XCTestCase {
    let baseURL = URL(string: "https://www.esbnyc.com")!

    func fixture(_ name: String) throws -> String {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "html", subdirectory: "Fixtures"))
        return try String(contentsOf: url, encoding: .utf8)
    }

    func testParseCurrent() throws {
        let lights = try TowerParser.parseCurrent(
            html: fixture("current-2026-10-03"),
            baseURL: baseURL,
            fallbackToday: CalendarDay(year: 2000, month: 1, day: 1)
        )

        XCTAssertEqual(lights.today.day, CalendarDay(year: 2026, month: 10, day: 3))
        XCTAssertEqual(lights.today.title, "Blue and Orange")
        XCTAssertEqual(lights.today.subtitle, "In Honor of the New York Islanders’ Home Opener")
        XCTAssertEqual(
            lights.today.imageURL?.absoluteString,
            "https://www.esbnyc.com/sites/default/files/a1rVV00000yKThfYAG-1786642942.jpg"
        )
        XCTAssertEqual(lights.today.colors, [.blue, .orange])

        XCTAssertEqual(lights.yesterday?.title, "Signature White")
        XCTAssertEqual(lights.yesterday?.day, CalendarDay(year: 2026, month: 10, day: 2))
        XCTAssertEqual(lights.tomorrow?.title, "Signature White")
        XCTAssertEqual(lights.tomorrow?.day, CalendarDay(year: 2026, month: 10, day: 4))
        XCTAssertNotNil(lights.tomorrow?.imageURL)
    }

    func testParseMonth() throws {
        let lightings = try TowerParser.parseMonth(html: fixture("calendar-202610"), baseURL: baseURL)

        XCTAssertEqual(lightings.map(\.title), [
            "Pink with a Ribbon Rotating in the Mast",
            "Red, White, and Blue",
            "Blue and Orange",
            "Orange and Green",
        ])
        XCTAssertEqual(lightings.map(\.day.day), [1, 1, 3, 31])
        XCTAssertEqual(Set(lightings.map(\.id)).count, 4, "IDs must be unique even when two lightings share a day")
        XCTAssertEqual(lightings[2].subtitle, "In Honor of the New York Islanders’ Home Opener")
        XCTAssertTrue(lightings.allSatisfy { $0.imageURL?.absoluteString.hasPrefix("https://www.esbnyc.com/sites/") == true })
    }

    func testUnexpectedPagesThrow() {
        XCTAssertThrowsError(try TowerParser.parseCurrent(html: "<html></html>", baseURL: baseURL, fallbackToday: CalendarDay(Date())))
        XCTAssertThrowsError(try TowerParser.parseMonth(html: "<html></html>", baseURL: baseURL))
    }

    func testNormalizeTitle() {
        XCTAssertEqual(TowerParser.normalizeTitle("  Blue and Orange COLOR "), "Blue and Orange")
        XCTAssertEqual(TowerParser.normalizeTitle("SIGNATURE WHITE"), "Signature White")
        XCTAssertEqual(TowerParser.normalizeTitle("Red, White, and Blue"), "Red, White, and Blue")
    }

    func testColorParsing() {
        XCTAssertEqual(LightColor.parse("Red, White, and Blue"), [.red, .white, .blue])
        XCTAssertEqual(LightColor.parse("Pink with a Ribbon Rotating in the Mast"), [.pink])
        XCTAssertEqual(LightColor.parse("Signature White"), [.white])
        XCTAssertEqual(LightColor.parse("Something Unexpected"), [.white])
        XCTAssertEqual(LightColor.parse("Rainbow").count, 6)
    }

    func testYearMonth() {
        let december = YearMonth(year: 2026, month: 12)
        XCTAssertEqual(december.next, YearMonth(year: 2027, month: 1))
        XCTAssertEqual(december.next.previous, december)
        XCTAssertEqual(YearMonth(year: 2026, month: 1).previous, YearMonth(year: 2025, month: 12))
        XCTAssertEqual(december.pathComponent, "202612")
    }
}
