using Toybox.WatchUi;
using Toybox.Sensor;
using Toybox.System;
using Toybox.Communications as Comm;
using Toybox.Lang;

class IoTWatchView extends WatchUi.View {
    var accel_x = [0];
    var accel_y = [0];
    var accel_z = [0];
    var heartBeatIntervals = [0];
    var url = "https://w66efzraph.execute-api.us-east-1.amazonaws.com/prod/watchdata";
    var unitId = System.getDeviceSettings().uniqueIdentifier;


    public function initialize() {
        View.initialize();
        onStart();
    }

    // start
    public function onStart() as Void {
        // initialize accelerometer
        var options = {:period => 1, 
            :accelerometer => {:enabled => true, :sampleRate => 25},
            :heartBeatIntervals => {:enabled => true} 
            };
        try {
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
        // if (sensorData has :heartRateData) {
        //     var hrData = sensorData.heartRateData;
        //     heartBeatIntervals = hrData.heartBeatIntervals;
        // }

        onAccelData();
    }

    public function onAccelData() as Void{
        var cur_acc_x = 0;      
        var cur_acc_y = 0;
        var cur_acc_z = 0;
        var cur_HR = 0;
        for (var i = 0; i < accel_x.size(); ++i) {
            cur_acc_x = accel_x[i];
            cur_acc_y = accel_y[i];
            cur_acc_z = accel_z[i];
            // cur_HR = heartBeatIntervals[i];
            // print for logging
            System.println("accel_x: " + cur_acc_x.toString() + 
            "accel_y: " + cur_acc_y.toString() + "accel_z: " + cur_acc_z.toString());
            System.println("unitID: " + unitId);
            // System.println("HR: " + cur_HR.toString());
            // Send data to REST API
            var params = {
                // "heartRate" => cur_HR.toNumber(),
                "xAccel" => cur_acc_x.toNumber(),
                "yAccel" => cur_acc_y.toNumber(),
                "zAccel" => cur_acc_z.toNumber(),
                "unitID" => unitId
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
        }
    }

    public function onReceive(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void{
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
