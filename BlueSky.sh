#!/bin/bash

parameters="${1}${2}${3}${4}${5}${6}${7}${8}${9}"

Escape_Variables()
{
	text_progress="\033[38;5;113m"
	text_success="\033[38;5;113m"
	text_warning="\033[38;5;221m"
	text_error="\033[38;5;203m"
	text_message="\033[38;5;75m"

	text_bold="\033[1m"
	text_faint="\033[2m"
	text_italic="\033[3m"
	text_underline="\033[4m"

	erase_style="\033[0m"
	erase_line="\033[0K"

	move_up="\033[1A"
	move_down="\033[1B"
	move_foward="\033[1C"
	move_backward="\033[1D"
}

Parameter_Variables()
{
	if [[ $parameters == *"-v"* || $parameters == *"-verbose"* ]]; then
		verbose="1"
		set -x
	fi
}

Path_Variables()
{
	script_path="${0}"
	directory_path="${0%/*}"

	patch_resources_path="$directory_path/resources/patch"
	revert_resources_path="$directory_path/resources/revert"
}

Input_Off()
{
	stty -echo
}

Input_On()
{
	stty echo
}

Output_Off()
{
	if [[ $verbose == "1" ]]; then
		"$@"
	else
		"$@" &>/dev/null
	fi
}

Check_Environment()
{
	echo -e ${text_progress}"> Checking system environment."${erase_style}
	if [ ! -d /Install\ *.app ]; then
		echo -e ${move_up}${erase_line}${text_success}"+ System environment check passed."${erase_style}
	fi
	if [ -d /Install\ *.app ]; then
		echo -e ${text_error}"- System environment check failed."${erase_style}
		echo -e ${text_message}"/ This tool is not supported in the Recovery environment."${erase_style}
		Input_On
		exit
	fi
}

Check_Root()
{
	echo -e ${text_progress}"> Checking for root permissions."${erase_style}
	if [[ $(whoami) == "root" ]]; then
		root_check="passed"
		echo -e ${move_up}${erase_line}${text_success}"+ Root permissions check passed."${erase_style}
	fi
	if [[ ! $(whoami) == "root" ]]; then
		root_check="failed"
		echo -e ${text_error}"- Root permissions check failed."${erase_style}
		echo -e ${text_message}"/ Run this tool with root permissions."${erase_style}
		Input_On
		exit
	fi
}

Check_SIP()
{
	echo -e ${text_progress}"> Checking System Integrity Protection status."${erase_style}
	if [[ $(csrutil status | grep status) == *disabled* || $(csrutil status | grep status) == *unknown* ]]; then
		echo -e ${move_up}${erase_line}${text_success}"+ System Integrity Protection status check passed."${erase_style}
	else
		echo -e ${text_error}"- System Integrity Protection status check failed."${erase_style}
		echo -e ${text_message}"/ Run this tool with System Integrity Protection disabled."${erase_style}
		Input_On
		exit
	fi
}

Check_Resources()
{
	echo -e ${text_progress}"> Checking for resources."${erase_style}
	if [[ -d "$patch_resources_path" && -d "$revert_resources_path" ]]; then
		resources_check="passed"
		echo -e ${move_up}${erase_line}${text_success}"+ Resources check passed."${erase_style}
	fi
	if [[ ! -d "$patch_resources_path" || ! -d "$revert_resources_path" ]]; then
		resources_check="failed"
		echo -e ${text_error}"- Resources check failed."${erase_style}
	fi
}

Check_Internet()
{
	echo -e ${text_progress}"> Checking for internet connectivity."${erase_style}
	if [[ $(ping -c 5 www.google.com) == *transmitted* && $(ping -c 5 www.google.com) == *received* ]]; then
		echo -e ${move_up}${erase_line}${text_success}"+ Internet connectivity check passed."${erase_style}
		internet_check="passed"
	else
		echo -e ${text_error}"- Internet connectivity check failed."${erase_style}
		internet_check="failed"
	fi
}

Check_Options()
{
	if [[ $resources_check == "failed" && $internet_check == "failed" ]]; then
		echo -e ${text_error}"- Resources check and internet connectivity check failed"${erase_style}
		echo -e ${text_message}"/ Run this tool with the required resources and/or an internet connection."${erase_style}
		Input_On
		exit
	fi
}

Input_Volume()
{
	echo -e ${text_message}"/ What volume would you like to use?"${erase_style}
	echo -e ${text_message}"/ Input a volume name."${erase_style}
	for volume_path in /Volumes/*; do 
		volume_name="${volume_path#/Volumes/}"
		if [[ ! "$volume_name" == com.apple* ]]; then
			echo -e ${text_message}"/     ${volume_name}"${erase_style} | sort -V
		fi
	done
	Input_On
	read -e -p "/ " volume_name
	Input_Off

	volume_path="/Volumes/$volume_name"

	if [[ $(diskutil info "$volume_name"|grep "Mount Point") == *"/" && ! $(diskutil info "$volume_name"|grep "Mount Point") == *"/Volumes" ]]; then
		sudo mount -uw /
	fi
}

Check_Volume_Version()
{
	echo -e ${text_progress}"> Checking system version."${erase_style}	
	volume_version="$(defaults read "$volume_path"/System/Library/CoreServices/SystemVersion.plist ProductVersion)"
	volume_version_short="$(defaults read "$volume_path"/System/Library/CoreServices/SystemVersion.plist ProductVersion | cut -c-5)"

	volume_build="$(defaults read "$volume_path"/System/Library/CoreServices/SystemVersion.plist ProductBuildVersion)"
	echo -e ${move_up}${erase_line}${text_success}"+ Checked system version."${erase_style}
}

Prepare_Options()
{
	if [[ $resources_check == "passed" ]]; then
		Prepare_Resources
	fi
	if [[ $resources_check == "failed" ]]; then
		Download_Resources
	fi
}

Check_Volume_Support()
{
	if [[ ! -d "$patch_resources_path"/SkyLight/${!skylight_folder_version} || !  -d "$revert_resources_path"/SkyLight/${!skylight_folder_version} ]]; then
		echo -e ${text_error}"- System support check failed."${erase_style}
		echo -e ${text_message}"/ Run this tool on a supported system."${erase_style}
		Input_On
		exit
	fi

	echo -e ${text_progress}"> Checking system support."${erase_style}
	if [[ $volume_version_short == "10.1"[4-5] ]]; then
		echo -e ${move_up}${erase_line}${text_success}"+ System support check passed."${erase_style}
	else
		echo -e ${text_error}"- System support check failed."${erase_style}
		echo -e ${text_message}"/ Run this tool on a supported system."${erase_style}
		Input_On
		exit
	fi
}

Check_Graphics_Card()
{
	if [[ "$(system_profiler SPDisplaysDataType | grep Metal)" == *"Supported"* ]]; then
		echo -e ${text_warning}"! Metal graphics card detected."${erase_style}
		echo -e ${text_warning}"! These patches are not for Metal cards."${erase_style}
		echo -e ${text_message}"/ Input an operation number."${erase_style}
		echo -e ${text_message}"/     1 - Abort"${erase_style}
		echo -e ${text_message}"/     2 - Proceed"${erase_style}
		Input_On
		read -e -p "/ " operation_graphis_card
		Input_Off

		if [[ $operation_graphis_card == "1" ]]; then
			Input_On
			exit
		fi
	fi
}

Input_Operation()
{
	echo -e ${text_message}"/ What operation would you like to run?"${erase_style}
	echo -e ${text_message}"/ Input an operation number."${erase_style}
	echo -e ${text_message}"/     1 - Install SkyLight patch"${erase_style}
	echo -e ${text_message}"/     2 - Remove SkyLight patch"${erase_style}
	Input_On
	read -e -p "/ " operation
	Input_Off

	if [[ $operation == "1" ]]; then
		Patch_SkyLight
	fi
	if [[ $operation == "2" ]]; then
		Remove_SkyLight
	fi
}

Prepare_Resources()
{
	echo -e ${text_progress}"> Preparing local resources."${erase_style}
	chmod +x "$directory_path"/resources/skylight_var.sh
	source "$directory_path"/resources/skylight_var.sh
	echo -e ${move_up}${erase_line}${text_success}"+ Prepared local resources."${erase_style}
}

Download_Resources()
{
	echo -e ${text_progress}"> Downloading internet resources."${erase_style}
	curl -L -s -o /tmp/bluesky.zip https://github.com/rmc-team/bluesky/archive/master.zip
	unzip -q /tmp/bluesky.zip -d /tmp

	patch_resources_path="/tmp/bluesky-master/resources/patch"
	revert_resources_path="/tmp/bluesky-master/resources/revert"

	chmod +x /tmp/bluesky-master/resources/skylight_var.sh
	source /tmp/bluesky-master/resources/skylight_var.sh
	echo -e ${move_up}${erase_line}${text_success}"+ Downloaded internet resources."${erase_style}
}

Patch_SkyLight()
{
	echo -e ${text_progress}"> Installing SkyLight patch."${erase_style}
	if [[ $volume_version_short == "10.14" ]]; then
		rm "$volume_path"/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight
		cp "$patch_resources_path"/SkyLight/${!skylight_folder_version}/SkyLight "$volume_path"/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A
	fi

	if [[ $volume_version_short == "10.15" ]]; then
		rm "$volume_path"/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLightOriginal
		cp "$patch_resources_path"/SkyLight/${!skylight_folder_version}/SkyLightOriginal "$volume_path"/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A
	fi
	echo -e ${move_up}${erase_line}${text_success}"+ Installed SkyLight patch."${erase_style}
}

Remove_SkyLight()
{
	echo -e ${text_progress}"> Removing SkyLight patch."${erase_style}
	if [[ $volume_version_short == "10.14" ]]; then
		rm "$volume_path"/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight
		cp "$revert_resources_path"/SkyLight/${!skylight_folder_version}/SkyLight "$volume_path"/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A
	fi

	if [[ $volume_version_short == "10.15" ]]; then
		rm "$volume_path"/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLightOriginal
		cp "$revert_resources_path"/SkyLight/${!skylight_folder_version}/SkyLightOriginal "$volume_path"/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A
	fi
	echo -e ${move_up}${erase_line}${text_success}"+ Removed SkyLight patch."${erase_style}
}

Patch_HIToolbox()
{
	echo -e ${text_progress}"> Installing HIToolbox patch."${erase_style}
	if [[ $volume_version_short == "10.14" ]]; then
		rm "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/A/HIToolbox
		cp "$patch_resources_path"/HIToolbox/${!hitoolbox_folder_version}/HIToolbox "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/A
	fi

	if [[ $volume_version_short == "10.15" ]]; then
		rm "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/A/HIToolbox
		cp "$patch_resources_path"/HIToolbox/${!hitoolbox_folder_build}/HIToolbox "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/A
	fi
	echo -e ${move_up}${erase_line}${text_success}"+ Installed HIToolbox patch."${erase_style}
}

Remove_HIToolbox()
{
	echo -e ${text_progress}"> Removing HIToolbox patch."${erase_style}
	if [[ $volume_version_short == "10.14" ]]; then
		rm "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/A/HIToolbox
		cp "$revert_resources_path"/HIToolbox/${!hitoolbox_folder_version}/HIToolbox "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/A
	fi

	if [[ $volume_version_short == "10.15" ]]; then
		rm "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/A/HIToolbox
		cp "$revert_resources_path"/HIToolbox/${!hitoolbox_folder_build}/HIToolbox "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework/Versions/A
	fi
	echo -e ${move_up}${erase_line}${text_success}"+ Removed HIToolbox patch."${erase_style}
}

Repair()
{
	chown -R 0:0 "$@"
	chmod -R 755 "$@"
}

Repair_Permissions()
{
	echo -e ${text_progress}"> Repairing permissions."${erase_style}
	Repair "$volume_path"/System/Library/PrivateFrameworks/SkyLight.framework
	Repair "$volume_path"/System/Library/Frameworks/Carbon.framework/Frameworks/HIToolbox.framework
	echo -e ${move_up}${erase_line}${text_success}"+ Repaired permissions."${erase_style}
}

Restart()
{
	echo -e ${text_progress}"> Removing temporary files."${erase_style}
	Output_Off rm /tmp/bluesky.zip
	Output_Off rm -R /tmp/bluesky-master
	echo -e ${move_up}${erase_line}${text_success}"+ Removed temporary files."${erase_style}

	if [[ $(diskutil info "$volume_name"|grep "Mount Point") == *"/" && ! $(diskutil info "$volume_name"|grep "Mount Point") == *"/Volumes" ]]; then
		echo -e ${text_message}"/ Your machine will restart soon."${erase_style}
		echo -e ${text_message}"/ Thank you for using BlueSky."${erase_style}
		reboot
	else
		echo -e ${text_message}"/ Thank you for using BlueSky."${erase_style}
		Input_On
		exit
	fi
}

Input_Off
Escape_Variables
Parameter_Variables
Path_Variables
Check_Environment
Check_Root
Check_SIP
Check_Resources
Check_Internet
Check_Options
Input_Volume
Check_Volume_Version
Prepare_Options
Check_Volume_Support
Check_Graphics_Card
Input_Operation
Repair_Permissions
Restart