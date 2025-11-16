#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Flutter Windows Desktop Screenshot Tool

This script captures screenshots of your Flutter Windows app window.
It can either attach to a running app or start a new instance.

Usage:
    python take_screenshot.py [--auto-start]

Controls:
    - Press 's' + Enter to take a screenshot
    - Enter a name for the screenshot when prompted
    - Press 'q' + Enter to quit

Requirements:
    python -m pip install -r requirements.txt
    (installs: pillow, pywin32, psutil)
"""

import subprocess
import sys
import time
import threading
from datetime import datetime
from pathlib import Path
from queue import Queue
import re

try:
    from PIL import ImageGrab
    import win32gui
    import win32ui
    import win32con
    import win32process
    import psutil
    from ctypes import windll
except ImportError as e:
    print(f"Error: Missing required package")
    print(f"Please install: python -m pip install -r requirements.txt")
    sys.exit(1)

# Configuration
SCREENSHOTS_DIR = Path("screenshots")
FLUTTER_WINDOW_KEYWORDS = ["epub_reader", "Flutter", "epub reader"]


class WindowCapture:
    """Utility to find and capture Windows application windows"""

    @staticmethod
    def get_window_exe(hwnd):
        """Get the executable path of a window"""
        try:
            _, pid = win32process.GetWindowThreadProcessId(hwnd)
            process = psutil.Process(pid)
            return process.exe().lower()
        except:
            return ""

    @staticmethod
    def find_window_by_keywords(keywords):
        """Find Flutter window - must be epub_reader.exe, not Explorer or other apps"""
        found_windows = []

        # System windows to exclude
        excluded_exes = [
            'explorer.exe',
            'applicationframehost.exe',
            'searchhost.exe',
            'startmenuexperiencehost.exe',
        ]

        def callback(hwnd, _):
            if win32gui.IsWindowVisible(hwnd):
                title = win32gui.GetWindowText(hwnd)
                if title:
                    # Check if it matches our keywords
                    for keyword in keywords:
                        if keyword.lower() in title.lower():
                            # Get the executable to verify it's actually our Flutter app
                            exe_path = WindowCapture.get_window_exe(hwnd)
                            exe_name = exe_path.split('\\')[-1] if exe_path else ""

                            # Only accept if it's epub_reader.exe (Flutter app)
                            # Skip File Explorer and other system apps
                            if exe_name in excluded_exes:
                                continue

                            # Accept if it's epub_reader.exe or unknown but has Flutter in title
                            if 'epub_reader.exe' in exe_path or 'flutter' in title.lower():
                                found_windows.append((hwnd, title, exe_path))
                                break
            return True

        win32gui.EnumWindows(callback, None)
        return found_windows

    @staticmethod
    def capture_window(hwnd):
        """Capture screenshot of specific window"""
        try:
            # Get window dimensions
            left, top, right, bottom = win32gui.GetWindowRect(hwnd)
            width = right - left
            height = bottom - top

            # Try to bring window to foreground (may fail due to Windows restrictions)
            # but that's okay - we can still capture it
            try:
                # Try using ShowWindow first to ensure window is visible
                win32gui.ShowWindow(hwnd, win32con.SW_RESTORE)
                time.sleep(0.1)

                # Try to set foreground - might fail but screenshot will still work
                win32gui.SetForegroundWindow(hwnd)
                time.sleep(0.2)
            except Exception as fg_error:
                # SetForegroundWindow can fail due to Windows restrictions
                # but we can still capture the window, so continue
                pass

            # Capture the window area (works even if window is not in foreground)
            screenshot = ImageGrab.grab(bbox=(left, top, right, bottom))

            return screenshot

        except Exception as e:
            print(f"Error capturing window: {e}")
            return None


class ScreenshotTool:
    def __init__(self, auto_start=False):
        self.screenshots_dir = SCREENSHOTS_DIR
        self.running = True
        self.flutter_process = None
        self.app_ready = False
        self.print_output = True
        self.auto_start = auto_start
        self.target_window = None

        # Create screenshots directory
        self.screenshots_dir.mkdir(exist_ok=True)
        print(f"Screenshots will be saved to: {self.screenshots_dir.absolute()}\n")

    def find_flutter_window(self):
        """Find the Flutter application window"""
        windows = WindowCapture.find_window_by_keywords(FLUTTER_WINDOW_KEYWORDS)

        if not windows:
            return None

        if len(windows) == 1:
            hwnd, title, exe_path = windows[0]
            print(f"Found Flutter window: '{title}'")
            print(f"  Executable: {exe_path}")
            return hwnd

        # Multiple windows found, let user choose
        print("\nMultiple Flutter windows found:")
        for i, (hwnd, title, exe_path) in enumerate(windows, 1):
            print(f"  {i}. {title}")
            print(f"     ({exe_path})")

        while True:
            try:
                choice = input("\nSelect window number (or Enter for first): ").strip()
                if not choice:
                    hwnd, title, exe_path = windows[0]
                    print(f"Using: '{title}'")
                    return hwnd

                idx = int(choice) - 1
                if 0 <= idx < len(windows):
                    hwnd, title, exe_path = windows[idx]
                    print(f"Using: '{title}'")
                    return hwnd
                else:
                    print(f"Please enter a number between 1 and {len(windows)}")
            except ValueError:
                print("Invalid input. Please enter a number.")
            except (KeyboardInterrupt, EOFError):
                return None

    def start_app(self):
        """Start the Flutter Windows desktop app in detached mode"""
        print("Launching Flutter Windows app...")
        print("This may take a moment to build...\n")

        try:
            # Create a new detached process using CREATE_NEW_CONSOLE
            # This runs Flutter in a separate window so it doesn't block our terminal
            import subprocess

            CREATE_NEW_CONSOLE = 0x00000010
            DETACHED_PROCESS = 0x00000008

            # Start Flutter in a new console window
            self.flutter_process = subprocess.Popen(
                "flutter run -d windows",
                creationflags=CREATE_NEW_CONSOLE,
                shell=True
            )

            print("✓ Flutter app is starting in a new window...")
            print("Waiting for the app window to appear...\n")

            # Wait for the window to appear
            max_wait = 60  # Wait up to 60 seconds
            wait_interval = 2
            elapsed = 0

            while elapsed < max_wait:
                time.sleep(wait_interval)
                elapsed += wait_interval

                # Check if process died
                if self.flutter_process.poll() is not None:
                    print("✗ Flutter process exited unexpectedly")
                    return False

                # Try to find the window
                if self.find_flutter_window():
                    print("\n✓ Flutter app window found and ready!\n")
                    time.sleep(1)  # Brief pause to ensure fully ready
                    return True

                print(f"  Still waiting... ({elapsed}s)")

            print("\n✗ Timeout: Flutter window did not appear")
            print("The app may still be building. Try running without --auto-start")
            return False

        except Exception as e:
            print(f"✗ Error starting app: {e}")
            return False

    def take_screenshot(self, name=None):
        """Take a screenshot of the Flutter window"""
        # Always refresh the window handle to ensure it's valid
        # Window handles can become stale
        print(f"Looking for Flutter window...")
        self.target_window = self.find_flutter_window()

        if not self.target_window:
            print("✗ Flutter window not found. Make sure the app is running.")
            return False

        # Generate filename
        if not name:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            name = f"screenshot_{timestamp}"

        # Sanitize filename
        name = re.sub(r'[^\w\s-]', '', name).strip()
        name = re.sub(r'[-\s]+', '_', name)

        filepath = self.screenshots_dir / f"{name}.png"

        # Capture the window
        print(f"Capturing window...")
        screenshot = WindowCapture.capture_window(self.target_window)

        if screenshot:
            screenshot.save(filepath)
            print(f"✓ Screenshot saved: {filepath}")
            print(f"  Size: {screenshot.size[0]}x{screenshot.size[1]}\n")
            return True
        else:
            print("✗ Failed to capture screenshot\n")
            return False

    def interactive_mode(self):
        """Run in interactive mode for taking screenshots"""
        print("\n" + "="*60)
        print("SCREENSHOT TOOL - Interactive Mode")
        print("="*60)
        print("\nCommands:")
        print("  s - Take a screenshot")
        print("  q - Quit")
        print("="*60 + "\n")

        while self.running:
            try:
                command = input("Enter command (s/q): ").strip().lower()

                if command == 'q':
                    print("\nQuitting...")
                    self.running = False
                    break

                elif command == 's':
                    name = input("Enter screenshot name (or press Enter for auto-name): ").strip()
                    if not name:
                        name = None
                    self.take_screenshot(name)

                else:
                    print("Invalid command. Use 's' to screenshot or 'q' to quit.\n")

            except KeyboardInterrupt:
                print("\n\nInterrupted. Quitting...")
                self.running = False
                break
            except EOFError:
                print("\nQuitting...")
                self.running = False
                break

    def cleanup(self):
        """Clean up resources"""
        print("\nCleaning up...")

        if self.flutter_process and self.flutter_process.poll() is None:
            print("Stopping Flutter app...")
            self.flutter_process.terminate()
            try:
                self.flutter_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                print("Force killing Flutter app...")
                self.flutter_process.kill()

        print(f"Done! Your screenshots are in: {self.screenshots_dir.absolute()}")

    def run(self):
        """Main run method"""
        print("\n" + "="*60)
        print("Flutter Windows Desktop Screenshot Tool")
        print("="*60 + "\n")

        # Check if app is already running
        existing_window = self.find_flutter_window()

        if existing_window:
            print("\n✓ Found running Flutter app")
            self.target_window = existing_window
            self.interactive_mode()
        elif self.auto_start:
            # Start the Flutter app
            if not self.start_app():
                print("\nFailed to start Flutter app. Please check the error messages above.")
                return

            # Find the window
            self.target_window = self.find_flutter_window()
            if not self.target_window:
                print("\n✗ Could not find Flutter window after starting app")
                return

            # Run interactive mode
            try:
                self.interactive_mode()
            finally:
                self.cleanup()
        else:
            print("\n✗ No Flutter app is running")
            print("\nOptions:")
            print("  1. Start the app manually: flutter run -d windows")
            print("  2. Run this script with --auto-start flag")
            print("\nExample: python take_screenshot.py --auto-start")
            print("\nNote: The script looks for windows with 'epub_reader.exe' process.")
            print("Make sure the Flutter app is actually running (not just File Explorer).")


if __name__ == "__main__":
    auto_start = "--auto-start" in sys.argv or "-a" in sys.argv
    tool = ScreenshotTool(auto_start=auto_start)
    tool.run()
