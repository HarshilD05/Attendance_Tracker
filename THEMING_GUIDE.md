# BunkMate Theming System

This document explains the comprehensive theming system implemented in BunkMate, which provides a consistent, configurable, and maintainable approach to app styling.

## Overview

The theming system is built around three core principles:
1. **Centralized Color Management**: All colors are defined in a single JSON configuration file
2. **Theme Consistency**: Standardized color roles for consistent UI components
3. **Easy Theme Switching**: Built-in support for light/dark mode toggle

## Architecture

### 1. Color Configuration (`lib/config/app_colors.json`)

The JSON file defines color palettes for both light and dark themes:

```json
{
  "light_theme": {
    "primary": "#22C55E",           // Main brand color (green)
    "primary_light": "#4ADE80",     // Lighter variant
    "primary_dark": "#16A34A",      // Darker variant
    "secondary": "#10B981",         // Secondary actions
    "accent": "#059669",            // Accent elements
    "background": "#F8FAFC",        // Main background
    "surface": "#FFFFFF",           // Card/surface background
    "card": "#FFFFFF",              // Card components
    "card_elevated": "#F1F5F9",     // Elevated cards
    "text_primary": "#1E293B",      // Primary text
    "text_secondary": "#64748B",    // Secondary text
    "text_muted": "#94A3B8",        // Muted/disabled text
    "border": "#E2E8F0",            // Borders and dividers
    "divider": "#F1F5F9",           // Divider lines
    "error": "#EF4444",             // Error states
    "warning": "#F59E0B",           // Warning states
    "success": "#10B981",           // Success states
    "info": "#3B82F6"               // Info states
  }
}
```

### 2. Color Manager (`lib/theme/app_colors.dart`)

The `AppColors` class loads colors from the JSON file and provides:
- Static color properties accessible throughout the app
- Theme switching functionality
- Color parsing utilities
- ColorScheme generation for Material Theme

### 3. Theme Manager (`lib/theme/app_theme.dart`)

The `AppTheme` class creates complete Flutter `ThemeData` objects with:
- Consistent styling for all UI components
- Custom decorations for cards and gradients
- Material 3 design system integration

### 4. Theme Controller (`lib/theme/theme_manager.dart`)

The `ThemeManager` class handles:
- Theme state management
- Light/dark mode switching
- Notifications for theme changes

## Color Roles

### Primary Colors
- **Primary**: Main brand color used for primary actions, app bars, and key UI elements
- **Primary Light**: Lighter variant for hover states and highlights
- **Primary Dark**: Darker variant for pressed states and shadows

### Background Colors
- **Background**: Main app background color
- **Surface**: Background for cards, sheets, and elevated surfaces
- **Card**: Standard card background
- **Card Elevated**: Background for elevated/highlighted cards

### Text Colors
- **Text Primary**: Main text color for headings and important content
- **Text Secondary**: Secondary text color for subtitles and descriptions
- **Text Muted**: Muted text color for disabled or less important content

### System Colors
- **Error**: Error states, validation messages
- **Warning**: Warning states, caution messages
- **Success**: Success states, confirmation messages
- **Info**: Informational messages and highlights

## Usage Examples

### Using Colors in Widgets

```dart
import '../theme/app_colors.dart';

// Direct color usage
Container(
  color: AppColors.primary,
  child: Text(
    'Hello',
    style: TextStyle(color: AppColors.textPrimary),
  ),
)

// Using theme decorations
Container(
  decoration: AppTheme.getCardDecoration(),
  child: content,
)
```

### Theme Switching

```dart
import '../theme/theme_manager.dart';

final themeManager = ThemeManager();

// Toggle theme
await themeManager.toggleTheme();

// Set specific theme
await themeManager.setThemeMode(true); // Dark mode
await themeManager.setThemeMode(false); // Light mode
```

## Customization

### Changing Colors

1. Edit `lib/config/app_colors.json`
2. Modify the hex color values
3. Hot reload to see changes

### Adding New Colors

1. Add new color entries to the JSON file
2. Add corresponding properties to `AppColors` class
3. Update the `loadColors()` method to parse new colors

### Creating Custom Themes

1. Add new theme objects to the JSON file
2. Extend the theme switching logic in `AppColors`
3. Create theme-specific logic in `ThemeManager`

## Best Practices

1. **Always use AppColors**: Never hardcode colors in widgets
2. **Use semantic naming**: Choose color roles based on purpose, not appearance
3. **Test both themes**: Ensure all colors work in both light and dark modes
4. **Maintain contrast**: Ensure sufficient contrast ratios for accessibility
5. **Use theme decorations**: Leverage pre-built decorations for consistency

## Future Enhancements

- **Custom Color Schemes**: Support for user-defined color themes
- **System Theme Detection**: Automatic theme switching based on device settings
- **Color Accessibility**: Built-in contrast checking and color-blind friendly options
- **Theme Persistence**: Save user theme preferences locally
- **Animation Support**: Smooth transitions between theme switches

This theming system provides a robust foundation for consistent, maintainable, and user-friendly app styling that can easily evolve with your design needs.
