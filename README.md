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

La mascota, el Gil, la experiencia, el inventario, el equipo, las materias y el progreso de misiones diarias se guardan localmente mediante `UserDefaults`. El bazar vende piezas para cabeza, cuerpo y amuleto; cada una aporta un efecto pasivo visible en el personaje pixel art. Las materias se compran, se equipan en dos ranuras y permiten lanzar Cura, Piro, Prisa y Regenerar consumiendo PM, que se recuperan con el tiempo. Los consumibles muestran efectos y cantidades; dormir recupera energía y la mascota despierta al descansar por completo. El hábitat cambia entre amanecer, día, atardecer y noche; la ficha presenta equipo, materias, nivel, experiencia y barras de estado. Las misiones diarias entregan Gil una sola vez por objetivo. El minijuego tiene ventana de reacción y estado de tiempo agotado. Los ajustes permiten activar/desactivar sonidos de interfaz, hápticos y recordatorios.

El chequeo Foundation también incluye `WorldPhase.swift` y `DailyQuest.swift`, para validar el estado emocional, el ciclo del hábitat y las misiones sin UIKit.
