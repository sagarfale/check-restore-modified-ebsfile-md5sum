## Author : Sagar Fale 
## Date :  30-Jan-2023
## usage : sh check-restore-modified-ebsfile-md5sum.sh <md5sum_value>

#!/bin/bash


scripts_base=/home/applmgr/scripts
## specify-emaid-here
MAIL_LIST=test@test.com
temp_var=`date +"bkp-%d%b%Y_%H%M%S"`
HOST=`hostname`

> ${scripts_base}/files_list.log 

## Setting the env 
## make required changes here ( specify the path here )

. /XXXXX/applmgr/EBSapps.env RUN
filename_run="$FMW_HOME/Oracle_EBS-app1/common/scripts/testfile.text"
. /XXXXX/applmgr/EBSapps.env patch
filename_patch="$FMW_HOME/Oracle_EBS-app1/common/scripts/testfile.text"


ls -ltr ${filename_run} ${filename_patch}

m1="$1"

sendemail_notify()
   {
      (
         echo "Subject: ${tempvalue}"
         echo "TO: $MAIL_LIST"
         echo "FROM: prod@itc-client.com"
         echo "MIME-Version: 1.0"
         echo "Content-Type: text/html"
         echo "Content-Disposition: inline"
         cat ${attachement_name}
      )  | /usr/sbin/sendmail $MAIL_LIST -t
}

convert_text_to_html()
{
    awk 'BEGIN {
        split("200,2000,150,150,", widths, ",")
        print "<style>\
            .my_table {font-size:8.0pt; font-family:\"Verdana\",\"sans-serif\"; border-bottom:3px double black; border-collapse: collapse; }\n\
            .my_table tr.header{border-bottom:3px double black;}\n\
            .my_table th {text-align: left;}\
        </style>"
        print "<table class=\"my_table\">"
    }
    NR == 1{
        print "<tr class=\"header\">"
        tag = "th"
    }
    NR != 1{
        print "<tr>"
        tag = "td"
    }
    {
        for(i=1; i<=NF; ++i) print "<" tag " width=\"" widths[i] "\">" $i "</" tag ">"
        print "</tr>"
    }
    END { print "</table>"}'  ${scripts_base}/files_list.log   > ${scripts_base}/files_list.html
}

m2=$(md5sum "${filename_run}" | cut -d' ' -f1)
if [ "$m1" != "$m2" ] ; then
    echo "ERROR: File has changed!" >&2 
    
    ## Taking backup of the file
    cp ${filename_run}  ${filename_run}_${temp_var}

    ## copying the file from patch_top to run_top
    cp -rf ${filename_patch} ${filename_run}
    
    tempvalue="Attention : $HOST txkFNDWRR.pl changes"
    ls -ltr ${filename_run}* | awk -F " " '{print $8,$9}' > ${scripts_base}/files_list.log 
    convert_text_to_html
    attachement_name=`echo ${scripts_base}/files_list.html`
    sendemail_notify ${attachement_name}
    exit 1
fi




