using Toybox.WatchUi;
using Toybox.Sensor;
using Toybox.System;

class IoTWatchView extends WatchUi.View {
    var accel_x = null;
    var accel_y = null;
    var accel_z = null;

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
            accel_x = accelData.x;
            accel_y = accelData.y;
            accel_z = accelData.z;
            onAccelData();
        } else {
            System.println("No accelerometer data available");
        }
    }

    function onAccelData() as Void{
        var cur_acc_x = 0;      
        var cur_acc_y = 0;
        var cur_acc_z = 0;
        for (var i = 0; i < accel_x.size(); ++i) {
            cur_acc_x = accel_x[i];
            cur_acc_y = accel_y[i];
            cur_acc_z = accel_z[i];
            System.println("accel_x: " + cur_acc_x.toString() + 
            "accel_y: " + cur_acc_y.toString() + "accel_z: " + cur_acc_z.toString());
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
