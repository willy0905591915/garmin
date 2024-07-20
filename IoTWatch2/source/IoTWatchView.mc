using Toybox.WatchUi;
using Toybox.Sensor;
using Toybox.System;
using Toybox.Communications as Comm;
using Toybox.Lang;
using Toybox.Timer;
using Toybox.Position;


class IoTWatchView extends WatchUi.View {
    var accel_x = [0];
    var accel_y = [0];
    var accel_z = [0];
    var heartRate = 0;
    var latitude = 0;
    var longitude = 0;
    var url = "https://w66efzraph.execute-api.us-east-1.amazonaws.com/prod/watchdata";
    var unitId = System.getDeviceSettings().uniqueIdentifier;
    var dataBatch = [];
    var sendTimer = new Timer.Timer();
    var sensorTimer = new Timer.Timer();


    public function initialize() {
        View.initialize();
        onStart();
        sendTimer.start(method(:sendDataBatch), 1000, true);
        sensorTimer.start(method(:updateSensorData), 1000, true);
    }

    // start
    public function onStart() as Void {
        // initialize accelerometer
        var options = {
            :period => 1, 
            :accelerometer => {:enabled => true, :sampleRate => 25},
            :heartBeatIntervals => {:enabled => true} 
            };
        try {
            Sensor.unregisterSensorDataListener();
            Sensor.registerSensorDataListener(method(:accelCallback), options);
            
        } catch(e) {
            System.println(e.getErrorMessage());
        }
    }

    public function onStop() as Void {
        Sensor.unregisterSensorDataListener();
    }

    // Initializes the view and registers for accelerometer data
    public function accelCallback(sensorData as Sensor.SensorData) as Void {
        if (sensorData has :accelerometerData) {
            var accelData = sensorData.accelerometerData;
            accel_x = accelData.x;
            accel_y = accelData.y;
            accel_z = accelData.z;
        }
        collectData();
    }

    // Update heart rate, latitude, and longitude every second
    public function updateSensorData() as Void {
        var sensorInfo = Sensor.getInfo();
        if (sensorInfo has :heartRate) {
            heartRate = sensorInfo.heartRate;
            if (heartRate == null) {
                System.println("heartRate is null");
            }
        }
        
        var positionInfo = Position.getInfo();
        if (positionInfo has :position) {
            var location = positionInfo.position.toDegrees();
            latitude = location[0];
            longitude = location[1];
        }
    }

    public function collectData() as Void{
        var cur_acc_x = 0;      
        var cur_acc_y = 0;
        var cur_acc_z = 0;

        for (var i = 0; i < accel_x.size(); ++i) {
            cur_acc_x = accel_x[i];
            cur_acc_y = accel_y[i];
            cur_acc_z = accel_z[i];

            var data = {
                "xAccel" => cur_acc_x.toNumber(),
                "yAccel" => cur_acc_y.toNumber(),
                "zAccel" => cur_acc_z.toNumber(),
                "heartRate" => heartRate,
                "latitude" => latitude,
                "longitude" => longitude,
                "unitID" => unitId
            }; 
            dataBatch.add(data);

            // Log the data for debugging
            System.println("Collected Data: " + data.toString());
        }
    }

    public function sendDataBatch() as Void {
        if (dataBatch.size() > 0) {
            var params = {
                "dataBatch" => dataBatch
            };

            var headers = {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            };
            var options = {
                :headers => headers,
                :method => Communications.HTTP_REQUEST_METHOD_POST,
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            };
            Communications.makeWebRequest(url, params, options, method(:onReceive));
            dataBatch = [];
        }
    }

    public function onReceive(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void{
        if (responseCode == 200) {
            System.println("Batch data sent successfully.");
        } else {
            System.println("Failed to send batch data. Response code: " + responseCode.toString());
        }
    }

    // Load your resources here
    public function onLayout(dc) {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    public function onShow() {
    }

    // Update the view
    public function onUpdate(dc) {
        View.onUpdate(dc);
    }

    public function onHide() {
        onStop();
    }
}
