# Masking_Script_Delphix

This Script is used to perform automated masking via Hooks by Delphix on systems that are not supported by DXMC.

The OS supported by DXMC are (RedHat, Windows and OSX)

Link for use the original DXMC: https://github.com/delphix/dxm-toolkit

## Prerequisites
To run the script, you need a jq library installed.

```
sudo apt-get install jq
```

Or

```
sudo yum install jq
```
Or

```
sudo zypper install jq
```

## Configuring
To execute the script you must configure the variables according to your environment.

```
IP_ENGINE_MASK='192.168.0.1'
NM_ENV='ENVNAME'
JOB_NAME=('MSK_JOB1' 'MSK_JOB2') 
USR=Admin
PWD='Admin-12'
```

## Executing
To run the script just run the following command

```shell
bash -x ./script.sh
```
