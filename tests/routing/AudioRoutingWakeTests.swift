import CoreAudio
import XCTest
@testable import Equaliser

@MainActor
final class AudioRoutingWakeTests: XCTestCase {
    private let speaker = AudioDevice(
        id: 100,
        uid: "speaker",
        name: "Speakers",
        transportType: kAudioDeviceTransportTypeBuiltIn
    )

    func testInactiveRoutingDoesNotRestartAfterWake() async {
        let (coordinator, devices, defaults) = makeCoordinator(defaultUID: "speaker")

        coordinator.handleWillSleep()
        coordinator.handleDidWake()
        try? await Task.sleep(for: .milliseconds(400))

        XCTAssertEqual(coordinator.routingStatus, .idle)
        XCTAssertEqual(devices.refreshCount, 0)
        XCTAssertTrue(defaults.restoredUIDs.isEmpty)
    }

    func testDefaultOutputNotificationDoesNotRestartStoppedRouting() {
        let (coordinator, _, defaults) = makeCoordinator(defaultUID: "speaker")
        coordinator.selectedOutputDeviceID = "speaker"

        defaults.onSystemDefaultChanged?(speaker)

        XCTAssertEqual(coordinator.routingStatus, .idle)
    }

    func testWakeRecoveryRefreshesDevicesAndCanBeCancelled() async {
        let (coordinator, devices, defaults) = makeCoordinator(defaultUID: DRIVER_DEVICE_UID)
        coordinator.selectedOutputDeviceID = "speaker"
        coordinator.routingStatus = .active(inputName: "Equaliser", outputName: "Speakers")

        coordinator.handleWillSleep()
        XCTAssertEqual(coordinator.routingStatus, .idle)
        XCTAssertEqual(defaults.restoredUIDs, ["speaker"])

        coordinator.handleDidWake()
        try? await Task.sleep(for: .milliseconds(400))
        XCTAssertGreaterThan(devices.refreshCount, 1)

        coordinator.stopRouting()
        let refreshCount = devices.refreshCount
        try? await Task.sleep(for: .milliseconds(600))
        XCTAssertEqual(devices.refreshCount, refreshCount)
    }

    func testSecondSleepCancelsPendingWakeAttempt() async {
        let (coordinator, devices, _) = makeCoordinator(defaultUID: DRIVER_DEVICE_UID)
        coordinator.selectedOutputDeviceID = "speaker"
        coordinator.routingStatus = .active(inputName: "Equaliser", outputName: "Speakers")

        coordinator.handleWillSleep()
        coordinator.handleDidWake()
        coordinator.handleWillSleep()
        let refreshCount = devices.refreshCount
        try? await Task.sleep(for: .milliseconds(400))

        XCTAssertEqual(devices.refreshCount, refreshCount)
        XCTAssertEqual(coordinator.routingStatus, .idle)
    }

    func testFailedWakeRecoveryLeavesPhysicalOutputSelected() async {
        let (coordinator, _, defaults) = makeCoordinator(defaultUID: DRIVER_DEVICE_UID)
        coordinator.selectedOutputDeviceID = "speaker"
        coordinator.routingStatus = .active(inputName: "Equaliser", outputName: "Speakers")

        coordinator.handleWillSleep()
        coordinator.handleDidWake()
        try? await Task.sleep(for: .milliseconds(4_600))

        XCTAssertEqual(coordinator.routingStatus, .error("Could not restore audio after wake"))
        XCTAssertEqual(defaults.currentUID, "speaker")
    }

    private func makeCoordinator(defaultUID: String) -> (AudioRoutingCoordinator, WakeDeviceProvider, WakeDefaultObserver) {
        let driver = UnavailableDriver()
        let devices = WakeDeviceProvider(outputs: [speaker])
        let defaults = WakeDefaultObserver(currentUID: defaultUID)
        let enumerator = DeviceEnumerationService(driverAccess: driver)
        let coordinator = AudioRoutingCoordinator(
            deviceProvider: devices,
            deviceChangeCoordinator: DeviceChangeCoordinator(deviceEnumerator: enumerator),
            eqConfiguration: EQConfiguration(),
            meterStore: MeterStore(metersEnabled: false),
            volumeService: DeviceVolumeService(),
            permissionService: AudioPermissionService(),
            systemDefaultObserver: defaults,
            sampleRateService: DeviceSampleRateService(),
            driverAccess: driver
        )
        return (coordinator, devices, defaults)
    }
}

@MainActor
private final class WakeDeviceProvider: DeviceProviding {
    let inputDevices: [AudioDevice] = []
    let outputDevices: [AudioDevice]
    var refreshCount = 0

    init(outputs: [AudioDevice]) { outputDevices = outputs }

    func device(forUID uid: String) -> AudioDevice? { outputDevices.first { $0.uid == uid } }
    func deviceID(forUID uid: String) -> AudioDeviceID? { device(forUID: uid)?.id }
    func enumerateInputDevices() {}
    func refreshDevices() { refreshCount += 1 }
    func findBuiltInAudioDevice() -> AudioDevice? { outputDevices.first { $0.isBuiltIn } }
    func selectFallbackOutputDevice(excluding excludeUID: String?) -> AudioDevice? {
        outputDevices.first { $0.uid != excludeUID }
    }
}

@MainActor
private final class WakeDefaultObserver: SystemDefaultObserving {
    var isAppSettingSystemDefault = false
    var onSystemDefaultChanged: ((AudioDevice) -> Void)?
    var currentUID: String
    var restoredUIDs: [String] = []

    init(currentUID: String) { self.currentUID = currentUID }

    func startObserving() {}
    func stopObserving() {}
    func getCurrentSystemDefaultOutputUID() -> String? { currentUID }
    func restoreSystemDefaultOutput(to uid: String) -> Bool {
        currentUID = uid
        restoredUIDs.append(uid)
        return true
    }
    func setDriverAsDefault(shortTimeout: Bool, onSuccess: (() -> Void)?, onFailure: (() -> Void)?) {
        currentUID = DRIVER_DEVICE_UID
        onSuccess?()
    }
    func clearAppSettingFlagAfterDelay() {}
}

@MainActor
private final class UnavailableDriver: DriverAccessing {
    let isReady = false
    let deviceID: AudioObjectID? = nil
    let deviceRegistry = DriverDeviceRegistry()

    func isDriverVisible() -> Bool { false }
    func findDriverDeviceWithRetry(initialDelayMs: Int, maxAttempts: Int) async -> AudioDeviceID? { nil }
    func setDeviceName(_ name: String) -> Bool { false }
    func setDriverSampleRate(matching targetRate: Float64) -> Float64? { nil }
    func restoreToBuiltInSpeakers() -> Bool { false }
    func hasSharedMemoryCapability() -> Bool { false }
}
