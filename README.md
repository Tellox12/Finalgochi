# Finalgochi

App nativa para iOS hecha con UIKit y navegación basada en Coordinator. No usa Storyboards ni SwiftUI.

## Abrir y ejecutar

1. Abre `Finalgochi.xcodeproj` en Xcode en una Mac.
2. Elige el esquema `Finalgochi` y un simulador de iPhone.
3. Ejecuta con **Run** (`⌘R`).

El proyecto apunta a iOS 15.0 y Swift 5. No requiere paquetes externos. En Signing & Capabilities selecciona tu equipo de desarrollo si Xcode solicita firma para un dispositivo físico; el simulador no requiere cuenta de desarrollador.

## Verificar compilación desde Windows

El workflow `.github/workflows/ios-build.yml` compila el proyecto en un runner macOS de GitHub Actions cada vez que se suben cambios o se abre un pull request. Sube el repositorio a GitHub y revisa la pestaña **Actions**; un check verde significa que el target compila para el simulador. Esto no sustituye ejecutar la app ni probar hápticos/notificaciones en un dispositivo.

Para revisar localmente la lógica Swift que no depende de UIKit, abre una terminal nueva y ejecuta `powershell -ExecutionPolicy Bypass -File .\scripts\check-foundation.ps1` desde la raíz del repo. Esto comprueba tipos y sintaxis de los modelos y del manager; no compila las pantallas iOS.

## Organización

- `App/`: ciclo de vida UIKit y configuración de escena sin Storyboard.
- `Coordinators/`: navegación y contratos entre pantallas.
- `Models/` y `Managers/`: estado, reglas del juego y persistencia con Foundation.
- `ViewControllers/`: pantallas UIKit programáticas.
- `Resources/`: recursos gráficos (se pueden agregar desde Xcode).

La mascota, su nombre personalizado, el Gil, la experiencia, el inventario, el equipo, las materias, las misiones, las expediciones y la progresión se guardan localmente mediante `UserDefaults`. El nombre se puede cambiar desde la ficha del personaje (máximo 16 caracteres). Las expediciones ofrecen tres rutas con distintos requisitos, tiempos y premios; el progreso sigue mientras la app está cerrada y al volver se pueden reclamar Gil, experiencia, consumibles y encuentros para completar el bestiario. El bazar vende equipo y cuatro decoraciones que cambian el hábitat. Las materias se equipan en dos ranuras y permiten lanzar Cura, Piro, Prisa y Regenerar consumiendo PM. La mascota evoluciona visualmente en los niveles 5, 10 y 20; los logros conceden Gil y aparecen en la ficha. Una racha diaria entrega Gil con bonus por días consecutivos. El minijuego incluye reflejos, sprint de chocobo y señales de materia. En Ajustes puedes exportar/importar un respaldo JSON, además de activar sonidos, hápticos y recordatorios. La interfaz admite tamaños de texto dinámicos de iOS.

El chequeo Foundation también incluye `WorldPhase.swift`, `DailyQuest.swift`, `Expedition.swift`, `Progression.swift` y `DailyStreak.swift`, para validar la lógica del juego, las etapas, los logros, las decoraciones, las rachas y el archivo de respaldo sin UIKit.
