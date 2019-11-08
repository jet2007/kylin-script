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


para_desc="入口参数1个: 1.cube_name "
if [[ "$1" = "" ]]; then
    fn_error_exit "$para_desc"
fi

baseUsernamePasswd=$(fn_kylinBaseUsernamePasswd "$KYLIN_USERNAME" "$KYLIN_PASSWORD")
  


kylin_api="http://$KYLIN_IP:$KYLIN_PORT/kylin/api"


# cube进行build
cube_job_build_info=$(curl -X PUT -H "Authorization: Basic $baseUsernamePasswd" -H 'Content-Type: application/json' -d '{"buildType":"BUILD"}'  $kylin_api/cubes/$cubeName/rebuild)
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

