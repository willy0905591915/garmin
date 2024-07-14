    using Toybox.WatchUi;
    using Toybox.Communications as Comm;
    using Toybox.Sensor;
    using Toybox.Graphics;
    using Toybox.System;
    using Toybox.Lang;
    using Toybox.Time.Gregorian;
    using Toybox.Sensor;
    using Toybox.Application;
    using Toybox.Position;
    using Toybox.Timer;

    class IoTWatchView extends WatchUi.View {
        var dataTimer = new Timer.Timer();
        var batchTimer = new Timer.Timer();
        var dataBatch = [];
        // Fill in this variable with your AWS API Gateway endpoint
        var url = "https://w66efzraph.execute-api.us-east-1.amazonaws.com/prod/watchdata";
        var dataInterval = 500; // in ms
        var batchInterval = 1000; // Send batch every 2 second
        
        function initialize() {
            View.initialize();
            // Set up a timer
            dataTimer.start(method(:collectData), dataInterval, true);
            batchTimer.start(method(:sendBatch), batchInterval, true);
        }
        
        function collectData() {
            var sensorInfo = Sensor.getInfo();
            var positionInfo = Position.getInfo();
            var xAccel = 0;
            var yAccel = 0;
            var zAccel = 0;
            var hR = 0;
            var heading = 0;
            var speed = 0;
            var latitude = 0;
            var longitude = 0;
        
            //Collect Data
            //Accelerometer
            if (sensorInfo has :accel && sensorInfo.accel != null) {
                var accel = sensorInfo.accel;
                xAccel = accel[0];
                yAccel = accel[1];
                zAccel = accel[2];
            }
            else {
                xAccel = 0;
                yAccel = 0;
                zAccel = 0;
            }
            //Heartrate
            if (sensorInfo has :heartRate && sensorInfo.heartRate != null) {
                hR = sensorInfo.heartRate;
            }
            else {
                hR = 0;
            }
            //heading
            if (sensorInfo has :heading && sensorInfo.heading != null) {
                heading = sensorInfo.heading;
            }
            else {
                heading = 0;
            }
            //Speed
            if (sensorInfo has :speed && sensorInfo.speed != null) {
                speed = sensorInfo.speed;
            }
            else {
                speed = 0;
            }
            //Position
            if (positionInfo has :position && positionInfo.position != null) {
                var location = positionInfo.position.toDegrees();
                latitude = location[0];
                longitude = location[1];
            }
            else {
                latitude = 0;
                longitude = 0;

            }

            var currentTime = System.getClockTime();
            var data = {
                "heartRate" => hR.toNumber(),
                "xAccel" => xAccel.toNumber(),
                "yAccel" => yAccel.toNumber(),
                "zAccel" => zAccel.toNumber(),
                "heading" => heading.toFloat(),
                "speed" => speed.toFloat(),
                "latitude" => latitude.toFloat(),
                "longitude" => longitude.toFloat()
            };
            dataBatch.add(data);

            // Log for debugging
            System.println("Collected data at: " + currentTime.hour.format("%02d") + ":" + currentTime.min.format("%02d") + ":" + currentTime.sec.format("%02d"));
            System.println("Collected data: " + data);
            System.println("dataBatch Length:" + dataBatch.size())
        }

        //Send the data to the REST API
        function sendBatch() {
            if (dataBatch.size() > 0) {
                var params = {"dataBatch" => dataBatch};
                var headers = {
                    "Content-Type" => Comm.REQUEST_CONTENT_TYPE_JSON
                };
                var options = {
                    :headers => headers,
                    :method => Comm.HTTP_REQUEST_METHOD_POST,
                    :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
                };
                Communications.makeWebRequest(url, params, options, method(:onReceive));
                dataBatch = [];
            }
        }
        
        function onReceive(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void{
            System.println("Response Code: " + responseCode.toString());
            if (data != null) {
                System.println("Response Data: " + data.toString());
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
        }

    }
