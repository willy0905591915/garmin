using Toybox.WatchUi;
using Toybox.Sensor;
using Toybox.System;
using Toybox.Communications as Comm;
using Toybox.Lang;
using Toybox.Timer;
using Toybox.Position;
import Toybox.Graphics;
using Toybox.ActivityRecording;
using Toybox.Math;


class IoTWatchView3 extends WatchUi.View {
    var accel_x = [0];
    var accel_y = [0];
    var accel_z = [0];
    var heartRate = 0;
    var latitude = 0;
    var longitude = 0;
    var prev_accel_x = 0.0;
    var prev_accel_y = 0.0;
    var prev_accel_z = 0.0;
    var acc_max = 0.0;
    var acc_min = 0.0;
    var playerLoad = 0.0;
    var cadence = 0;
    var numericUnitId = 0;
    var url = "https://bvt4m4utok.execute-api.us-east-1.amazonaws.com/stage1/watchdata";
    var unitId = System.getDeviceSettings().uniqueIdentifier;
    var dataBatch = [];
    var distance = 0.0;
    // var sendTimer = new Timer.Timer();
    var sensorTimer = new Timer.Timer();
    private var _UUID as Lang.String;
    public var phone = System.getDeviceSettings().phoneConnected;
    var session = null;
    public var sessionId;
    // var lastSentDataTime = 0;
    private var fitField;
    private var fitFieldPlayerLoad, fitFieldCadence, fitFieldHeartRate, 
                fitFieldLatitude, fitFieldLongitude, fitFieldUnitID, fitFieldSessionID, fitFieldAccMax, fitFieldAccMin;

    public function initialize() {
        View.initialize();
        System.println("phone connected: " + phone);
        sessionId = generateSessionId();
        System.println("Session ID: " + sessionId);
        onStart();
        _UUID = unitId.toString();
        // we only send data batch at the end of the app
        // sendTimer.start(method(:sendDataBatch), 1000, true);
        sensorTimer.start(method(:updateSensorData), 1000, true);
        if (Toybox has :ActivityRecording) {

            session = ActivityRecording.createSession({          // set up recording session
                :name=>"IoT Data Collection",                              // set session name
                :sport=> Activity.SPORT_GENERIC,                // set sport type
                :subSport=> Activity.SUB_SPORT_GENERIC         // set sub sport type
           });

            // session.setActivityType(customSport);
            // session.enableSensorEvents({"accelerometer" => true, "heartRate" => true});


            // Create custom FIT fields using MESG_TYPE_DEVELOPER
        // fitFieldXAccel = session.createField("X Acceleration", 0, FitContributor.DATA_TYPE_FLOAT, 
        //     {:mesgType => FitContributor.MESG_TYPE_RECORD, :units => "m/s^2"});
        // fitFieldYAccel = session.createField("Y Acceleration", 1, FitContributor.DATA_TYPE_FLOAT, 
        //     {:mesgType => FitContributor.MESG_TYPE_RECORD, :units => "m/s^2"});
        // fitFieldZAccel = session.createField("Z Acceleration", 2, FitContributor.DATA_TYPE_FLOAT, 
        //     {:mesgType => FitContributor.MESG_TYPE_RECORD, :units => "m/s^2"});
        fitFieldPlayerLoad = session.createField("Player Load", 0, FitContributor.DATA_TYPE_FLOAT, 
            {:mesgType => FitContributor.MESG_TYPE_RECORD, :units => "G"});
        fitFieldHeartRate = session.createField("Heart Rate", 1, FitContributor.DATA_TYPE_UINT8, 
            {:mesgType => FitContributor.MESG_TYPE_RECORD, :units => "bpm"});
        fitFieldLatitude = session.createField("Latitude", 2, FitContributor.DATA_TYPE_FLOAT, 
            {:mesgType => FitContributor.MESG_TYPE_RECORD, :units => "degrees"});
        fitFieldLongitude = session.createField("Longitude", 3, FitContributor.DATA_TYPE_FLOAT, 
            {:mesgType => FitContributor.MESG_TYPE_RECORD, :units => "degrees"});
        fitFieldUnitID = session.createField("Unit ID", 4, FitContributor.DATA_TYPE_UINT32, 
            {:mesgType => FitContributor.MESG_TYPE_RECORD});
        fitFieldCadence = session.createField("Cadence", 5, FitContributor.DATA_TYPE_UINT16, 
            {:mesgType => FitContributor.MESG_TYPE_RECORD, :units => "rpm"});
        fitFieldSessionID = session.createField("SessionID", 6, FitContributor.DATA_TYPE_UINT16, 
            {:mesgType => FitContributor.MESG_TYPE_RECORD});    
        fitFieldAccMax = session.createField("Acc Max", 7, FitContributor.DATA_TYPE_FLOAT, 
            {:mesgType => FitContributor.MESG_TYPE_RECORD, :units => "G"});
        fitFieldAccMin = session.createField("Acc Min", 8, FitContributor.DATA_TYPE_FLOAT, 
            {:mesgType => FitContributor.MESG_TYPE_RECORD, :units => "G"});   

            session.start();                          
        }
    }

    function generateSessionId() {
        var time = System.getTimer();
        var random = Math.rand();
        return (time * 1000 + random).abs().toNumber();
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
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);  // Disable location updates
        if (session != null) {
            session.stop();
            session.save();
            session = null;
        }
        if (sensorTimer != null) {
        sensorTimer.stop();
        sensorTimer = null;
        }
        sendDataBatch(); // Send all collected data when the app stops
        dataBatch = [];  // Clear the data batch after sending
        accel_x = null;
        accel_y = null;
        accel_z = null;
        System.println("App stopped and all resources released");
    }

    // Initializes the view and registers for accelerometer data
    public function accelCallback(sensorData as Sensor.SensorData) as Void {
        if (sensorData has :accelerometerData) {
            var accelData = sensorData.accelerometerData;
            accel_x = accelData.x;
            accel_y = accelData.y;
            accel_z = accelData.z;
            System.println("accel_x: " + accel_x.toString());
            System.println("accel_y: " + accel_y.toString());
            System.println("accel_z: " + accel_z.toString());
            calculatePlayerLoad();
        }
    }

    public function calculatePlayerLoad() as Void {
        prev_accel_x = 0.0;
        prev_accel_y = 0.0;
        prev_accel_z = 0.0;
        playerLoad = 0.0;
        var sampleCount = 0;
        var isFirstSample = true;
        
        for (var i = 0; i < accel_x.size(); i++) {
            var combinedAcc = accel_x[i] + accel_y[i] + accel_z[i];
            
            if (isFirstSample) {
                acc_max = combinedAcc;
                acc_min = combinedAcc;
                isFirstSample = false;
            } else {
                if (combinedAcc > acc_max) {
                    acc_max = combinedAcc;
                }
                if (combinedAcc < acc_min) {
                    acc_min = combinedAcc;
                }
            }

            var dx = (accel_x[i] - prev_accel_x) / 1000;
            var dy = (accel_y[i] - prev_accel_y) / 1000;
            var dz = (accel_z[i] - prev_accel_z) / 1000;
            
            var load = Math.sqrt(dx * dx + dy * dy + dz * dz);
            playerLoad += load;
            
            prev_accel_x = accel_x[i];
            prev_accel_y = accel_y[i];
            prev_accel_z = accel_z[i];
            
            sampleCount++;
            
            if (sampleCount == 25) {
                collectData();
                writeToFitFile();
                playerLoad = 0.0;
                sampleCount = 0;
                isFirstSample = true;  // Reset for the next second
                accel_x = [0];  // Reset acceleration arrays
                accel_y = [0];
                accel_z = [0];
            }
    }
    }

    public function writeToFitFile() as Void {
        if (session != null) {
            fitFieldPlayerLoad.setData(playerLoad);
            fitFieldHeartRate.setData(heartRate);
            fitFieldLatitude.setData(latitude);
            fitFieldLongitude.setData(longitude);
            fitFieldUnitID.setData(numericUnitId);
            fitFieldCadence.setData(cadence);
            fitFieldSessionID.setData(sessionId);
            fitFieldAccMax.setData(acc_max);
            fitFieldAccMin.setData(acc_min);
            System.println("Successfully wrote data to FIT file");
        } else {
            System.println("Session is null, cannot write to FIT file");
        }   
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

        // Update distance
        if (sensorInfo has :accumulated_distance) {
            distance = sensorInfo.accumulated_distance;
        }

        // Request a position update
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    // Callback function for position updates
    public function onPosition(info as Position.Info) as Void {
        if (info has :position && info.position != null) {
            var location = info.position.toDegrees();
            latitude = location[0];
            longitude = location[1];
        }
    }


    // public function collectData() as Void{
    //     var cur_acc_x = 0;      
    //     var cur_acc_y = 0;
    //     var cur_acc_z = 0;

    //     for (var i = 0; i < accel_x.size(); ++i) {
    //         cur_acc_x = accel_x[i];
    //         cur_acc_y = accel_y[i];
    //         cur_acc_z = accel_z[i];

    //         var data = {
    //             "xAccel" => cur_acc_x.toNumber(),
    //             "yAccel" => cur_acc_y.toNumber(),
    //             "zAccel" => cur_acc_z.toNumber(),
    //             "heartRate" => heartRate,
    //             "latitude" => latitude,
    //             "longitude" => longitude,
    //             "unitID" => unitId
    //         }; 
    //         dataBatch.add(data);

    //         // Log the data for debugging
    //         System.println("Collected Data: " + data.toString());

    //         // Write data to FIT file
    //         if (session != null) {
    //             fitFieldXAccel.setData(cur_acc_x);
    //             fitFieldYAccel.setData(cur_acc_y);
    //             fitFieldZAccel.setData(cur_acc_z);
    //             fitFieldHeartRate.setData(heartRate);
    //             fitFieldLatitude.setData(latitude);
    //             fitFieldLongitude.setData(longitude);
    //             fitFieldUnitID.setData(unitId);
    //             System.println("Successfully wrote data to FIT file");
    //         } else {
    //             System.println("Session is null, cannot write to FIT file");
    //         }
    //     }
    // }
    public function collectData() as Void {
        numericUnitId = removeAlphabets(unitId.toString());
        var enhancedSpeed = 0.0;
        var activityInfo = Activity.getActivityInfo();
        if (activityInfo has :currentSpeed) {
            enhancedSpeed = activityInfo.currentSpeed;
        }


        var data = {
            "playerLoad" => playerLoad,
            "heartRate" => heartRate,
            "latitude" => latitude,
            "longitude" => longitude,
            "unitID" => numericUnitId,
            "cadence" => cadence,
            "distance" => distance,
            "sessionID" => sessionId,
            "acc_max" => acc_max, 
            "acc_min" => acc_min, 
            "enhanced_speed" => enhancedSpeed
        }; 
        dataBatch.add(data);

        // Get current time
        var currentTime = System.getClockTime();
        var timeString = Lang.format("$1$:$2$:$3$", [currentTime.hour, currentTime.min, currentTime.sec]);
        // print current time and collected data
        System.println("Current time: " + timeString);
        System.println("Collected Data: " + data.toString());
    }

    public function sendDataBatch() as Void {
        if (dataBatch.size() > 0) {
            System.println("Sending data batch. Size: " + dataBatch.size());
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
            System.println("Making web request to: " + url);
            Communications.makeWebRequest(url, params, options, method(:onReceive));
            dataBatch = [];  // Clear the data batch after sending
        } else {
            System.println("No data to send");
        }
    }

    // Function to remove alphabets from unitId
    public function removeAlphabets(str) {
        var result = 0;
        var numericChars = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
        for (var i = 0; i < str.length(); i++) {
            var char = str.substring(i, i+1);
            if (numericChars.indexOf(char) != -1) {
                result = (result * 10) + char.toNumber();
            }
        }
        if (result < 0) {
            result *= -1;
        }
        System.println("result: " + result);
        return result;
    }


    public function onReceive(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
        System.println("Received response. Code: " + responseCode);
        if (responseCode == 200) {
            System.println("Batch data sent successfully.");
            dataBatch = [];
        } else {
            System.println("Failed to send batch data. Response code: " + responseCode.toString());
            if (data != null) {
                System.println("Response data: " + data.toString());
            }
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
        // Set background color
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        
        var x = dc.getWidth() / 2;
        var y = dc.getHeight() / 2;
        
        var font = Graphics.FONT_XTINY;
        var textHeight = dc.getFontHeight(font);

        if (phone == true) {
            dc.drawText(x, 0, Graphics.FONT_TINY, "Phone connected", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(x, 0, Graphics.FONT_TINY, "Phone disconnected", Graphics.TEXT_JUSTIFY_CENTER);
        }

        dc.drawText(x, y / 2, Graphics.FONT_TINY, "Compute PlayerLoad", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, y/2 + textHeight, Graphics.FONT_TINY, "SessionID", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(x, y/2 + 2 * textHeight, Graphics.FONT_XTINY, sessionId, Graphics.TEXT_JUSTIFY_CENTER);
        y = y / 2 + 3 * textHeight;
        
        
        // var _UUID1 = _UUID.substring(0,20);
        // var _UUID2 = _UUID.substring(20,40);
        var str = unitId;
        var result = 0;
        var numericChars = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
        for (var i = 0; i < str.length(); i++) {
            var char = str.substring(i, i+1);
            if (numericChars.indexOf(char) != -1) {
                result = (result * 10) + char.toNumber();
            }
        }
        if (result < 0) {
            result *= -1;
        }

        dc.drawText(x, y, Graphics.FONT_TINY, "UUID:", Graphics.TEXT_JUSTIFY_CENTER);
        y += textHeight;
        dc.drawText(x, y, Graphics.FONT_XTINY, result, Graphics.TEXT_JUSTIFY_CENTER);
        // y += textHeight;
        // dc.drawText(x, y, font, _UUID2, Graphics.TEXT_JUSTIFY_CENTER);
        // View.onUpdate(dc);
    }

    public function onHide() {
        onStop();
    }
}
