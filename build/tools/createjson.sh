#!/bin/bash
#
# Copyright (C) 2019-2022 crDroid Android Project
# Copyright (C) 2024 risingOS Android Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#$1=TARGET_DEVICE, $2=PRODUCT_OUT, $3=FILE_NAME, $4=RISING_VERSION, $5=RISING_CODENAME, $6=RISING_PACKAGE_TYPE, $7=RISING_RELEASE_TYPE
existingOTAjson=./vendor/official_devices/OTA/device/$6/$1.json
output=$2/$1.json
major_version=$(echo $4 | cut -d'.' -f1)

#cleanup old file
if [ -f $output ]; then
	rm $output
fi

echo "Generating JSON file data for OTA support..."

if [ -f $existingOTAjson ]; then
	#get data from already existing device json
	#there might be a better way to parse json yet here we try without adding more dependencies like jq
	maintainer=`grep -n "\"maintainer\"" $existingOTAjson | cut -d ":" -f 3 | sed 's/"//g' | sed 's/,//g' | xargs`
	oem=`grep -n "\"oem\"" $existingOTAjson | cut -d ":" -f 3 | sed 's/"//g' | sed 's/,//g' | xargs`
	device=`grep -n "\"device\"" $existingOTAjson | cut -d ":" -f 3 | sed 's/"//g' | sed 's/,//g' | xargs`
	filename=$3
	download="https://sourceforge.net/projects/risingos-revived/files/${major_version}.x/$6/$1/$filename/download"
	version=`echo $4-$5`
	buildprop=$2/system/build.prop
	linenr=`grep -n "ro.system.build.date.utc" $buildprop | cut -d':' -f1`
	timestamp=`sed -n $linenr'p' < $buildprop | cut -d'=' -f2`
	md5=`md5sum "$2/$3" | cut -d' ' -f1`
	sha256=`sha256sum "$2/$3" | cut -d' ' -f1`
	size=`stat -c "%s" "$2/$3"`
	buildtype=$7
	forum=`grep -n "\"forum\"" $existingOTAjson | cut -d ":" -f 4 | sed 's/"//g' | sed 's/,//g' | xargs`
	if [ ! -z "$forum" ]; then
		forum="https:"$forum
	fi
	recovery=`grep -n "\"recovery\"" $existingOTAjson | cut -d ":" -f 4 | sed 's/"//g' | sed 's/,//g' | xargs`
	if [ ! -z "$recovery" ]; then
		recovery="https:"$recovery
	fi
	paypal=`grep -n "\"paypal\"" $existingOTAjson | cut -d ":" -f 4 | sed 's/"//g' | sed 's/,//g' | xargs`
	if [ ! -z "$paypal" ]; then
		paypal="https:"$paypal
	fi
	telegram=`grep -n "\"telegram\"" $existingOTAjson | cut -d ":" -f 4 | sed 's/"//g' | sed 's/,//g' | xargs`
	if [ ! -z "$telegram" ]; then
		telegram="https:"$telegram
	fi

	echo '{
	"response": [
		{
			"maintainer": "'$maintainer'",
			"oem": "'$oem'",
			"device": "'$device'",
			"filename": "'$filename'",
			"download": "'$download'",
			"timestamp": '$timestamp',
			"md5": "'$md5'",
			"sha256": "'$sha256'",
			"size": '$size',
			"version": "'$version'",
			"buildtype": "'$buildtype'",
			"forum": "'$forum'",
			"recovery": "'$recovery'",
			"paypal": "'$paypal'",
			"telegram": "'$telegram'"
		}
	]
}' >> $output
	cat $output
else
	filename=$3
	version=$4-$5
	buildprop=$2/system/build.prop
	linenr=`grep -n "ro.system.build.date.utc" $buildprop | cut -d':' -f1`
	timestamp=`sed -n $linenr'p' < $buildprop | cut -d'=' -f2`
	md5=`md5sum "$2/$3" | cut -d' ' -f1`
	sha256=`sha256sum "$2/$3" | cut -d' ' -f1`
	size=`stat -c "%s" "$2/$3"`

	echo '{
	"response": [
		{
			"maintainer": "''",
			"oem": "''",
			"device": "''",
			"filename": "'$filename'",
			"download": "",
			"timestamp": '$timestamp',
			"md5": "'$md5'",
			"sha256": "'$sha256'",
			"size": '$size',
			"version": "'$version'",
			"buildtype": "''",
			"forum": "''",
			"recovery": "''",
			"paypal": "''",
			"telegram": "''"
		}
	]
}' >> $output
	cat $output
	echo 'There is no official support for this device yet'
	echo 'Consider adding official support by reading the documentation at https://github.com/RisingOS-Revived/official_devices/blob/main/README.md'
fi

echo ""
