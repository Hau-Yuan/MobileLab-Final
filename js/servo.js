var wpi = require('wiringpi-node');
var bleno = require('bleno');

// bleno modules
var PrimaryService = bleno.PrimaryService;
var Characteristic = bleno.Characteristic;
var Descriptor = bleno.Descriptor;

// Give our Raspberry Pi a unique identifier
var name = 'My Awesome Servo';

// Get your own UUIDs at https://www.uuidgenerator.net/
var deviceUuid = '89f3cea5-7619-4c7f-9114-1fd62a5bce2d';

var fisrtServoServiceUuid = '08196144-d50c-4a48-af4b-1337c47bbcb9';
var fisrtServoCharacteristicUuid = '44f6b86f-43e6-4c7b-8cab-820b7dfb441e';

var secondServoServiceUuid = '71059488-69db-49f6-8121-319e5d730e33';
var secondServoCharacteristicUuid = '1af42567-4a2c-4a8d-bffd-0b9b8e406d68';

var MAX_PULSE = 200;
var MIN_PULSE = 100;
var delay = 20;
var direction = 1;
var pulse = 100;

/**
 * Servo setup
 */
wpi.wiringPiSetupGpio();
wpi.pinMode(18, wpi.PWM_OUTPUT)
wpi.pinMode(19, wpi.PWM_OUTPUT)
wpi.pwmSetMode(wpi.PWM_MODE_MS)
wpi.pwmSetClock(192)
wpi.pwmSetRange(2000)


/**
 * BLE setup
 */

// Set a custom device name
// by setting the BLENO_DEVICE_NAME environment variable:
process.env.BLENO_DEVICE_NAME = name;

// Apple recommended interval
// process.env.BLENO_ADVERTISING_INTERVAL = 20;

/**
 * Define our servo service
 */

var firstServoService = new PrimaryService({
  uuid: fisrtServoServiceUuid,

  characteristics: [
    new Characteristic({
      uuid: fisrtServoCharacteristicUuid,
      properties: ['read', 'write'],
      descriptors: [
        new bleno.Descriptor({
          uuid: fisrtServoCharacteristicUuid,
          value: 'first servo position'
        })
      ],
      onWriteRequest: function(data, offset, withoutResponse, callback) {
        // https://nodejs.org/api/buffer.html
    if (firstServoData) {
      console.log('>>> offset', offset);
      var value = firstServoData.readInt8(offset);
      console.log('>> Received BLE write request:', value);
      // convert value to pulse
      var pulseRange = MAX_PULSE - MIN_PULSE;
      var pulse = Math.round(MIN_PULSE + (value / 100) * pulseRange);
      console.log('>> Writing pulsetoservo', pulse);
      wpi.pwmWrite(18, pulse);


    }

    var result = Characteristic.RESULT_SUCCESS;
    callback(result);
      }
    })
  ]

});


var secondServoService = new PrimaryService({
  uuid: secondServoServiceUuid,

  characteristics: [
    new Characteristic({
      uuid: secondServoCharacteristicUuid,
      properties: ['read', 'write'],
      descriptors: [
        new bleno.Descriptor({
          uuid: secondServoCharacteristicUuid,
          value: 'second servo position'
        })
      ],
      onWriteRequest: function(data, offset, withoutResponse, callback) {
        // https://nodejs.org/api/buffer.html
    if (secondServoData) {
      console.log('>>> offset', offset);
      var value = secondServoService.readInt8(offset);
      console.log('>> Received BLE write request:', value);
      // convert value to pulse
      var pulseRange = MAX_PULSE - MIN_PULSE;
      var pulse = Math.round(MIN_PULSE + (value / 100) * pulseRange);
      console.log('>> Writing pulsetoservo', pulse);
      wpi.pwmWrite(19, pulse);

    }

    var result = Characteristic.RESULT_SUCCESS;
    callback(result);
      }
    })
  ]

});

bleno.setServices([
  firstServoService, secondServoService
]);


/**
 * State changes
 */
bleno.on('stateChange', function(newState) {
  console.log('bleno state changed:', newState);

   if (newState === 'poweredOn') {
      bleno.startAdvertising( name, [deviceUuid] );
   } else {
     bleno.stopAdvertising();
   }

});

/**
 * Start advertising BLE device
 */
bleno.on('advertisingStart', function(err) {
  if (!err) {
      console.log('Started advertising with uuid', deviceUuid);

  } else {
    console.log('Error advertising our BLE device!', err);
  }
});
