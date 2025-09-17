# Mac Sleep Scheduler 💤

A modern macOS SwiftUI application that automatically puts your Mac to sleep at a specified date and time directly from the menu bar.

## ✨ Features

- **🎯 MenuBar Integration**: Native macOS menu bar application with no dock icon
- **⏱️ Live Countdown**: Real-time countdown display in menu bar ("2h 15m" → "5:45" → "0:30")
- **🎛️ Quick Actions**: Right-click for instant scheduling (30min, 1h, 2h)
- **🌍 Local Timezone Support**: Automatically uses your system's timezone
- **✅ Smart Validation**: Prevents past date selection with future date validation
- **🛡️ Secure Operation**: Administrator privileges requested only when needed
- **💬 User Friendly**: Clear error messages and confirmation dialogs
- **⚡ Async Operations**: Loading states and progress indicators
- **🔄 Persistent**: Schedule survives app restarts and system sleep/wake
- **🎨 Visual States**: 5 different icon states with color coding

## 📋 System Requirements

- macOS 12.0 or later
- Administrator privileges (requested during scheduling)

## 🚀 How to Use

### **Basic Usage**
1. **Launch the application** - Menu bar icon (🌙) appears
2. **Left-click icon** - Opens scheduling interface
3. **Select date and time** - Use the compact date picker
4. **Click "Schedule"** - Confirm your selection
5. **Enter admin password** - When prompted
6. **Live countdown begins** - Shows remaining time in menu bar

### **Quick Actions**
- **Right-click menu bar icon** for instant scheduling:
  - Sleep in 30 minutes
  - Sleep in 1 hour  
  - Sleep in 2 hours
  - Cancel current schedule
  - Quit application

### **Menu Bar States**
- **🌙 Idle**: Default moon icon - ready to schedule
- **⏰ Active**: Live countdown - "2h 15m" format
- **🟠 Warning**: Orange text when < 10 minutes remain
- **🔴 Critical**: Red text when < 1 minute remains
- **⚠️ Error**: Triangle icon when errors occur

## 🔧 Technical Details

The application uses macOS built-in `pmset` command:
```bash
pmset schedule sleep 'MM/dd/yy HH:mm:ss'
```

### Architecture
- **MenuBar Manager**: NSStatusBar integration and UI
- **Countdown Service**: Smart timer with adaptive intervals
- **Schedule Manager**: Coordinates all components
- **Persistence**: UserDefaults-based state storage
- **System Monitor**: IOKit sleep/wake event handling

### Performance
- **Memory Usage**: < 50MB target for menu bar app
- **CPU Optimization**: Adaptive timer intervals (1h+ = 1min, <1min = 1s)
- **Background Mode**: Reduced processing when inactive

## 🏗️ Development

### Installation
```bash
# Clone the project
git clone [repo-url]

# Open with Xcode
open sleeper.xcodeproj

# Build and Run
⌘ + R
```

### Testing
```bash
# Run unit tests
⌘ + U
```

## 📁 File Structure

```
sleeper/
├── sleeperApp.swift              # Main app entry point (menu bar only)
├── AppDelegate.swift             # App lifecycle and coordination
├── MenuBarManager.swift          # NSStatusBar integration
├── MenuContentView.swift         # SwiftUI popover interface
├── MenuBarScheduleManager.swift  # Schedule coordination
├── CountdownService.swift        # Timer and formatting
├── SleepSchedulerService.swift   # pmset command execution
├── MyApiFunctions.swift          # Date utilities (DateUtilities)
├── SchedulePersistence.swift     # UserDefaults storage
├── SystemEventMonitor.swift      # IOKit sleep/wake events
├── PerformanceMonitor.swift      # Memory usage tracking
└── Assets.xcassets              # App resources

sleeperTests/
├── CountdownServiceTests.swift   # Timer functionality tests
├── DateUtilitiesTests.swift      # Date validation tests
├── MenuBarManagerTests.swift     # Menu bar integration tests
└── SchedulePersistenceTests.swift # Storage tests

.kiro/specs/
├── mac-sleep-scheduler/          # Original window-based spec
└── menubar-sleep-scheduler/      # Current menu bar implementation
    ├── requirements.md           # Feature requirements
    ├── design.md                # Technical design
    └── tasks.md                 # Implementation tasks
```

## 🎯 Use Cases

- **Night Work**: Schedule Mac to sleep at specific morning time
- **Energy Saving**: Automatic sleep during long unused periods
- **Parental Control**: Limit computer usage at specific hours
- **Work Discipline**: Turn off computer outside working hours
- **Presentations**: Prevent sleep during important demos
- **Downloads**: Sleep after large file transfers complete

## 🔄 Updates

### v2.0 (Current - MenuBar)
- ✅ Native menu bar integration
- ✅ Live countdown display
- ✅ Quick action shortcuts
- ✅ State persistence
- ✅ System event handling
- ✅ Performance optimization
- ✅ Comprehensive testing

### v1.0 (Legacy - Window)
- ❌ Window-based interface
- ❌ Hardcoded GMT+3 timezone
- ❌ Basic error handling
- ❌ Automatic app termination

## 🤝 Contributing

1. Fork the project
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project was created by Berkecan Özgür.

## 🆘 Troubleshooting

### Common Issues

**Q: Getting "Administrator privileges" error**
A: Make sure you enter your system password correctly. Your user must have admin privileges.

**Q: Menu bar icon not appearing**
A: Check if the app is running. Look for it in Activity Monitor under "sleeper" or "MacSleepSchedulerApp".

**Q: Can't select past dates**
A: This is normal behavior. Only future dates can be selected for scheduling.

**Q: Scheduling not working**
A: Check active schedules in Terminal: `pmset -g sched`

**Q: App not persisting after restart**
A: The app automatically restores active schedules. Check if the scheduled time has already passed.

### Debug Commands
```bash
# Check current pmset schedules
pmset -g sched

# Cancel all pmset schedules
sudo pmset schedule cancelall

# Check app memory usage
ps aux | grep sleeper
```

---

**💡 Tip**: To manually wake your Mac, press any key or move the mouse. The scheduled sleep will still work as expected.