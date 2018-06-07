/*
  The MIT License (MIT)

  Copyright (c) 2016 Ivor Wanders

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
*/

// This library cannot be installed with the built-in library manager.
// Be sure to unzip it into a library folder such that it is available.
#include "DynamixelSerial3.h"

// include the message specification.
#include "./messages.h"

// #define DEBUGPRINTS
#ifdef DEBUGPRINTS
  #define DBG(a) Serial.print(a);
  #define DBGln(a) Serial.println(a);
#else
  #define DBG(a)
  #define DBGln(a)
#endif


// #define TEST_POSITION 768
// #define TEST_MESSAGE_SIZES
// #define TEST_READ_MOTOR_MOVEMENT
// #define TEST_POSITION_READ_ERRORS
// #define TEST_SEND_DATA

// Settings
#define DYNAMIXEL_PIN_DIRECTION 2
#define DYNAMIXEL_BAUD 1000000
#define JOINT_COUNT 3

uint16_t serial_receive_timeout_ = 1000;
msg_status_t status_;

void setup() {
  Serial.setTimeout(serial_receive_timeout_);  // Set the readBytes timeout.
  Serial.begin(115200);

  Dynamixel.begin(DYNAMIXEL_BAUD, DYNAMIXEL_PIN_DIRECTION);

  delay(100);

  // This is a persistent value set to 30 in the original firmware.
  // Here we set it back to the factory default.
  Dynamixel.setRDT(1,50);
  delay(10);
  Dynamixel.setRDT(2,50);
  delay(10);
  Dynamixel.setRDT(3,50);
  delay(10);

  #ifdef TEST_POSITION
    DBGln("Setting the servos to center position.")
    Dynamixel.moveSpeed(1,TEST_POSITION,100);
    Dynamixel.moveSpeed(2,TEST_POSITION,100);
    Dynamixel.moveSpeed(3,TEST_POSITION,100);
  #endif

  #ifdef TEST_MESSAGE_SIZES
    delay(5000);
    DBGln("Testing message sizes");
    DBG("Sizeof(msg_t): ");DBGln(sizeof(msg_t));
    DBG("Sizeof(msg_type): ");DBGln(sizeof(msg_type));
    DBG("Sizeof(msg_joints_position_speed_t): ");DBGln(sizeof(msg_joints_position_speed_t));
  #endif

  #ifdef TEST_READ_MOTOR_MOVEMENT
    for (uint8_t osc=0; osc < 3 ; osc++){
      uint8_t i = 2;
      Dynamixel.moveSpeed(i,400,100);
      delay(40);
      for (uint16_t j=0; j < 10; j++){
        int position = Dynamixel.readPosition(i);
        delay(40);
        int speed = Dynamixel.readSpeed(i);
        delay(40);
        DBG("joint[");DBG(i);DBG("] Position: ");DBG(position);DBG(", speed: ");DBG(speed);DBGln("");
        DBG("Temperature: "); DBGln(Dynamixel.readTemperature(i));
        DBG("Voltage: "); DBGln(Dynamixel.readVoltage(i));
      }
      Dynamixel.moveSpeed(i,600,100);
      delay(40);
      for (uint16_t j=0; j < 10; j++){
        int position = Dynamixel.readPosition(i);
        delay(40);
        int speed = Dynamixel.readSpeed(i);
        delay(40);
        DBG("joint[");DBG(i);DBG("] Position: ");DBG(position);DBG(", speed: ");DBG(speed);DBGln("");
      }
    };
  #endif

  #ifdef TEST_SEND_DATA
    char buffer[sizeof(msg_t)] = {0};
    msg_t* response = reinterpret_cast<msg_t*>(buffer);
    response->type = get_joints_position_speed;
    uint32_t j = 0;
    while (1) {
      j++;
      delay(100);
      for (auto i=0; i < JOINT_COUNT; i++){
        response->joints_position_speed.joint[i].position = i*1 + j*10;
        response->joints_position_speed.joint[i].speed = i*1 + j*10;
      }
      Serial.write(buffer, sizeof(msg_t));
    }
  #endif

  #ifdef TEST_POSITION_READ_ERRORS
    int16_t pos[3] = {0};
    int16_t goal = 450;
    int16_t thresshold = 400;
    uint32_t fails[3] = {0};
    for (uint8_t i=0; i < 3; i++){
      Dynamixel.moveSpeed(i+1, goal, 300);
    }
    uint32_t loops = 0;
    while (1){
      for (uint8_t i=0; i < 3; i++){
        pos[i] = Dynamixel.readPosition(i+1);
        if (pos[i] < thresshold){
          fails[i]++;
          DBG("pos["); DBG(i);DBG("] = ");DBGln(pos[i]);
          delay(1000);
        }
      }
      if ((loops % 1000) == 0) {
        DBG("Loops: ");DBGln(loops);
        DBG("fails: ");for(uint8_t m=0;m<3;m++){DBG(fails[m]);DBG(" ");};DBGln();
      }
      loops++;
    }
  #endif
}

void send_joints_position_speed(){
  char buffer[sizeof(msg_t)] = {0};
  msg_t* response = reinterpret_cast<msg_t*>(buffer);
  response->type = get_joints_position_speed;
  uint16_t speed;
  for (auto i=0; i < JOINT_COUNT; i++){
    response->joints_position_speed.joint[i].position = Dynamixel.readPosition(i+1);

    // If a value is in the rage of 0~1023, it means that the motor rotates to the CCW direction.
    // If a value is in the rage of 1024~2047, it means that the motor rotates to the CW direction.
    // That is, the 10th bit becomes the direction bit to control the direction, and 0 and 1024 are equal.It is the current moving speed.
    speed = Dynamixel.readSpeed(i+1);
    response->joints_position_speed.joint[i].speed = (speed & (1<<10)) ? (speed & 0x3FF) : -(speed & 0x3FF);
    DBG("joint[");DBG(i);DBG("].moveSpeed(");DBG(response->joints_position_speed.joint[i].position);DBG(",");DBG(response->joints_position_speed.joint[i].speed);DBGln(")");
  }
  Serial.write(buffer, sizeof(msg_t));
}


// Handle incomming commands from the serial port.
void processCommand(const msg_t* msg) {
  switch (msg->type) {
    case nop:
      DBGln("Got nop.");
      break;

    case set_joints_position_speed:
      for (auto i=0; i < JOINT_COUNT; i++){
        // DBG("joint[");DBG(i);DBG("].moveSpeed(");DBG(msg->joints_position_speed.joint[i].position);DBG(",");DBG(msg->joints_position_speed.joint[i].speed);DBGln(")");
        Dynamixel.moveSpeed(i+1, msg->joints_position_speed.joint[i].position, msg->joints_position_speed.joint[i].speed);
      }
      break;

    case get_joints_position_speed:
      send_joints_position_speed();
      break;

    case get_status:
      {
        char buffer[sizeof(msg_t)] = {0};
        msg_t* response = reinterpret_cast<msg_t*>(buffer);
        response->type = get_status;
        response->status = status_;
        response->status.uptime = millis();
        Serial.write(buffer, sizeof(msg_t));
      }
      break;
    case get_version:
      {
        char buffer[sizeof(msg_t)] = {0};
        msg_t* response = reinterpret_cast<msg_t*>(buffer);
        response->type = get_version;
        response->version.major = FIRMWARE_MAJOR_VERSION;
        response->version.minor = FIRMWARE_MINOR_VERSION;
        response->version.magic_identifier = FIRMWARE_MAGIC_IDENTIFIER;
        Serial.write(buffer, sizeof(msg_t));
      }
      break;

    default:
      status_.transmission_errors++;
      DBG("Got unknown command: ");DBGln(msg->type);
  }
}

// loop; continuously read IR commands and read serial commands.
void loop() {
  // Check if we should read the serial port for commands.
  if (Serial.available()) {
    char buffer[sizeof(msg_t)] = {0};
    if (Serial.readBytes(buffer, sizeof(msg_t)) == sizeof(msg_t)) {
      // we have a command, process it.
      processCommand(reinterpret_cast<msg_t*>(buffer));
    }
  }
}
