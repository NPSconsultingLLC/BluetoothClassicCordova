/*global cordova*/
module.exports = {

	/**
	 * Gets the bluetooth firmware version available in this plugin for reflashing
	 * @param {string} id The identifier of the device to connect to
	 * @param {function} success A function called when connection succeeds
	 * @param {function} failure A function called when connection fails
	 */
	version: function (success, failure) {
        cordova.exec(success, failure, "BluetoothDongle", "version", []);
    },
	
	/**
	 * Connects to a bluetooth device
	 * @param {string} id The identifier of the device to connect to
	 * @param {function} success A function called when connection succeeds
	 * @param {function} failure A function called when connection fails
	 */
    connect: function (id, success, failure) {
        cordova.exec(success, failure, "BluetoothDongle", "connect", [id]);
    },

	/**
	 * Disconnects to a bluetooth device
	 * @param {function} success A function called when disconnection succeeds
	 * @param {function} failure A function called when disconnection fails
	 */
    disconnect: function (success, failure) {
        cordova.exec(success, failure, "BluetoothDongle", "disconnect", []);
    },

	/**
	 * Gets a list of paired devices.
	 * @param {function} success A function called when a list of available devices is gathered
	 * @param {function} failure A function called when enumerating a list of devices fails
	 */
    devices: function (success, failure) {
        cordova.exec(success, failure, "BluetoothDongle", "list", []);
    },

	/**
	 * Determines whether a connection is active
	 * @param {function} success A function called if there is a connection
	 * @param {function} failure A function called if there is no connection
	 */
    isConnected: function (success, failure) {
        cordova.exec(success, failure, "BluetoothDongle", "isConnected", []);
    },

	/**
	 * Sends a request PGN to the bluetooth dongle, i.e "B0 5E [length] F9 [data] [checksum] EB"
	 * @param {function} data An array containing just the data portion of PGN request.
	 * @param {function} success A function called if the write succeeds
	 * @param {function} failure A function called if the write fails
	 */
    write: function (data, success, failure) {
        cordova.exec(success, failure, "BluetoothDongle", "write", [data]);
    },

	/**
	 * Subscribes to any streaming data read from bluetooth device
	 * @param {function} success A function called when data is successfully read
	 * @param {function} failure A function called if the subscribe fails
	 */
    subscribe: function (success, failure) {
        cordova.exec(success, failure, "BluetoothDongle", "subscribe", []);
    },
	
	/**
	 * Updates the firmware for the currently-connected bluetooth dongle 
	 * @param {function} complete A function called if reflashing is 100% complete
	 * @param {function} failure A function called if reflashing has failed
	 * @param {function} success A function called repeatedly indicating progress
	 */
	reflash: function(complete, failure, progress) {
		var success = function(result) {
			// If we are complete...
			if (result.phase == 1) {
				// Notify js reflash was successful.
				complete();
			} else {
				// Still in progress. Notify of percentage.
				progress(result.percent);
			}
		};
		
		cordova.exec(success, failure, "BluetoothDongle", "reflash", []);
	}
};
