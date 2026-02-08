"""Watch project directory for changes and auto-regenerate dashboard.

This script monitors the .project/ directory for changes to registry.json
and artifact files (spec.md, design.md, plan.md), then triggers dashboard
regeneration after a configurable debounce period.
"""

import argparse
import signal
import subprocess
import sys
import time
from pathlib import Path
from threading import Event, Timer
from typing import Any

from watchdog.events import FileSystemEvent, FileSystemEventHandler
from watchdog.observers import Observer


class DebouncedDashboardRegeneration(FileSystemEventHandler):
    """File system event handler with debounced dashboard regeneration.

    This handler watches for changes to registry.json and artifact files,
    then triggers dashboard regeneration after a debounce period to avoid
    excessive regeneration during rapid file changes.
    """

    def __init__(
        self, debounce_seconds: float, project_root: Path, output_path: Path
    ) -> None:
        """Initialize the event handler.

        Args:
            debounce_seconds: Wait time in seconds after last change before regenerating
            project_root: Root directory of project
            output_path: Path where dashboard.html will be written
        """
        self.debounce_seconds = debounce_seconds
        self.project_root = project_root
        self.output_path = output_path
        self.timer: Timer | None = None
        self.shutdown_event = Event()

    def _should_trigger_regeneration(self, event: FileSystemEvent) -> bool:
        """Determine if event should trigger dashboard regeneration.

        Args:
            event: File system event to evaluate

        Returns:
            True if event should trigger regeneration, False otherwise
        """
        # Ignore directory events
        if event.is_directory:
            return False

        # src_path can be str or bytes, ensure it's str for Path
        src_path_str = (
            event.src_path
            if isinstance(event.src_path, str)
            else event.src_path.decode('utf-8')
        )
        path = Path(src_path_str)

        # Ignore dashboard.html changes (prevent infinite loop)
        if path.name == 'dashboard.html':
            return False

        # Watch registry.json
        if path.name == 'registry.json':
            return True

        # Watch artifact files (spec.md, design.md, plan.md)
        if path.name in ('spec.md', 'design.md', 'plan.md'):
            return True

        return False

    def _regenerate_dashboard(self) -> None:
        """Trigger dashboard regeneration by calling generate-dashboard script."""
        try:
            print(
                f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Regenerating dashboard...",
                flush=True,
            )
            result = subprocess.run(
                [
                    sys.executable,
                    '-m',
                    'src.scripts.generate_dashboard',
                    '--output',
                    str(self.output_path),
                    '--project-root',
                    str(self.project_root),
                ],
                capture_output=True,
                text=True,
            )

            if result.returncode == 0:
                timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
                print(
                    f"[{timestamp}] Dashboard regenerated successfully",
                    flush=True,
                )
            else:
                timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
                print(
                    f"[{timestamp}] ERROR: Dashboard generation failed",
                    file=sys.stderr,
                )
                print(result.stderr, file=sys.stderr)
        except Exception as e:
            print(
                f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] ERROR: {e}",
                file=sys.stderr,
            )

    def _schedule_regeneration(self) -> None:
        """Schedule dashboard regeneration after debounce period.

        Cancels any pending timer and schedules a new one.
        """
        # Cancel existing timer if present
        if self.timer is not None:
            self.timer.cancel()

        # Schedule new timer
        self.timer = Timer(self.debounce_seconds, self._regenerate_dashboard)
        self.timer.start()

    def on_modified(self, event: FileSystemEvent) -> None:
        """Handle file modification events.

        Args:
            event: File system event with modification details
        """
        if self._should_trigger_regeneration(event):
            src_path_str = (
                event.src_path
                if isinstance(event.src_path, str)
                else event.src_path.decode('utf-8')
            )
            timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
            print(
                f"[{timestamp}] Change detected: {src_path_str}",
                flush=True,
            )
            self._schedule_regeneration()

    def on_created(self, event: FileSystemEvent) -> None:
        """Handle file creation events.

        Args:
            event: File system event with creation details
        """
        if self._should_trigger_regeneration(event):
            src_path_str = (
                event.src_path
                if isinstance(event.src_path, str)
                else event.src_path.decode('utf-8')
            )
            timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
            print(
                f"[{timestamp}] Change detected: {src_path_str}",
                flush=True,
            )
            self._schedule_regeneration()

    def on_deleted(self, event: FileSystemEvent) -> None:
        """Handle file deletion events.

        Args:
            event: File system event with deletion details
        """
        if self._should_trigger_regeneration(event):
            src_path_str = (
                event.src_path
                if isinstance(event.src_path, str)
                else event.src_path.decode('utf-8')
            )
            timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
            print(
                f"[{timestamp}] Change detected: {src_path_str}",
                flush=True,
            )
            self._schedule_regeneration()

    def shutdown(self) -> None:
        """Gracefully shutdown the event handler.

        Cancels any pending timer and sets shutdown event.
        """
        if self.timer is not None:
            self.timer.cancel()
        self.shutdown_event.set()


def main() -> None:
    """Main entry point for watch-project script."""
    parser = argparse.ArgumentParser(
        description='Watch project directory and auto-regenerate dashboard'
    )
    parser.add_argument(
        '--debounce',
        type=float,
        default=2.0,
        help='Debounce period in seconds (default: 2.0)',
    )
    parser.add_argument(
        '--project-root',
        type=Path,
        default=Path('.'),
        help='Root directory of project (default: current directory)',
    )
    parser.add_argument(
        '--output',
        type=Path,
        default=None,
        help='Path to dashboard.html output file (default: .project/dashboard.html)',
    )

    args = parser.parse_args()

    # Determine output path
    output_path = args.output
    if output_path is None:
        output_path = args.project_root / '.project' / 'dashboard.html'

    # Validate project root
    project_dir = args.project_root / '.project'
    if not project_dir.exists():
        print(
            f"ERROR: Project directory not found: {project_dir}",
            file=sys.stderr,
        )
        sys.exit(2)

    # Create event handler and observer
    event_handler = DebouncedDashboardRegeneration(
        debounce_seconds=args.debounce,
        project_root=args.project_root,
        output_path=output_path,
    )
    observer = Observer()
    observer.schedule(event_handler, str(project_dir), recursive=True)

    # Set up signal handler for graceful shutdown
    def signal_handler(sig: int, frame: Any) -> None:
        """Handle SIGTERM/SIGINT signals for graceful shutdown."""
        print(
            f"\n[{time.strftime('%Y-%m-%d %H:%M:%S')}] Shutting down watcher...",
            flush=True,
        )
        event_handler.shutdown()
        observer.stop()

    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)

    # Start watching
    print(
        f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Watching {project_dir} for changes...",
        flush=True,
    )
    timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
    print(
        f"[{timestamp}] Debounce period: {args.debounce} seconds",
        flush=True,
    )
    observer.start()

    try:
        # Keep running until shutdown event is set
        while not event_handler.shutdown_event.is_set():
            time.sleep(1)
    except KeyboardInterrupt:
        pass
    finally:
        observer.stop()
        observer.join()
        print(
            f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Watcher stopped",
            flush=True,
        )


if __name__ == '__main__':
    main()
