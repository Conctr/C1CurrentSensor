// Copyright (c) 2017 Mystic Pants Pty Ltd
// This file is licensed under the MIT License
// http://opensource.org/licenses/MIT

// Import Libraries
#require "conctr.device.class.nut:1.0.0"


class CurrentSensor{
    DEBUG = false;
    WINDING_RATIO = 60;
    GAUGE_FILTER = 100;
    GAUGE_RATIO = 20.0;
    ZERO_OFFSET = 120;
    MAX_ADC = 65535.0;
    POLL_FREQ = 0.5;
    _currentSensor = null;
    
    constructor(currentSensor) {
        _currentSensor = currentSensor;
    }
    
    // function that reads the current
    // 
    // @params none
    // @returns none
    // 
    function readCurrent() {
        local maxReading = 0;
        local minReading = 0;
        local currentGauge = 0; 
        local previousReading = 0;
        
        // Take 1000 samples
        for (local i = 0; i < 1000; i++) {
            local currentReading = (currentSensor.read() + currentSensor.read() + currentSensor.read())/3.0;
            previousReading = currentReading;
            if (currentReading > maxReading) {
                maxReading = currentReading;
                // Apply a Lowpass Filter
                currentGauge = currentGauge + (currentReading - currentGauge)/GAUGE_FILTER;
            }
            if (currentReading < minReading) {
                minReading = currentReading;
                
            }
        }

        // Calculate the voltage amplitude and current
        local voltageDiff = (maxReading - minReading - ZERO_OFFSET)/ MAX_ADC * hardware.voltage();
        local calcCurrent = voltageDiff*WINDING_RATIO;
        currentGauge = (currentGauge/GAUGE_RATIO);
        
        
        conctr.sendData({
            "current" : calcCurrent, "currentgauge": currentGauge.tointeger(),
        },function(error,response) {
            if(error) {
                server.error(error); 
            } else {
                if (DEBUG) server.log("CONCTR Response Code:" + response.statusCode); 
            }
        }.bindenv(this));
        
        if (DEBUG){
            server.log("Our Current Gauge Shows:" + currentGauge);
            server.log("Our Sensor Voltage Reading is:" + voltageDiff);
            server.log("Our Current Reading is:" + calcCurrent);
        }
        
        imp.wakeup(POLL_FREQ, readCurrent.bindenv(this));
        
    }
    
}



//=============================================================================
// START OF PROGRAM

// Setup Conctr
conctr <- Conctr({"sendLoc": false});

// Initialise pins
currentSensorPin <- hardware.pinF;
currentSensorPin.configure(ANALOG_IN);

// CurrentSensor
cs <- CurrentSensor(currentSensorPin);
cs.readCurrent();

