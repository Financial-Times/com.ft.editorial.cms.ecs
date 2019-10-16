#!/usr/bin/env bash

#USAGE
#./certname2hostname.sh certname

ENC_ENDPOINT="http://enc.svc.ft.com/enc"
NG_ENDPOINT="http://ftppm509-lvuk-uk-p/api/nodegroups"

declare -a HC_ARRAY
declare -A CH_ARRAY # Associative array to hold data such as CH_ARRAY[certname-first-octet]=hostname

buildAsssociativeArray() {
    i=1
    while [[ i -lt ${#HC_ARRAY[*]} ]]; do
        prev_i=`expr $i - 1` # 1 less than i value
        CH_ARRAY[${HC_ARRAY[${i}]}]="${HC_ARRAY[${prev_i}]}"
        i=`expr $i + 2` # increment i by 2
    done

}

buildHostAndCertnameArray() {
    for each in $(curl -s ${NG_ENDPOINT}/${NG} | jq '.|.nodes' | egrep 'host|certname' | cut -d : -f 2 | sed 's/ \|"\|,//g'); do
        HC_ARRAY+=(${each})
    done
}

displayInstructions() {
    echo "
    1. On Puppet Master ${HOSTNAME} run command 
        /usr/local/bin/puppet cert clean ${certname}
    2. Copy openssl downgrade package across 
        scp /opt/openssl-1.0.1e-48.el6_8.3.x86_64.rpm $(who | tail -1 | awk '{print $1}')@${CH_ARRAY[${certname_short}]}:/tmp
    3. Renew certificate on Puppet Agent
        ssh $(who | tail -1 | awk '{print $1}')@${CH_ARRAY[${certname_short}]}
        sudo su -
        yum downgrade -y /tmp/openssl-1.0.1e-48.el6_8.3.x86_64.rpm && rm -rf /etc/puppetlabs/puppet/ssl/* && puppet agent -t
    "
}



getNodegroupname() {
    wget -qO- ${ENC_ENDPOINT}/$1 | grep nodegroup | cut -d : -f 2 | sed 's/ //g'
}

usage() {
    echo "USAGE: $0 certname"
    echo "EXAMPLE: $0 app01.claro.int.cloud.ft.com"
    exit 1
}

test -z $1 && usage


certname=$1
NG=$(getNodegroupname $certname)
if [[ "$?" -eq "0" ]]; then
    echo "Certname $certname lives in nodegroup ${NG}"
else
    echo "Sorry, no certname ${certname} found in any nodegroup"
    exit 1
fi

buildHostAndCertnameArray
#echo ${HC_ARRAY[*]}
buildAsssociativeArray
#echo ${CH_ARRAY[*]}
certname_short="$(echo ${certname} | cut -d '.' -f 1)"
echo "certname ${certname} has hostname ${CH_ARRAY[${certname_short}]}"

test -z ${CH_ARRAY[${certname_short}]} || displayInstructions
