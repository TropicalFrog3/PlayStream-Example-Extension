package com.frog.playstream.extensions

import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

/**
 * Unit tests for JsExtensionEngine.
 * 
 * These tests verify that the JavaScript bridge works correctly by:
 * - Loading simple JavaScript code
 * - Executing JavaScript functions
 * - Handling return values
 * - Properly managing the QuickJS context lifecycle
 */
class JsExtensionEngineTest {
    
    private lateinit var engine: JsExtensionEngine
    
    @Before
    fun setUp() {
        engine = JsExtensionEngine()
    }
    
    @After
    fun tearDown() {
        // Always clean up the engine after each test
        engine.close()
    }
    
    /**
     * Test: Load a simple "Hello World" JavaScript and verify the bridge works.
     * 
     * This test verifies:
     * 1. The engine can load JavaScript code
     * 2. The engine can execute a simple function
     * 3. The function returns the expected result
     */
    @Test
    fun testHelloWorldJavaScript() {
        // Arrange: Define a simple JavaScript function that returns "Hello World"
        val jsCode = """
            function helloWorld() {
                return "Hello World";
            }
        """.trimIndent()
        
        // Act: Load the script and call the function
        engine.loadScript(jsCode)
        val result = engine.callFunction("helloWorld")
        
        // Assert: Verify the result is "Hello World"
        assertEquals("Hello World", result)
    }
    
    /**
     * Test: Verify the engine is ready after loading a script.
     */
    @Test
    fun testEngineIsReadyAfterLoadingScript() {
        // Arrange
        val jsCode = "function test() { return 'ready'; }"
        
        // Act
        assertFalse("Engine should not be ready before loading script", engine.isReady())
        engine.loadScript(jsCode)
        
        // Assert
        assertTrue("Engine should be ready after loading script", engine.isReady())
    }
    
    /**
     * Test: Verify the engine is not ready after closing.
     */
    @Test
    fun testEngineIsNotReadyAfterClosing() {
        // Arrange
        val jsCode = "function test() { return 'test'; }"
        engine.loadScript(jsCode)
        
        // Act
        engine.close()
        
        // Assert
        assertFalse("Engine should not be ready after closing", engine.isReady())
    }
    
    /**
     * Test: Verify function with parameters works correctly.
     */
    @Test
    fun testFunctionWithParameters() {
        // Arrange
        val jsCode = """
            function greet(name) {
                return "Hello, " + name + "!";
            }
        """.trimIndent()
        
        // Act
        engine.loadScript(jsCode)
        val result = engine.callFunction("greet", "Kiro")
        
        // Assert
        assertEquals("Hello, Kiro!", result)
    }
    
    /**
     * Test: Verify function with multiple parameters.
     */
    @Test
    fun testFunctionWithMultipleParameters() {
        // Arrange
        val jsCode = """
            function add(a, b) {
                return a + b;
            }
        """.trimIndent()
        
        // Act
        engine.loadScript(jsCode)
        val result = engine.callFunction("add", 5, 3)
        
        // Assert
        assertEquals("8", result)
    }
    
    /**
     * Test: Verify JSON return values work correctly.
     */
    @Test
    fun testJsonReturnValue() {
        // Arrange
        val jsCode = """
            function getUser() {
                return JSON.stringify({
                    name: "John Doe",
                    age: 30,
                    active: true
                });
            }
        """.trimIndent()
        
        // Act
        engine.loadScript(jsCode)
        val result = engine.callFunction("getUser")
        
        // Assert
        assertTrue("Result should contain JSON", result.contains("John Doe"))
        assertTrue("Result should contain age", result.contains("30"))
    }
    
    /**
     * Test: Verify calling a function before loading script throws exception.
     */
    @Test(expected = IllegalStateException::class)
    fun testCallFunctionBeforeLoadingScript() {
        // Act & Assert: Should throw IllegalStateException
        engine.callFunction("nonExistent")
    }
    
    /**
     * Test: Verify loading a script twice throws exception.
     */
    @Test(expected = IllegalStateException::class)
    fun testLoadScriptTwice() {
        // Arrange
        val jsCode = "function test() { return 'test'; }"
        
        // Act: Load script twice
        engine.loadScript(jsCode)
        engine.loadScript(jsCode) // Should throw
    }
    
    /**
     * Test: Verify error handling when JavaScript function throws an error.
     */
    @Test
    fun testJavaScriptErrorHandling() {
        // Arrange
        val jsCode = """
            function throwError() {
                throw new Error("Test error");
            }
        """.trimIndent()
        
        // Act
        engine.loadScript(jsCode)
        val result = engine.callFunction("throwError")
        
        // Assert: Result should contain error information
        assertTrue("Result should indicate an error", result.contains("error"))
        assertTrue("Result should contain error message", result.contains("Test error"))
    }
    
    /**
     * Test: Verify the native HTTP client bridge works from JavaScript.
     * 
     * This test proves the "sandbox escape" works by:
     * 1. Loading a JS script that uses the injected 'client' object
     * 2. Calling client.get() to make a real HTTP request to google.com
     * 3. Verifying that the response contains expected HTML content
     * 
     * This is a critical test that validates the entire native bridge architecture.
     */
    @Test
    fun testNetworkBridgeWithRealHttpRequest() {
        // Arrange: JavaScript code that uses the native HTTP client
        val jsCode = """
            function testNetworkCall() {
                try {
                    // Call the native HTTP client bridge
                    var response = client.get("https://google.com", "{}");
                    
                    // Return a JSON object with the response info
                    return JSON.stringify({
                        success: true,
                        hasContent: response.length > 0,
                        containsHtml: response.indexOf("<html") >= 0 || response.indexOf("<!doctype") >= 0
                    });
                } catch (e) {
                    return JSON.stringify({
                        success: false,
                        error: e.message || String(e)
                    });
                }
            }
        """.trimIndent()
        
        // Act: Load the script and call the function
        engine.loadScript(jsCode)
        val result = engine.callFunction("testNetworkCall")
        
        // Assert: Verify the network call succeeded
        assertTrue("Result should contain 'success'", result.contains("success"))
        assertTrue("Result should indicate success:true", result.contains("\"success\":true"))
        assertTrue("Result should indicate content was received", result.contains("\"hasContent\":true"))
        assertTrue("Result should indicate HTML was received", result.contains("\"containsHtml\":true"))
        
        // Additional verification: result should be valid JSON
        assertNotNull("Result should be valid JSON", org.json.JSONObject(result))
    }
}
