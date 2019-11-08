#!/bin/bash  
  
###################################################################################################################  
#Kylin增量build cube  

set -e
source "$HOME/.bashrc"
source "$HOME/.bash_profile"
curDir=$(cd `dirname $0`; pwd)
scriptName=`basename $0`
cd ${curDir}


source ../etc/tool.conf
source ../common/func.common.sh


cubeName="$1"    # CUBE NAME
startDate="$2"   # 日期,示例2012-09-01
endDate="$3"     # 日期,示例2012-09-01

para_desc="入口参数3个: 1.cube_name; 2.startDate; 3.endDate"
if [[ "$3" = "" ]]; then
    fn_error_exit "$para_desc"
fi

baseUsernamePasswd=$(fn_kylinBaseUsernamePasswd "$KYLIN_USERNAME" "$KYLIN_PASSWORD")
  
kylinMinusTime=$((8 * 60 * 60 * 1000)) #kyin提前8小时，所以需要偏移8小时
onedayTime=$((24 * 60 * 60 * 1000)) #24小时的毫秒数
startTimeStamp=`date -d "$startDate 00:00:00" +%s`  
startTimeStampMs=$(($startTimeStamp*1000)) #将current转换为时间戳，精确到毫秒  
endTimeStamp=`date -d "$endDate 00:00:00" +%s`  
endTimeStampMs=$(($endTimeStamp*1000)) #将current转换为时间戳，精确到毫秒  
startTime=$(($startTimeStampMs + $kylinMinusTime)) 
endTime=$(($endTimeStampMs + $kylinMinusTime))  

kylin_api="http://$KYLIN_IP:$KYLIN_PORT/kylin/api"


# cube进行build
cube_job_build_info=$(curl -X PUT -H "Authorization: Basic $baseUsernamePasswd" -H 'Content-Type: application/json' -d '{"startTime":'$startTime', "endTime":'$endTime', "buildType":"BUILD"}' $kylin_api/cubes/$cubeName/rebuild)
cube_job_code=$(echo $cube_job_build_info | jq '.code')
cube_job_code=${cube_job_code//\"/}

# 是否已经在build中
if [[ "$cube_job_code" = "999" ]]; then
    cube_job_exception=$(echo $cube_job_build_info | jq '.exception')
    cube_job_exception=${cube_job_exception//\"/}
    fn_error_exit "[exception:$cube_job_exception]"  # 已在build中，作业失败
fi
cube_job_id=$(echo $cube_job_build_info | jq '.uuid')
cube_job_name=$(echo $cube_job_build_info | jq '.name')
cube_job_id=${cube_job_id//\"/}
cube_job_name=${cube_job_name//\"/}



#作业执行状态
cube_job_status=""
condition="false"
sleep_time=10
while [ "${condition}" = "false" ]
do
   cube_job_run_info=$(curl -X GET -H "Authorization: Basic $baseUsernamePasswd" -H 'Content-Type: application/json'  $kylin_api/jobs/$cube_job_id)
   cube_job_status=$(echo $cube_job_run_info | jq '.job_status')
   cube_job_status=$(echo $cube_job_run_info | jq '.job_status')
   cube_job_status=${cube_job_status//\"/}
   cube_job_process=$(echo $cube_job_run_info | jq '.progress')
   echo "$PRINT_LINE_HEAD_TAIL [cube=$cubeName,job=$cube_job_name,status=$cube_job_status,progress=$cube_job_process"
   if [ "${cube_job_status}" = "FINISHED"  ];then
       condition="true"
   elif [[ "${cube_job_status}" = "ERROR" ]] || [[ "${cube_job_status}" = "DISCARDED" ]] || [[ "${cube_job_status}" = "KILLED" ]] ; then
       condition="error" # 异常错误
   fi
   sleep $sleep_time
done

if [[ "$condition" = "error" ]]; then
    fn_error_exit
fi

