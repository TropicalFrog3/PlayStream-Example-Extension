import com.microsoft.playwright.CLI

fun main() {
    println("Installing Playwright browsers...")
    CLI.main(arrayOf("install", "chromium"))
    println("Installation complete!")
}
