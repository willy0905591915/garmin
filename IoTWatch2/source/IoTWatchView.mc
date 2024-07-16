using Toybox.WatchUi;
using Toybox.Sensor;
using Toybox.System;

class IoTWatchView extends WatchUi.View {

    function initialize() {
        View.initialize();
        enableAccel();
    }

    // Initializes the view and registers for accelerometer data
    function enableAccel() {
        var maxSampleRate = 25;
        System.println("Sample Rate: " + maxSampleRate);

        // Unregister any existing listeners to avoid conflicts
        try {
            Sensor.unregisterSensorDataListener();
        } catch(e) {
            System.println("Error while unregistering sensor listener: " + e.getErrorMessage());
        }

        // Initialize accelerometer to request the maximum amount of data possible
        var options = { 
            :period => 1, 
            :accelerometer => {
                :enabled => true,       // Enable the accelerometer
                :sampleRate => maxSampleRate       // 25 samples
            }
        };
        try {
            Sensor.registerSensorDataListener(method(:accelHistoryCallback), options);
        } catch(e) {
            System.println("Error: " + e.getErrorMessage());
        }
    }

    function accelHistoryCallback(sensorData as Sensor.SensorData) as Void {
        if (sensorData != null) {
            var accelData = sensorData.accelerometerData;
            System.println("Accel Data: X=" + accelData.x + ", Y=" + accelData.y + ", Z=" + accelData.z);
        } else {
            System.println("No accelerometer data available");
        }
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onShow() {
    }

    // Update the view
    function onUpdate(dc) {
        View.onUpdate(dc);
    }

    function onHide() {
        disableAccel();
    }

    public function disableAccel() as Void {
        try {
            Sensor.unregisterSensorDataListener();
        } catch(e) {
            System.println("Error while unregistering sensor listener: " + e.getErrorMessage());
        }
    }
}
