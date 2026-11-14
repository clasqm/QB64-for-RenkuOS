/*
  Haiku gamepad backend for QB64, based on the Haiku device kit (BJoystick).

  This file is compiled as C++ (see os/haiku/build.sh) because BJoystick is a
  C++ class, but it implements the same C interface as the Linux and macOS
  backends of Alex Diener's gamepad library.

  BJoystick reports every joystick the Haiku joystick server knows about in
  /dev/input/joystick, so no direct access to the Linux input layer (which does
  not exist on Haiku) is required.
*/

#include "gamepad/Gamepad.h"
#include "gamepad/Gamepad_private.h"

#include <device/Joystick.h>
#include <OS.h>
#include <SupportDefs.h>

#include <stdlib.h>
#include <string.h>

struct Gamepad_devicePrivate {
	char*		portName;
	BJoystick*	joystick;
	int16*		axisValues;
	bool*		buttonValues;
};

static struct Gamepad_device** devices = NULL;
static unsigned int numDevices = 0;
static unsigned int nextDeviceID = 0;

static double
currentTimestamp()
{
	// system_time() returns microseconds since boot
	return (double)system_time() / 1000000.0;
}

static const char*
deviceName(BJoystick* joystick)
{
	static char name[B_OS_NAME_LENGTH];
	name[0] = '\0';
	BString controllerName;
	if (joystick->GetControllerName(&controllerName) == B_OK
		&& controllerName.Length() > 0) {
		strlcpy(name, controllerName.String(), sizeof(name));
	} else {
		strlcpy(name, "Joystick", sizeof(name));
	}
	return name;
}

static void
disposeDevice(struct Gamepad_device* device)
{
	struct Gamepad_devicePrivate* priv
		= (struct Gamepad_devicePrivate*)device->privateData;

	if (priv != NULL) {
		if (priv->joystick != NULL) {
			priv->joystick->Close();
			delete priv->joystick;
		}
		free(priv->portName);
		free(priv->axisValues);
		free(priv->buttonValues);
		free(priv);
	}

	free((void*)device->description);
	free(device->axisStates);
	free(device->buttonStates);
	free(device);
}

static struct Gamepad_device*
deviceForPort(const char* portName)
{
	unsigned int deviceIndex;

	for (deviceIndex = 0; deviceIndex < numDevices; deviceIndex++) {
		struct Gamepad_devicePrivate* priv
			= (struct Gamepad_devicePrivate*)devices[deviceIndex]->privateData;
		if (priv != NULL && strcmp(priv->portName, portName) == 0)
			return devices[deviceIndex];
	}

	return NULL;
}

static void
addDevice(const char* portName)
{
	BJoystick* joystick = new BJoystick();
	if (joystick->Open(portName) != B_OK) {
		delete joystick;
		return;
	}

	// Make sure the device is polled correctly before reading its layout.
	joystick->Update();

	struct Gamepad_device* device
		= (struct Gamepad_device*)calloc(1, sizeof(struct Gamepad_device));
	struct Gamepad_devicePrivate* priv
		= (struct Gamepad_devicePrivate*)calloc(1,
			sizeof(struct Gamepad_devicePrivate));
	if (device == NULL || priv == NULL) {
		free(device);
		free(priv);
		joystick->Close();
		delete joystick;
		return;
	}

	priv->portName = strdup(portName);
	priv->joystick = joystick;

	device->deviceID = nextDeviceID++;
	device->description = strdup(deviceName(joystick));
	device->vendorID = 0;
	device->productID = 0;
	device->numAxes = (unsigned int)joystick->CountAxes();
	device->numButtons = (unsigned int)joystick->CountButtons();
	device->axisStates = (float*)calloc(device->numAxes, sizeof(float));
	device->buttonStates = (bool*)calloc(device->numButtons, sizeof(bool));
	device->privateData = priv;

	priv->axisValues = (int16*)calloc(device->numAxes, sizeof(int16));
	priv->buttonValues = (bool*)calloc(device->numButtons, sizeof(bool));

	devices = (struct Gamepad_device**)realloc(devices,
		sizeof(struct Gamepad_device*) * (numDevices + 1));
	devices[numDevices++] = device;

	if (Gamepad_deviceAttachCallback != NULL) {
		Gamepad_deviceAttachCallback(device, Gamepad_deviceAttachContext);
	}
}

static void
removeDevice(struct Gamepad_device* device)
{
	unsigned int deviceIndex;

	for (deviceIndex = 0; deviceIndex < numDevices; deviceIndex++) {
		if (devices[deviceIndex] != device)
			continue;

		if (Gamepad_deviceRemoveCallback != NULL) {
			Gamepad_deviceRemoveCallback(device,
				Gamepad_deviceRemoveContext);
		}

		disposeDevice(device);
		numDevices--;
		for (; deviceIndex < numDevices; deviceIndex++)
			devices[deviceIndex] = devices[deviceIndex + 1];
		return;
	}
}

void
Gamepad_init()
{
	// Devices are enumerated on the first Gamepad_detectDevices() call.
}

void
Gamepad_shutdown()
{
	while (numDevices > 0)
		removeDevice(devices[0]);

	free(devices);
	devices = NULL;
	numDevices = 0;
}

unsigned int
Gamepad_numDevices()
{
	return numDevices;
}

struct Gamepad_device*
Gamepad_deviceAtIndex(unsigned int deviceIndex)
{
	if (deviceIndex >= numDevices)
		return NULL;

	return devices[deviceIndex];
}

void
Gamepad_detectDevices()
{
	BJoystick enumerator;

	// Haiku extension: refresh the device list so hot-plugged pads appear.
	enumerator.RescanDevices();

	int32 count = enumerator.CountDevices();
	for (int32 index = 0; index < count; index++) {
		char portName[B_OS_NAME_LENGTH];
		if (enumerator.GetDeviceName(index, portName, sizeof(portName)) != B_OK)
			continue;
		if (deviceForPort(portName) == NULL)
			addDevice(portName);
	}
}

void
Gamepad_processEvents()
{
	unsigned int deviceIndex;

	for (deviceIndex = 0; deviceIndex < numDevices; deviceIndex++) {
		struct Gamepad_device* device = devices[deviceIndex];
		struct Gamepad_devicePrivate* priv
			= (struct Gamepad_devicePrivate*)device->privateData;
		if (priv == NULL || priv->joystick == NULL)
			continue;

		if (priv->joystick->Update() != B_OK)
			continue;

		if (device->numAxes > 0
			&& priv->joystick->GetAxisValues(priv->axisValues, 0) == B_OK) {
			for (unsigned int axisIndex = 0;
				axisIndex < device->numAxes; axisIndex++) {
				float value = (float)priv->axisValues[axisIndex] / 32767.0f;
				if (value > 1.0f) value = 1.0f;
				if (value < -1.0f) value = -1.0f;
				if (value == device->axisStates[axisIndex])
					continue;

				float lastValue = device->axisStates[axisIndex];
				device->axisStates[axisIndex] = value;
				if (Gamepad_axisMoveCallback != NULL) {
					Gamepad_axisMoveCallback(device, axisIndex, value,
						lastValue, currentTimestamp(),
						Gamepad_axisMoveContext);
				}
			}
		}

		if (device->numButtons > 0
			&& priv->joystick->GetButtonValues(priv->buttonValues, 0) == B_OK) {
			for (unsigned int buttonIndex = 0;
				buttonIndex < device->numButtons; buttonIndex++) {
				bool down = priv->buttonValues[buttonIndex];
				if (down == device->buttonStates[buttonIndex])
					continue;

				device->buttonStates[buttonIndex] = down;
				if (down) {
					if (Gamepad_buttonDownCallback != NULL) {
						Gamepad_buttonDownCallback(device, buttonIndex,
							currentTimestamp(),
							Gamepad_buttonDownContext);
					}
				} else {
					if (Gamepad_buttonUpCallback != NULL) {
						Gamepad_buttonUpCallback(device, buttonIndex,
							currentTimestamp(),
							Gamepad_buttonUpContext);
					}
				}
			}
		}
	}
}
