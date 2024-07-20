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
        var unitId = System.getDeviceSettings().uniqueIdentifier;
        // Fill in this variable with your AWS API Gateway endpoint
        var url = "https://w66efzraph.execute-api.us-east-1.amazonaws.com/prod/watchdata";
        var timer = 1000; // in ms
        
        function initialize() {
            View.initialize();
            // Set up a timer
            dataTimer.start(method(:timerCallback), timer, true);
        }
        
        function timerCallback() {
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

        //Send the data to the REST API
        
        var params = {
            "heartRate" => hR.toNumber(),
            "xAccel" => xAccel.toNumber(),
            "yAccel" => yAccel.toNumber(),
            "zAccel" => zAccel.toNumber(),
            "heading" => heading.toFloat(),
            "speed" => speed.toFloat(),
            "latitude" => latitude.toFloat(),
            "longitude" => longitude.toFloat(),
            "unitID" => unitId
        };

        // set a variable to record time and print the time and collected data in log for debugging
        var currentTime = System.getClockTime();
        System.println("Collected data at: " + currentTime.hour.format("%02d") + ":" + currentTime.min.format("%02d") + ":" + currentTime.sec.format("%02d"));
        System.println("Collected data: " + params);

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
        
        function onReceive(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void{
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
