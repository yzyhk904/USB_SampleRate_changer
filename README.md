## USB sample rate changer for Android devices on the fly

Under Magisk environment (<strong>"root name space mount mode" must be changed to "global"</strong> in the settings of Magisk Manager), this script changes the sample rate of the USB audio class driver on Android devices on the fly like Bluetooth LDAC or Windows mixer for <q><em>avoiding annoying SRC (Sample Rate Conversion) distorsions</em></q>. This script signals the audioserver on the "global" mount name space to try to reaload a USB audio policy configuration file generated by this script with a specified sample rate and bit depth, so the "root name space mount mode" change is needed.

* Usage: `sh /sdcard/USB_SampleRate_Changer/USB_SampleRate_Changer.sh [--reset] [--offload][--bypass-offload] [[44k|48k|88k|96k|176k|192k|353k|384k|706k|768k] [[16|24|32]]]`

  if you unpack the archive under "/sdcard" (Internal Storage). The arguments are a sample rate and a bit depth to which you like to change, respectively.
`--reset` option without arguments is for resetting its previous execution results. If `--offload` option (<strong>currently experimental</strong>) and arguments are specified, this script changes an audio policy configuration file for (USB) hardware offload. If `--bypass-offload` option (<strong>currently experimental</strong>) and arguments are specified, this script changes an audio policy configuration file for bypassing (USB) hardware offload and using a non-offload (usual or legacy) USB audio driver while the 3.5mm jack and internal speaker use a hardware offload driver.
* Note: "USB_SampleRate_Changer.sh" requires to unlock the USB audio class driver's limitation (upto 96kHz lock or 384kHz offload lock) if you like to specify greater than 96kHz or 384kHz (in case of offload). See my companion magisk module ["usb-samplerate-unlocker"](https://github.com/yzyhk904/usb-samplerate-unlocker) for non-offload drivers. Although you specify a high sample rate for this script execution, you cannot connect your device to a USB DAC with the sample rate unless the USB DAC supports the sample rate (the USB driver will limit the connecting sample rate downto its maximum sample rate).
* Tips: you can see the sample rate connecting to a USB DAC during music replaying by a command `cat /proc/asound/card1/pcm0p/sub0/hw_params` (for non- USB hardware offload drivers). You can also see mixer ("AudioFlinger") info by a command `dumpsys media.audio_flinger`. There are corresponding scripts in "extras" folder.

I recommend to use Script Manager or like for easiness.

## DISCLAIMER

* I am not responsible for any damage that may occur to your device, 
   so it is your own choice to attempt this script.

## Change logs

# v1.0
* Initial Release

# v1.1
* Recent higher sample rates added

# V1.2
* (USB) hardware offload support added (currently experimental)
* Bypass (USB) offload (using a non- USB hardware offload driver while the 3.5mm jack and internal speaker use a hardware offload driver) support added (currently experimental)

# V1.3
* Selinux enforcing mode bug fixed. Now this script can be used under both selinux enforcing and permissive modes
