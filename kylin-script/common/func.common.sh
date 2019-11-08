#!/bin/bash
#***********************************************************************************
# **  创建日期: 2019-11-007
# **  编写人员: caihm
# **  功能描述: 通用函数
# **  All Rights Reserved.
#***********************************************************************************


#######################################################################
##功能：获取用户密码的KYLIN BASE字符串
function fn_kylinBaseUsernamePasswd()
{
UserName=$1
Password=$2
#baseUsernamePasswd=`python -c "import base64; print base64.standard_b64encode('$UserName:$Password')"`
baseUsernamePasswd=`echo -n "$UserName:$Password" | base64`
echo "$baseUsernamePasswd"

}


#######################################################################
##函数fn_header_print
##功能：打印工具头

function fn_header_print()
{
    echo "$PRINT_LINE_HEAD_TAIL [$IMEX_NAME$IMEX_INFO $IMEX_VERSION]" 2>&1|tee -a ${1}
    echo "$PRINT_LINE_HEAD_TAIL [$IMEX_COPYRIGHT]" 2>&1|tee -a ${1}
    echo "$PRINT_LINE_HEAD_TAIL [$IMEX_DEVELOPER]" 2>&1|tee -a ${1}
}


#######################################################################
##功能：作业错误

function fn_error_exit()
{
    if [[ "$1" != "" ]]; then
        echo "$PRINT_LINE_HEAD_TAIL $1" 
    fi
    runtime=`date '+%Y-%m-%d %H:%M:%S'`
    echo "$PRINT_LINE_HEAD_TAIL $runtime,作业错误！！！" 
    exit 1
}




#######################################################################
##函数fn_parse_input_date
##功能：解析输入日期或时间; 输出变量DAY_ID,MONTH_ID,YEAR_ID等
##参数可接受：20190102(天), 201901(月), 2019(年), 2019010203或'2019010203'(小时), 201901020310或'201901020310'(分), 20190102031022或'20190102031022'(秒)
##参数可接受：2019-01-02(天), 2019-01(月), 2019(年), '2019-01-02 03'(小时), '2019-01-02 03:10'(分), '2019-01-02 03:10:22'(秒)
function fn_parse_input_date()
{
local para=$1

local input_para_nodash=${para//:/}
local input_para_nodash=${input_para_nodash// /}
local input_para_nodash=${input_para_nodash//-/} #去空格-：，示例20190923

local para_len=$(expr length "$input_para_nodash")
local zx_type

if [ "$para_len" = 4 ];then
    # 2019(年)
    input_date_time_nodash="${input_para_nodash}0101000000"
    zx_type='year'
elif [ "$para_len" = 6 ];then
    # 201901(月)
    input_date_time_nodash="${input_para_nodash}01000000"
    zx_type='month'
elif [ "$para_len" = 8 ];then 
    # 20190102(天)
    input_date_time_nodash="${input_para_nodash}000000"
    zx_type='day'
elif [ "$para_len" = 10 ];then 
    # 2019010211(小时)
    input_date_time_nodash="${input_para_nodash}0000"
    zx_type='hour'
elif [ "$para_len" = 12 ];then 
    # 201901021122(分)
    input_date_time_nodash="${input_para_nodash}00"
    zx_type='minute'
elif [ "$para_len" = 14 ];then 
    # 20190102112233(秒)
    input_date_time_nodash="${input_para_nodash}"
    zx_type='second'
else
    input_date_time_nodash=$(date +"%Y%m%d000000" -d "-1day")
fi

local input_date_time="${input_date_time_nodash:0:4}-${input_date_time_nodash:4:2}-${input_date_time_nodash:6:2} ${input_date_time_nodash:8:2}:${input_date_time_nodash:10:2}:${input_date_time_nodash:12:2}"

#示例 input_date_time = '2019-09-23 03:48:25'
DAY_ID=${input_date_time:0:10}  # 2019-09-23
MONTH_ID=${input_date_time:0:7} # 2019-09
YEAR_ID=${input_date_time:0:4}  # 2019
HOUR_ID=${input_date_time:11:2}  # 03
MINUTE_ID=${input_date_time:14:2}  # 48
SECOND_ID=${input_date_time:17:2}  # 25
PRE_MONTH_ID=$(date -d "${MONTH_ID}-01  -1 month" +%Y-%m) # 2019-08
NEXT_MONTH_ID=$(date -d "${MONTH_ID}-01  1 month" +%Y-%m) # 2019-10
LASTDAY_ID=$(date -d "${DAY_ID} -1 day" +%Y-%m-%d) # 2019-09-22


local input_para_nodash=${para//:/}
local input_para_nodash=${input_para_nodash// /}
local input_para_nodash=${input_para_nodash//-/} #去空格-：，示例20190923
local input_para_nodash_date_less=${input_para_nodash:0:8} #20190923,201909,2019(前8或6,4位)


#示例 input_date_time_nodash = '2019-09-23 03:48:25'
DAY_ID2=${input_date_time_nodash:0:8} # 20190923
MONTH_ID2=${input_date_time_nodash:0:6} # 201909
YEAR_ID2=${input_date_time_nodash:0:4}  # 2019
HOUR_ID2=${input_date_time_nodash:8:2}  # 03
MINUTE_ID2=${input_date_time_nodash:10:2}  # 48
SECOND_ID2=${input_date_time_nodash:12:2}  # 25
PRE_MONTH_ID2=$(date -d "${MONTH_ID}-01  -1 month" +%Y%m) # 2019-08
NEXT_MONTH_ID2=$(date -d "${MONTH_ID}-01  1 month" +%Y%m) # 2019-10
LASTDAY_ID2=$(date -d "${DAY_ID} -1 day" +%Y%m%d) # 2019-09-22

}