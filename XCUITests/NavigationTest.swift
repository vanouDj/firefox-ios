/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
let url_1 = "www.mozilla.org"
let url_1Label = "Internet for people, not profit — Mozilla"
let url_1Value = "mozilla.org"

let url_2 = "www.yahoo.com"
let url_2Label = "Yahoo"
let url_2Value = "yahoo"

let urlAddOns = "addons.mozilla.org"

class NavigationTest: BaseTestCase {
    var navigator: Navigator!
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        navigator = createScreenGraph(app).navigator(self)
    }

    override func tearDown() {
        super.tearDown()
    }

    func testNavigation() {
        navigator.goto(URLBarOpen)
        let urlPlaceholder = "Search or enter address"
        XCTAssert(app.textFields["url"].exists)
        let defaultValuePlaceholder = app.textFields["url"].placeholderValue!

        // Check the url placeholder text and that the back and forward buttons are disabled
        XCTAssert(urlPlaceholder == defaultValuePlaceholder)
        XCTAssertFalse(app.buttons["TabToolbar.backButton"].isEnabled)
        XCTAssertFalse(app.buttons["TabToolbar.forwardButton"].isEnabled)

        // Once an url has been open, the back button is enabled but not the forward button
        navigator.openURL(urlString: url_1)
        waitForValueContains(app.textFields["url"], value: url_1Value)
        XCTAssertTrue(app.buttons["TabToolbar.backButton"].isEnabled)
        XCTAssertFalse(app.buttons["TabToolbar.forwardButton"].isEnabled)

        // Once a second url is open, back button is enabled but not the forward one till we go back to url_1
        navigator.openURL(urlString: url_2)
        waitForValueContains(app.textFields["url"], value: url_2Value)
        XCTAssertTrue(app.buttons["TabToolbar.backButton"].isEnabled)
        XCTAssertFalse(app.buttons["TabToolbar.forwardButton"].isEnabled)

        // Go back to previous visited web site
        app.buttons["TabToolbar.backButton"].tap()
        waitForValueContains(app.textFields["url"], value: url_1Value)

        // Go forward to next visited web site
        app.buttons["TabToolbar.forwardButton"].tap()
        waitForValueContains(app.textFields["url"], value: url_2Value)
    }

    func testTapSignInShowsFxAFromTour() {
        navigator.goto(SettingsScreen)
        // Open FxAccount from tour option in settings menu
        let appsettingstableviewcontrollerTableviewTable = app.tables["AppSettingsTableViewController.tableView"]
        appsettingstableviewcontrollerTableviewTable.staticTexts["Firefox needs to reopen for this change to take effect."].swipeUp()
        let startTour = app.tables["AppSettingsTableViewController.tableView"].cells["Show Tour"]
        startTour.tap()

        // Swipe to check that all the screen are shown
        let organizeStaticText = app.staticTexts["Organize"]
        waitforExistence(organizeStaticText)
        organizeStaticText.swipeLeft()

        let customizeStaticText = app.staticTexts["Customize"]
        waitforExistence(customizeStaticText)
        customizeStaticText.swipeLeft()

        let shareStaticText = app.staticTexts["Share"]
        waitforExistence(shareStaticText)
        shareStaticText.swipeLeft()

        let chooseStaticText = app.staticTexts["Choose"]
        waitforExistence(chooseStaticText)
        chooseStaticText.swipeLeft()

        let sycnStaticText = app.staticTexts["Sync your Devices."]
        waitforExistence(sycnStaticText)

        // Finally Sign in to Firefox screen should be shown correctly
        app.buttons["Sign in to Firefox"].tap()
        checkFirefoxSyncScreenShown()

        // Go back to NewTabScreen
        app.navigationBars["Client.FxAContentView"].buttons["Cancel"].tap()
        navigator.nowAt(NewTabScreen)
    }

    func testTapSigninShowsFxAFromSettings() {
        navigator.goto(SettingsScreen)
        // Open FxAccount from settings menu and check the Sign in to Firefox scren
        let signInToFirefoxStaticText = app.tables["AppSettingsTableViewController.tableView"].staticTexts["Sign In to Firefox"]
        signInToFirefoxStaticText.tap()
        checkFirefoxSyncScreenShown()

        // After that it is possible to go back to Settings
        let settingsButton = app.navigationBars["Client.FxAContentView"].buttons["Settings"]
        settingsButton.tap()
    }

    func testTapSignInShowsFxAFromRemoteTabPanel() {
        navigator.goto(NewTabScreen)
        // Open FxAccount from remote tab panel and check the Sign in to Firefox scren
        app.buttons["HomePanels.History"].tap()
        XCTAssertTrue(app.tables["History List"].staticTexts["Synced Devices"].isHittable)
        app.tables["History List"].staticTexts["Synced Devices"].tap()
        app.tables.buttons["Sign in"].tap()
        checkFirefoxSyncScreenShown()
        app.navigationBars["Client.FxAContentView"].buttons["Cancel"].tap()
    }

    private func checkFirefoxSyncScreenShown() {
        waitforExistence(app.webViews.staticTexts["Sign in"])
        XCTAssertTrue(app.webViews.textFields["Email"].exists)
        XCTAssertTrue(app.webViews.secureTextFields["Password"].exists)
        XCTAssertTrue(app.webViews.buttons["Sign in"].exists)
    }

    func testScrollsToTopWithMultipleTabs() {
        navigator.goto(TabTray)
        navigator.openURL(urlString: url_1)
        waitForValueContains(app.textFields["url"], value: url_1Value)

        // Element at the TOP
        let topElement = app.webViews.buttons["MENU"]

        // Element at the BOTTOM
        let bottomElement = app.webViews.links.staticTexts["Contact Us"]

        // Scroll to bottom
        bottomElement.tap()
        app.buttons["TabToolbar.backButton"].tap()

        // Scroll to top
        topElement.tap()
    }

    private func checkMobileView() {
        let mobileViewElement = app.webViews.links.staticTexts["View desktop site"]
        waitforExistence(mobileViewElement)
        XCTAssertTrue (mobileViewElement.exists, "Mobile view is not available")
    }

    private func checkDesktopView() {
        let desktopViewElement = app.webViews.links.staticTexts["View Mobile Site"]
        waitforExistence(desktopViewElement)
        XCTAssertTrue (desktopViewElement.exists, "Desktop view is not available")
    }

    private func clearData() {
        navigator.goto(ClearPrivateDataSettings)
        app.tables.staticTexts["Clear Private Data"].tap()
        app.alerts.buttons["OK"].tap()
        navigator.goto(NewTabScreen)
    }

    func testToggleBetweenMobileAndDesktopSiteFromSite() {
        clearData()
        let goToDesktopFromMobile = app.webViews.links.staticTexts["View desktop site"]
        // Open URL by default in mobile view
        navigator.openURL(urlString: urlAddOns)
        waitForValueContains(app.textFields["url"], value: urlAddOns)
        waitforExistence(goToDesktopFromMobile)

        // From the website go to Desktop view
        goToDesktopFromMobile.tap()
        checkDesktopView()

        // From the website go back to Mobile view
        app.webViews.links.staticTexts["View Mobile Site"].tap()
        checkMobileView()
    }

    func testToggleBetweenMobileAndDesktopSiteFromMenu() {
        clearData()
        navigator.openURL(urlString: urlAddOns)

        // Mobile view by default, desktop view should be available
        navigator.changeBrowserView(view: "RequestDesktopMenuItem")
        checkDesktopView()

        // From desktop view it is posible to change to mobile view again
        navigator.nowAt(BrowserTab)
        navigator.changeBrowserView(view: "RequestMobileMenuItem")

        checkMobileView()
    }

    func testNavigationPreservesDesktopSiteOnSameHost() {
        clearData()
        navigator.openURL(urlString: urlAddOns)

        // Mobile view by default, desktop view should be available
        navigator.changeBrowserView(view: "RequestDesktopMenuItem")
        checkDesktopView()

        // Select any link to navigate to another site and check if the view is kept in desktop view
        waitforExistence(app.webViews.links["Featured ›"])
        app.webViews.links["Featured ›"].tap()
        checkDesktopView()
    }

    func testReloadPreservesMobileOrDesktopSite() {
        clearData()
        navigator.openURL(urlString: urlAddOns)

        // Mobile view by default, desktop view should be available
        navigator.changeBrowserView(view: "RequestDesktopMenuItem")

        // After reloading a website the desktop view should be kept
        app.buttons["Reload"].tap()
        waitForValueContains(app.textFields["url"], value: urlAddOns)
        checkDesktopView()

        // From desktop view it is posible to change to mobile view again
        navigator.nowAt(BrowserTab)
        navigator.changeBrowserView(view: "RequestMobileMenuItem")
        waitForValueContains(app.textFields["url"], value: urlAddOns)

        // After reloading a website the mobile view should be kept
        app.buttons["Reload"].tap()
        checkMobileView()
    }
    /* Test disabled till bug: https://bugzilla.mozilla.org/show_bug.cgi?id=1346157 is fixed
     func testBackForwardNavigationRestoresMobileOrDesktopSite() {
        clearData()
        let desktopViewElement = app.webViews.links.staticTexts["Mobile"]
        let collectionViewsQuery = app.collectionViews

        // Open first url and keep it in mobile view
        navigator.openURL(urlString: urlAddOns)
        waitForValueContains(app.textFields["url"], value: urlAddOns)
        checkMobileView()
        // Open a second url and change it to desktop view
        navigator.openURL(urlString: "www.linkedin.com")
        navigator.goto(BrowserTabMenu)
        waitforExistence(collectionViewsQuery.cells["RequestDesktopMenuItem"])
        collectionViewsQuery.cells["RequestDesktopMenuItem"].tap()
        waitforExistence(desktopViewElement)
        XCTAssertTrue (desktopViewElement.exists, "Desktop view is not available")

        // Go back to first url and check that the view is still mobile view
        app.buttons["TabToolbar.backButton"].tap()
        waitForValueContains(app.textFields["url"], value: urlAddOns)
        checkMobileView()

        // Go forward to second url and check that the view is still desktop view
        app.buttons["TabToolbar.forwardButton"].tap()
        waitForValueContains(app.textFields["url"], value: "www.linkedin.com")
        waitforExistence(desktopViewElement)
        XCTAssertTrue (desktopViewElement.exists, "Desktop view is not available after coming from another site in mobile view")
     }*/
}
