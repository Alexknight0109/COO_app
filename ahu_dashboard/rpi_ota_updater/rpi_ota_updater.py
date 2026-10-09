#!/usr/bin/env python3
"""
Raspberry Pi OTA Updater for AHU Dashboard
Simple git pull based update system - receives commands via local MQTT from ESP32
"""

import os
import sys
import json
import time
import subprocess
import logging
import threading
import paho.mqtt.client as mqtt
from datetime import datetime

# ==================== Configuration ====================

# MQTT Configuration - local broker (ESP32 hotspot network)
MQTT_BROKER = os.getenv('MQTT_BROKER', 'localhost')
MQTT_PORT = int(os.getenv('MQTT_PORT', '1883'))
MQTT_USERNAME = os.getenv('MQTT_USERNAME', 'almed')
MQTT_PASSWORD = os.getenv('MQTT_PASSWORD', 'Almed1234$')
MQTT_CLIENT_ID = f"rpi_ota_updater_{int(time.time())}"

# MQTT Topics
MQTT_TOPIC_COMMAND = 'almed/rpi/ota/command'   # Subscribe: receive OTA commands
MQTT_TOPIC_STATUS = 'almed/rpi/ota/status'      # Publish: report OTA status

# Dashboard Configuration
DASHBOARD_DIR = os.getenv('DASHBOARD_DIR', '/home/radxa/COO_app')
FLUTTER_PI_SERVICE = os.getenv('FLUTTER_PI_SERVICE', 'ahu-dashboard')
FLUTTER_BIN = os.getenv('FLUTTER_BIN', 'flutter')
GIT_BRANCH = os.getenv('GIT_BRANCH', 'main')

# Logging Configuration
LOG_FILE = '/var/log/ahu_ota_updater.log'

# ==================== Setup Logging ====================

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
    ]
)

# Try to add file handler
try:
    if os.access(os.path.dirname(LOG_FILE), os.W_OK):
        file_handler = logging.FileHandler(LOG_FILE, mode='a')
        file_handler.setFormatter(logging.Formatter('%(asctime)s [%(levelname)s] %(message)s'))
        logging.getLogger().addHandler(file_handler)
except:
    pass

logger = logging.getLogger('rpi_ota_updater')

# ==================== Global State ====================

mqtt_client = None
current_version = 'unknown'
update_in_progress = False


def get_current_version():
    """Get current git commit hash/version"""
    global current_version
    try:
        result = subprocess.run(
            ['git', 'rev-parse', '--short', 'HEAD'],
            cwd=DASHBOARD_DIR,
            capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0:
            current_version = result.stdout.strip()
        else:
            current_version = 'unknown'
    except Exception as e:
        logger.error(f"Failed to get git version: {e}")
        current_version = 'unknown'
    return current_version


APP_VERSION_BASE = '1.0'


def version_info():
    """(version, commit) shown on the dashboard: 1.0.<commit count>, short hash."""
    try:
        count = subprocess.run(
            ['git', 'rev-list', '--count', 'HEAD'],
            cwd=DASHBOARD_DIR, capture_output=True, text=True, timeout=10
        ).stdout.strip()
        commit = subprocess.run(
            ['git', 'rev-parse', '--short', 'HEAD'],
            cwd=DASHBOARD_DIR, capture_output=True, text=True, timeout=10
        ).stdout.strip()
        return f"{APP_VERSION_BASE}.{count or 0}", commit
    except Exception:
        return f"{APP_VERSION_BASE}.0", ''


def version_label():
    version, commit = version_info()
    return f"v{version} · {commit}" if commit else f"v{version}"


def publish_status(status, message, progress=None, **extra):
    """Publish OTA status to MQTT (ESP32 will relay to AWS)"""
    global mqtt_client, current_version
    
    if mqtt_client is None or not mqtt_client.is_connected():
        logger.warning("MQTT not connected, cannot publish status")
        return
    
    payload = {
        'status': status,
        'message': message,
        'current_version': current_version,
        'timestamp': datetime.utcnow().isoformat()
    }
    payload.update(extra)
    
    if progress is not None:
        payload['progress'] = progress
    
    try:
        mqtt_client.publish(MQTT_TOPIC_STATUS, json.dumps(payload), qos=1)
        logger.info(f"Status: {status} - {message}")
    except Exception as e:
        logger.error(f"Failed to publish status: {e}")


def run_git_pull():
    """Execute git pull origin main"""
    logger.info(f"Running git pull origin {GIT_BRANCH}...")
    
    try:
        # First, fetch to see if there are updates
        fetch_result = subprocess.run(
            ['git', 'fetch', 'origin', GIT_BRANCH],
            cwd=DASHBOARD_DIR,
            capture_output=True, text=True, timeout=120
        )
        
        if fetch_result.returncode != 0:
            logger.error(f"Git fetch failed: {fetch_result.stderr}")
            return False, fetch_result.stderr
        
        # Check if we're behind
        status_result = subprocess.run(
            ['git', 'status', '-uno'],
            cwd=DASHBOARD_DIR,
            capture_output=True, text=True, timeout=10
        )
        
        if 'Your branch is up to date' in status_result.stdout:
            return True, 'Already up to date'
        
        # Do the pull
        pull_result = subprocess.run(
            ['git', 'pull', 'origin', GIT_BRANCH],
            cwd=DASHBOARD_DIR,
            capture_output=True, text=True, timeout=300
        )
        
        if pull_result.returncode == 0:
            logger.info(f"Git pull successful: {pull_result.stdout}")
            return True, pull_result.stdout
        else:
            logger.error(f"Git pull failed: {pull_result.stderr}")
            return False, pull_result.stderr
            
    except subprocess.TimeoutExpired:
        logger.error("Git operation timed out")
        return False, "Operation timed out"
    except Exception as e:
        logger.error(f"Git pull error: {e}")
        return False, str(e)


def flutter_project_dir():
    """Flutter package directory. COO_app keeps it under ahu_dashboard/."""
    nested = os.path.join(DASHBOARD_DIR, 'ahu_dashboard')
    if os.path.isfile(os.path.join(nested, 'pubspec.yaml')):
        return nested
    return DASHBOARD_DIR


def _flutter_env():
    env = os.environ.copy()
    home = os.path.expanduser('~')
    extra = [
        os.path.join(home, 'flutter', 'bin'),
        os.path.join(home, 'development', 'flutter', 'bin'),
        os.path.join(home, 'snap', 'flutter', 'common', 'flutter', 'bin'),
        '/opt/flutter/bin',
        '/usr/local/bin',
    ]
    env['PATH'] = os.pathsep.join(extra + [env.get('PATH', '')])
    return env


BUILD_TIMEOUT_S = 1800
# Typical Radxa release build time; progress eases toward 95% around this mark.
BUILD_EXPECTED_S = 240


def run_flutter_build(progress_start=None, progress_end=None):
    """Rebuild the Linux bundle the kiosk launches, stamping the version.

    When a progress range is given, publishes 'building' every few seconds so
    the dashboard can show a live bar during the multi-minute build.
    """
    project = flutter_project_dir()
    env = _flutter_env()
    logger.info(f"Building Linux bundle in {project}")
    try:
        pub = subprocess.run(
            [FLUTTER_BIN, 'pub', 'get'],
            cwd=project, capture_output=True, text=True, timeout=600, env=env,
        )
        if pub.returncode != 0:
            tail = (pub.stderr or pub.stdout or 'pub get failed')[-500:]
            logger.error(f"flutter pub get failed: {tail}")
            return False, tail

        version, commit = version_info()
        cmd = [
            FLUTTER_BIN, 'build', 'linux', '--release',
            f'--dart-define=APP_VERSION={version}',
            f'--dart-define=APP_COMMIT={commit}',
        ]
        proc = subprocess.Popen(
            cmd, cwd=project, env=env,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
        )
        output = []
        reader = threading.Thread(
            target=lambda: output.extend(proc.stdout), daemon=True
        )
        reader.start()

        started = time.time()
        while proc.poll() is None:
            elapsed = time.time() - started
            if elapsed > BUILD_TIMEOUT_S:
                proc.kill()
                logger.error("Flutter build timed out")
                return False, "Flutter build timed out"
            if progress_start is not None and progress_end is not None:
                fraction = min(elapsed / BUILD_EXPECTED_S, 1.0) * 0.95
                pct = int(progress_start + (progress_end - progress_start) * fraction)
                publish_status(
                    'building',
                    f'Building new version... {int(elapsed // 60)}m {int(elapsed % 60):02d}s',
                    progress=pct,
                )
            time.sleep(5)
        reader.join(timeout=5)

        if proc.returncode == 0:
            logger.info("Flutter linux build succeeded")
            return True, "Linux bundle built"
        tail = ''.join(output)[-500:] or 'build failed'
        logger.error(f"Flutter build failed: {tail}")
        return False, tail
    except Exception as e:
        logger.error(f"Flutter build error: {e}")
        return False, str(e)


def _relaunch_kiosk():
    """Start the autostart launcher when no systemd dashboard service exists."""
    project = flutter_project_dir()
    launcher = os.path.join(project, 'rpi_kiosk_setup', 'launch_kiosk.sh')
    if not os.path.isfile(launcher):
        return False, f"Kiosk launcher not found at {launcher}"
    subprocess.run(['pkill', '-x', 'ahu_dashboard'], check=False)
    # launch_kiosk.sh refuses to start while an old copy is still exiting.
    for _ in range(25):
        if subprocess.run(['pgrep', '-x', 'ahu_dashboard'],
                          capture_output=True).returncode != 0:
            break
        time.sleep(0.2)
    env = os.environ.copy()
    env['DISPLAY'] = os.getenv('DISPLAY', ':0')
    env['ALMED_KIOSK_BOOT_DELAY'] = '0'
    subprocess.Popen(
        ['bash', launcher],
        env=env,
        start_new_session=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    logger.info(f"Relaunched kiosk via {launcher}")
    return True, "Kiosk relaunched"


def restart_dashboard():
    """Restart the dashboard service, or the kiosk binary if that service is absent."""
    logger.info(f"Restarting {FLUTTER_PI_SERVICE} service...")

    try:
        result = subprocess.run(
            ['sudo', 'systemctl', 'restart', FLUTTER_PI_SERVICE],
            capture_output=True, text=True, timeout=60
        )

        if result.returncode == 0:
            logger.info("Dashboard restarted successfully")
            return True, "Dashboard restarted"
        logger.error(f"systemctl restart failed: {result.stderr}")
        return _relaunch_kiosk()

    except subprocess.TimeoutExpired:
        logger.error("Restart timed out")
        return False, "Restart timed out"
    except Exception as e:
        logger.error(f"Restart error: {e}")
        return _relaunch_kiosk()


def _running_is_stale(running_commit):
    """True when the dashboard reports an older build than the checked-out code
    (e.g. someone ran git pull by hand without rebuilding)."""
    if not running_commit:
        return False
    head = current_version
    return bool(head) and head != 'unknown' and not (
        head.startswith(running_commit) or running_commit.startswith(head)
    )


def perform_update(confirm_restart=False, running_commit=None):
    """Pull, rebuild, then restart the dashboard.

    With confirm_restart (sent by the dashboard's update button) it stops after
    the build with 'ready_to_restart' so the user chooses when to restart.
    """
    global update_in_progress
    
    if update_in_progress:
        publish_status('error', 'Update already in progress')
        return False
    
    update_in_progress = True
    
    try:
        # Step 1: Notify starting
        publish_status('starting', 'Starting update...', progress=0)
        
        # Step 2: Git pull
        publish_status('pulling', 'Downloading update...', progress=10)
        success, message = run_git_pull()
        
        if not success:
            publish_status('error', f'Git pull failed: {message}')
            return False
        
        if 'Already up to date' in message:
            get_current_version()
            if not _running_is_stale(running_commit):
                publish_status('up_to_date', 'Already up to date', progress=100)
                return True
        
        publish_status('pulled', 'Code downloaded', progress=25)

        old_version = current_version
        get_current_version()

        publish_status('building', 'Building new version...', progress=30)
        success, message = run_flutter_build(progress_start=30, progress_end=98)
        if not success:
            publish_status('error', f'Flutter build failed: {message}')
            return False

        if confirm_restart:
            label = version_label()
            publish_status(
                'ready_to_restart',
                f'{label} is ready. Restart to use it.',
                progress=100,
                new_version=label,
            )
            return True

        publish_status('restarting', 'Restarting dashboard...', progress=85)
        success, message = restart_dashboard()
        
        if not success:
            publish_status('error', f'Restart failed: {message}')
            return False
        
        # Step 5: Success!
        time.sleep(3)  # Give dashboard time to start
        publish_status('complete', f'✅ Updated: {old_version} → {current_version}', progress=100)
        
        # Send multiple confirmations
        for i in range(5):
            time.sleep(1)
            publish_status('complete', f'🎉 OTA Update Complete! Version: {current_version} [{i+1}/5]', progress=100)
        
        return True
        
    except Exception as e:
        logger.error(f"Update failed: {e}")
        publish_status('error', f'Update failed: {str(e)}')
        return False
    finally:
        update_in_progress = False


def check_for_updates(running_commit=None):
    """Check if there are updates available (git fetch)"""
    publish_status('checking', 'Checking for updates...')
    
    try:
        # Fetch from remote
        result = subprocess.run(
            ['git', 'fetch', 'origin', GIT_BRANCH],
            cwd=DASHBOARD_DIR,
            capture_output=True, text=True, timeout=60
        )
        
        if result.returncode != 0:
            publish_status('error', 'Failed to check for updates')
            return
        
        # Check status
        status_result = subprocess.run(
            ['git', 'status', '-uno'],
            cwd=DASHBOARD_DIR,
            capture_output=True, text=True, timeout=10
        )
        
        get_current_version()

        behind = subprocess.run(
            ['git', 'rev-list', '--count', f'HEAD..origin/{GIT_BRANCH}'],
            cwd=DASHBOARD_DIR,
            capture_output=True, text=True, timeout=10
        )
        commits_behind = 0
        if behind.returncode == 0:
            try:
                commits_behind = int(behind.stdout.strip() or '0')
            except ValueError:
                commits_behind = 0
        elif 'Your branch is behind' in status_result.stdout:
            commits_behind = 1

        if commits_behind > 0:
            publish_status('update_available', f'Update available! {commits_behind} new commits')
        elif _running_is_stale(running_commit):
            publish_status('update_available', 'Downloaded update not installed yet')
        else:
            publish_status('up_to_date', f'Already on latest version: {current_version}')
            
    except Exception as e:
        logger.error(f"Check failed: {e}")
        publish_status('error', f'Check failed: {str(e)}')


# ==================== MQTT Callbacks ====================

def on_connect(client, userdata, flags, rc, properties=None):
    """Callback when connected to MQTT broker"""
    if rc == 0:
        logger.info(f"✓ Connected to MQTT broker: {MQTT_BROKER}:{MQTT_PORT}")
        client.subscribe(MQTT_TOPIC_COMMAND, qos=1)
        logger.info(f"✓ Subscribed to: {MQTT_TOPIC_COMMAND}")
        
        # Publish online status
        get_current_version()
        publish_status('online', f'RPi OTA Updater ready (v{current_version})')
    else:
        logger.error(f"Failed to connect to MQTT: {rc}")


def on_disconnect(client, userdata, rc, properties=None):
    """Callback when disconnected from MQTT broker"""
    logger.warning(f"Disconnected from MQTT broker (rc={rc})")


def on_message(client, userdata, msg):
    """Callback when MQTT message received"""
    try:
        topic = msg.topic
        payload = msg.payload.decode('utf-8')
        logger.info(f"📩 Received: {topic} - {payload}")
        
        data = json.loads(payload)
        command = data.get('type', data.get('command', ''))
        from_esp = data.get('from_esp', 'unknown')
        
        logger.info(f"Command: {command} (from ESP: {from_esp})")
        
        if command in ['ota_update', 'update', 'pull']:
            logger.info("🔄 Received update command - starting git pull...")
            threading.Thread(
                target=perform_update,
                kwargs={
                    'confirm_restart': bool(data.get('confirm_restart')),
                    'running_commit': data.get('running_commit'),
                },
                daemon=True,
            ).start()
            
        elif command in ['check_update', 'check']:
            logger.info("🔍 Received check command...")
            threading.Thread(
                target=check_for_updates,
                kwargs={'running_commit': data.get('running_commit')},
                daemon=True,
            ).start()
            
        elif command == 'restart':
            logger.info("🔄 Received restart command...")
            publish_status('restarting', 'Restarting dashboard...')
            success, message = restart_dashboard()
            if success:
                time.sleep(2)
                get_current_version()
                publish_status('restarted', f'Dashboard restarted (v{current_version})')
            else:
                publish_status('error', f'Restart failed: {message}')
            
        elif command == 'status':
            logger.info("📊 Received status request...")
            get_current_version()
            publish_status('online', f'RPi OTA Updater ready (v{current_version})')
            
        else:
            logger.warning(f"Unknown command: {command}")
            
    except json.JSONDecodeError:
        logger.error(f"Invalid JSON: {msg.payload}")
    except Exception as e:
        logger.error(f"Error processing message: {e}")


# ==================== Main ====================

def main():
    global mqtt_client
    
    print("=" * 50)
    print("  RPi OTA Updater for AHU Dashboard")
    print("  Simple Git Pull Based Updates")
    print("=" * 50)
    print(f"  MQTT Broker: {MQTT_BROKER}:{MQTT_PORT}")
    print(f"  Dashboard Dir: {DASHBOARD_DIR}")
    print(f"  Git Branch: {GIT_BRANCH}")
    print(f"  Service: {FLUTTER_PI_SERVICE}")
    print("=" * 50)
    
    # Check if dashboard directory exists and is a git repo
    if not os.path.exists(DASHBOARD_DIR):
        logger.error(f"Dashboard directory not found: {DASHBOARD_DIR}")
        sys.exit(1)
    
    if not os.path.exists(os.path.join(DASHBOARD_DIR, '.git')):
        logger.error(f"Not a git repository: {DASHBOARD_DIR}")
        sys.exit(1)
    
    # Get current version
    get_current_version()
    logger.info(f"Current Version: {current_version}")
    
    # Create MQTT client
    mqtt_client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id=MQTT_CLIENT_ID)
    mqtt_client.username_pw_set(MQTT_USERNAME, MQTT_PASSWORD)
    
    # Set callbacks
    mqtt_client.on_connect = on_connect
    mqtt_client.on_disconnect = on_disconnect
    mqtt_client.on_message = on_message
    
    # Connect to broker with retry
    while True:
        try:
            logger.info(f"Connecting to MQTT broker {MQTT_BROKER}:{MQTT_PORT}...")
            mqtt_client.connect(MQTT_BROKER, MQTT_PORT, keepalive=60)
            break
        except Exception as e:
            logger.error(f"MQTT connection failed: {e}")
            logger.info("Retrying in 10 seconds...")
            time.sleep(10)
    
    # Start MQTT loop
    try:
        logger.info("✓ Starting MQTT loop - waiting for commands...")
        mqtt_client.loop_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down...")
    finally:
        mqtt_client.disconnect()
        logger.info("Disconnected")


if __name__ == '__main__':
    main()
