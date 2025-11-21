import Foundation

struct STYThemeRegistration: ThemeRegistrable {
    let id = "sty"
    let displayName = "STY Athletic"
    
    func createTheme() -> AppTheme {
        return STYThemeStyle()
    }
}