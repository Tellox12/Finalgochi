# Finalgochi

App nativa para iOS hecha con UIKit y navegación basada en Coordinator. No usa Storyboards ni SwiftUI.

## Abrir y ejecutar

1. Abre `Finalgochi.xcodeproj` en Xcode en una Mac.
2. Elige el esquema `Finalgochi` y un simulador de iPhone o iPad.
3. Ejecuta con **Run** (`⌘R`).

El proyecto apunta a iOS 15.0 y Swift 5. No requiere paquetes externos. La app admite todas las orientaciones (vertical, vertical invertida y ambas horizontales) tanto en iPhone como en iPad. En Signing & Capabilities selecciona tu equipo de desarrollo si Xcode solicita firma para un dispositivo físico; el simulador no requiere cuenta de desarrollador.

## Pruebas

El esquema incluye el target `FinalgochiTests`. Puedes ejecutarlo desde Xcode con **Test** (`⌘U`) o desde terminal:

```sh
xcodebuild -project Finalgochi.xcodeproj -scheme Finalgochi \
  -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Las pruebas cubren el desgaste y el sueño de la mascota, las subidas de nivel, las misiones diarias, la racha, las expediciones, la importación de respaldos y los límites de inventario y materias.

## Verificar compilación desde Windows

El workflow `.github/workflows/ios-build.yml` compila y ejecuta las pruebas del proyecto en un runner macOS de GitHub Actions cada vez que se suben cambios o se abre un pull request. Sube el repositorio a GitHub y revisa la pestaña **Actions**; un check verde significa que el target compila y que las pruebas pasan en el simulador. Esto no sustituye ejecutar la app ni probar hápticos/notificaciones en un dispositivo.

Para revisar localmente la lógica Swift que no depende de UIKit, abre una terminal nueva y ejecuta `powershell -ExecutionPolicy Bypass -File .\scripts\check-foundation.ps1` desde la raíz del repo. Esto comprueba tipos y sintaxis de los modelos y del manager; no compila las pantallas iOS ni el target de pruebas.

## Organización

- `App/`: ciclo de vida UIKit y configuración de escena sin Storyboard.
- `Coordinators/`: navegación y contratos entre pantallas.
- `Models/` y `Managers/`: estado, reglas del juego y persistencia con Foundation.
- `ViewControllers/`: pantallas UIKit programáticas y el sistema visual compartido (`ScreenKit.swift`).
- `FinalgochiTests/`: pruebas unitarias del modelo y de la persistencia.
- `Resources/`: catálogo de iconos, manifiesto de privacidad y recursos gráficos.

La mascota, su nombre personalizado, el Gil, la experiencia, el inventario, el equipo, las materias, las misiones, las expediciones y la progresión se guardan localmente mediante `UserDefaults`. El guardado incluye una versión de esquema y migraciones tolerantes para conservar partidas anteriores. El nombre se puede cambiar desde la ficha del personaje (máximo 16 caracteres). Las expediciones ofrecen tres rutas con distintos requisitos, tiempos y premios; el progreso sigue mientras la app está cerrada y al volver se pueden reclamar Gil, experiencia, consumibles y encuentros para completar el bestiario. El bazar vende equipo y cuatro decoraciones que cambian el hábitat. Las materias se equipan en dos ranuras y permiten lanzar Cura, Piro, Prisa y Regenerar consumiendo PM. La mascota evoluciona visualmente en los niveles 5, 10 y 20; los logros conceden Gil y aparecen en la ficha. Una racha diaria entrega Gil con bonus por días consecutivos. El minijuego incluye reflejos, sprint de chocobo y señales de materia. En Ajustes puedes exportar/importar un respaldo JSON, además de activar sonidos, hápticos y recordatorios. La importación pide confirmación, valida el archivo y reajusta las fechas para que un respaldo antiguo no envejezca ni mate a la mascota. La interfaz usa exclusivamente SF Symbols (sin emojis), tipografía redondeada, tamaños de texto dinámicos y un diseño adaptable que funciona en todas las orientaciones de iPhone y iPad.

El equilibrio actual usa un desgaste suave en vigilia (hambre `0.14/min`, ánimo `0.09/min`, energía `0.11/min`) y un descanso de ocho horas que recupera energía (`1.6/min`) mientras el hambre baja muy despacio. El tiempo sin abrir la app se limita a doce horas para evitar muertes injustas al volver. Los consumibles solo se gastan si tienen efecto, y los recordatorios de cuidado se programan al salir de la app.

El chequeo Foundation también incluye `WorldPhase.swift`, `DailyQuest.swift`, `Expedition.swift`, `Progression.swift` y `DailyStreak.swift`, para validar la lógica del juego, las etapas, los logros, las decoraciones, las rachas y el archivo de respaldo sin UIKit.
