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

#include <stdint.h>

#define MSG_LENGTH 16
#define FIRMWARE_MAJOR_VERSION 0
#define FIRMWARE_MINOR_VERSION 1
#define FIRMWARE_MAGIC_IDENTIFIER 0x120B07

enum msg_type {
  nop = 0,
  set_joints_position_speed = 1,
  get_joints_position_speed = 2,
  get_status = 3,
  get_version = 4,
};

typedef struct {
  int16_t position;
  int16_t speed;
} joint_move_speed_t;

typedef struct{
  joint_move_speed_t joint[3];
} msg_joints_position_speed_t;

typedef struct {
  uint32_t uptime;
  uint16_t transmission_errors;
} msg_status_t;

typedef struct {
  uint32_t magic_identifier;
  uint8_t major;
  uint8_t minor;
  // uint8_t hash[MSG_LENGTH - sizeof(msg_type) - 2*sizeof(uint8_t)];
  // Cannot pass arguments from the makefile to the compiler because of the 
  // Arduino executable being in the way :(
  // No git hash in the version message.
} msg_version_t;

// A struct which represents a message.
typedef struct {
  msg_type type;
  union {
    // msg_version_t version;
    msg_joints_position_speed_t joints_position_speed;
    msg_status_t status;
    msg_version_t version;
    uint8_t raw[MSG_LENGTH - sizeof(msg_type)];
  };
} msg_t;
