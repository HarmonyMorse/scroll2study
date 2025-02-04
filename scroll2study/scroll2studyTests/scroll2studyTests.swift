//
//  scroll2studyTests.swift
//  scroll2studyTests
//
//  Created by Harm on 2/3/25.
//

import Testing

@testable import scroll2study

@MainActor
struct ContentViewTests {
    @Test func testInitialState() async throws {
        let state = ViewState()
        #expect(state.isLoggedIn == false)
        #expect(state.counter == 0)
        #expect(state.errorMessage.isEmpty)
    }

    @Test func testSignInAnonymously_Success() async throws {
        let state = ViewState()
        await state.signInAnonymously()

        // Since Firebase auth is async, we need to wait a bit
        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

        #expect(state.isLoggedIn == true)
        #expect(state.errorMessage.isEmpty)
    }

    @Test func testIncrementCounter_RequiresAuth() async throws {
        let state = ViewState()
        await state.incrementCounter()

        #expect(state.errorMessage == "Not logged in")
        #expect(state.counter == 0)
    }

    @Test func testSignOut() async throws {
        let state = ViewState()

        // First sign in
        await state.signInAnonymously()
        try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second

        // Then sign out
        await state.signOut()

        #expect(state.isLoggedIn == false)
        #expect(state.counter == 0)
        #expect(state.errorMessage.isEmpty)
    }
}
