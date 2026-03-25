# 🕯️ Shadow Ward — Psychological Horror

> *"You wake up in an abandoned psychiatric hospital. Only a dying flashlight stands between you and what lurks in the dark."*

---

## 🎮 Платформы
| Платформа | Управление |
|-----------|-----------|
| 📱 Android | Виртуальный джойстик + тач-камера |
| 🖥️ Windows | WASD + мышь |
| 🐧 Linux | WASD + мышь |

Игра **автоматически определяет устройство** и переключает управление.

---

## 🕹️ Управление (ПК)
| Клавиша | Действие |
|---------|---------|
| WASD / Стрелки | Движение |
| Мышь | Камера |
| E | Взаимодействие |
| F | Фонарик вкл/выкл |
| Shift | Бег |
| Escape | Пауза |

---

## 🗺️ Уровни
1. **Ward A** — Крыло А. Найди ключ от подвала
2. **Ward B** — Крыло Б. Разберись с прошлым
3. **Basement** — Подвал. Финальная правда

---

## ⚙️ Открыть в Godot 4

1. Скачай [Godot 4.2](https://godotengine.org/download)
2. Открой `project.godot`
3. Нажми **Import → Edit**
4. Запусти через F5

### Сборка APK вручную
```bash
# Установи Android SDK и шаблоны экспорта в Godot
# Editor → Export → Android → Export Project
```

---

## 🏗️ GitHub Actions (автосборка)

Пуш в `main` → автоматически собирает:
- `ShadowWard.apk` (Android)  
- `ShadowWard.exe` (Windows)
- `ShadowWard.x86_64` (Linux)

И создаёт GitHub Release с тегом `v1.0.X`

---

## 📁 Структура проекта
```
ShadowWard/
├── scenes/
│   ├── levels/       # Ward_A, Ward_B, Basement
│   ├── ui/           # MainMenu, HUD, GameOver
│   └── entities/     # Player, Ghost prefabs
├── scripts/
│   ├── player/       # Player.gd
│   ├── enemies/      # Ghost.gd
│   ├── ui/           # HUD.gd, MainMenu.gd
│   └── systems/      # GameManager.gd, InteractableObject.gd
├── assets/
│   ├── models/       # 3D модели (импортируй из Sketchfab/Kenney)
│   ├── shaders/      # Godot shaders
│   └── sounds/       # Ambient, jump scares, footsteps
└── .github/workflows/build.yml
```

## 🎨 Рекомендуемые 3D ресурсы (бесплатные)
- **Sketchfab** → фильтр "Free" → Hospital/Asylum
- **Kenney.nl** → kenney.nl/assets (CC0)
- **Godot Asset Library** → встроенный в редактор
- **Quaternius** → quaternius.com (CC0 паки)
- **itch.io** → itch.io/game-assets/free/tag-horror

---

## 🔧 Настройка после открытия в Godot

1. **Скачай 3D модели** (ссылки выше) и импортируй в `assets/models/`
2. **Создай сцены** по шаблонам в `scenes/`
3. **Добавь звуки** в `assets/sounds/`
4. **Настрой NavMesh** для призраков
5. **Запусти** и тестируй!
