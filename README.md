# Finalgochi

App nativa para iOS hecha con UIKit y navegación basada en Coordinator. No usa Storyboards ni SwiftUI.

## Abrir y ejecutar

1. Abre `Finalgochi.xcodeproj` en Xcode en una Mac.
2. Elige el esquema `Finalgochi` y un simulador de iPhone.
3. Ejecuta con **Run** (`⌘R`).

El proyecto apunta a iOS 15.0 y Swift 5. No requiere paquetes externos. En Signing & Capabilities selecciona tu equipo de desarrollo si Xcode solicita firma para un dispositivo físico; el simulador no requiere cuenta de desarrollador.

## Verificar compilación desde Windows

El workflow `.github/workflows/ios-build.yml` compila el proyecto en un runner macOS de GitHub Actions cada vez que se suben cambios o se abre un pull request. Sube el repositorio a GitHub y revisa la pestaña **Actions**; un check verde significa que el target compila para el simulador. Esto no sustituye ejecutar la app ni probar hápticos/notificaciones en un dispositivo.

## Organización

- `App/`: ciclo de vida UIKit y configuración de escena sin Storyboard.
- `Coordinators/`: navegación y contratos entre pantallas.
- `Models/` y `Managers/`: estado, reglas del juego y persistencia con Foundation.
- `ViewControllers/`: pantallas UIKit programáticas.
- `Resources/`: recursos gráficos (se pueden agregar desde Xcode).

La mascota, el Gil, la experiencia y los accesorios se guardan localmente mediante `UserDefaults`. Las estadísticas se degradan con el tiempo y se actualizan al volver a abrir la app.
