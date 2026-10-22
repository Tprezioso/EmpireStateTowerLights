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
        let html = try fixture("current-2026-10-21")
        let lights = try TowerParser.parseCurrent(html: html, baseURL: baseURL, today: CalendarDay(year: 2026, month: 10, day: 21))

        XCTAssertEqual(lights.today.day, CalendarDay(year: 2026, month: 10, day: 21))
        XCTAssertEqual(lights.today.title, "Signature White")
        XCTAssertEqual(
            lights.today.subtitle,
            "A crisp white illumination that highlights the tower’s iconic silhouette with timeless elegance"
        )
        XCTAssertEqual(lights.today.colors, [.white])

        XCTAssertEqual(lights.yesterday?.day, CalendarDay(year: 2026, month: 10, day: 20))
        XCTAssertEqual(lights.yesterday?.title, "Blue and Orange")
        XCTAssertEqual(lights.yesterday?.subtitle, "In Celebration of the New York Knicks’ Home Opener")
        XCTAssertEqual(
            lights.yesterday?.imageURL?.absoluteString,
            "https://empirestatebuilding2prod.prod.acquia-sites.com/sites/default/files/tlbg-da046ed81c2d0227-1792526501.jpg"
        )
        XCTAssertEqual(lights.tomorrow?.day, CalendarDay(year: 2026, month: 10, day: 22))
        XCTAssertEqual(lights.tomorrow?.title, "Light Blue, Magenta, and Navy")
        XCTAssertNotNil(lights.tomorrow?.imageURL)

        let knicks = try TowerParser.parseCurrent(html: html, baseURL: baseURL, today: CalendarDay(year: 2026, month: 10, day: 20))
        XCTAssertEqual(knicks.today.colors, [.blue, .orange])

        XCTAssertThrowsError(
            try TowerParser.parseCurrent(html: html, baseURL: baseURL, today: CalendarDay(year: 2027, month: 6, day: 1)),
            "A day outside the embedded schedule is a parsing failure"
        )
    }

    func testJSONContainerIgnoresBracketsInStrings() {
        let text = #"{"x":1,"days":[{"title":"A [b] {c}","d":"q\"]"},{"e":[1]}],"hero":{"t":"}"},"after":[2]}"#
        XCTAssertEqual(TowerParser.jsonContainer(named: "days", in: text), #"[{"title":"A [b] {c}","d":"q\"]"},{"e":[1]}]"#)
        XCTAssertEqual(TowerParser.jsonContainer(named: "hero", in: text), #"{"t":"}"}"#)
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
        XCTAssertThrowsError(try TowerParser.parseCurrent(html: "<html></html>", baseURL: baseURL, today: CalendarDay(Date())))
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
