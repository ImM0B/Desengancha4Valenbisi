#!/usr/bin/bash

function ctrl_c(){
        echo -e "${redColour}\n[❗] Saliendo...${endColour}\n"
    tput cnorm 2>/dev/null ; exit 1
}

trap ctrl_c INT

#Colores
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

#Variables globales
getTakn="https://api.cyclocity.fr/auth/environments/PRD/client_tokens"
key='{"code":"vls.web.valence:PRD","key":"5baec26027069c8ff4358f7f8faf43e0ce2c1e32f6d919cc6006a4ee6bfdf5ac"}'
mail=$1 ; pin=$2; station=$3; stand=$4
getAuthCode="https://api.cyclocity.fr/identities/contracts/valence/users/login?email=$mail&password=$pin&redirect_uri=https%3A%2F%2Fwww.valenbisi.es%2Fopenid_connect_login%2F"
getUserId="https://api.cyclocity.fr/contracts/valence/accounts/$mail/id"
calcBici="https://api.cyclocity.fr/contracts/valence/bikes?stationNumber=$station"

#USO
usage() {
    echo -e "${grayColour}Uso: ${redColour}$0 ${yellowColour}[opciones]${endColour}"
    echo -e "${grayColour}Opciones:${endColour}"
    echo -e "${yellowColour}  --help${purpleColour}                      Muestra esta ayuda ${endColour}"
    echo -e "${yellowColour}  mail${purpleColour}                        Indica el mail de la cuenta.${endColour} Ej: valenbisi@gmail.com"
    echo -e "${yellowColour}  pin/archivo refreshToken${purpleColour}    Indica el pin de la cuenta o en su defecto el path del archivo con el refreshToken.${endColour} Ej: 123456 / .valenbisi@gmail.com_refresh${endColour}"
    echo -e "${yellowColour}  nº estación${purpleColour}                 Indica el número de la estación donde está la bici a sacar.${endColour} Ej: 36 ${endColour}"
    echo -e "${yellowColour}  nº stand${purpleColour}                    Indica el stand donde está la bici a sacar.${endColour} Ej: 5 ${endColour}"
    exit 1
}

if [[ $# -eq 0 || "$1" == "--help" ]]; then
    usage
fi

#MAIN
echo -e "${grayColour}[🔄] Obteniendo token Takn ... ${endColour}"
res=$(curl -X POST -s "$getTakn" -d "$key" -x "socks5://127.0.0.1:9050" -H 'Content-Type: application/json' 2>&1 )
taknToken=$(echo $res | jq -r '.accessToken')
if [ -n $taknToken ] ; then echo -e "\t${greenColour}[🪙] Token Takn obtenido.${endColour}"; else echo -e "${redColour}[❌] Imposible obtener Token Takn.${endColour}";exit 1; fi

echo -e "${grayColour}[🔄] Obteniendo Auth Code ... ${endColour}"
res=$(curl -s -o /dev/null -I -w "%{redirect_url}\n" "$getAuthCode" -H "Authorization: Taknv1 $taknToken" -x "socks5://127.0.0.1:9050" -H 'Connection: keep-alive' )
authCode=$(echo $res| tr '=' ' '|awk '{print $2}')
if [ -n $authCode ] ; then echo -e "\t${greenColour}[🔑] Auth Code obtenido.${endColour}"; else echo -e "${redColour}[❌] Imposible obtener Auth Code.${endColour}";exit 1; fi

echo -e "${grayColour}[🔄] Obteniendo tokens Refresh y Access ... ${endColour}"
getRefreshAndAccess="https://api.cyclocity.fr/identities/token?grant_type=authorization_code&code=$authCode&redirect_uri=https%3A%2F%2Fwww.valenbisi.es%2Fopenid_connect_login%2F"
res=$(curl -X POST -s "$getRefreshAndAccess" -x "socks5://127.0.0.1:9050" -H "Authorization: Taknv1 $taknToken" -d '{"scope":"openid"}' -H 'Content-Type: application/json' 2>&1 )
refreshToken=$(echo $res | jq -r '.refresh_token')
if [ -n $refreshToken ] ; then echo -e "\t${greenColour}[🪙] Refresh Token obtenido.${endColour}"; else echo -e "${redColour}[❌] Imposible obtener Refresh Token.${endColour}";exit 1; fi

echo $refreshToken > ".${mail}_refresh"
echo -e "\t${yellowColour}[💾] Refresh Token guardado.${endColour}"
accessToken=$(echo $res | jq -r '.access_token')
if [ -n $accessToken ] ; then echo -e "\t${greenColour}[🪙] Access Token obtenido.${endColour}"; else echo -e "${redColour}[❌] Imposible obtener Access Token.${endColour}";exit 1; fi

echo -e "${grayColour}[🔄] Obteniendo Id de Usuario ... ${endColour}"
res=$(curl -X GET -s "$getUserId" -x "socks5://127.0.0.1:9050" -H "Authorization: Taknv1 $taknToken" -H "Identity: $accessToken" 2>&1 )
userId=$(echo $res| tr -d '"')
if [ -n $userId ] ; then echo -e "\t${greenColour}[👤] Id de Usuario obtenido.${endColour}"; else echo -e "${redColour}[❌] Imposible obtener Id de Usuario.${endColour}";exit 1; fi
echo $userId > ".${mail}_userId"
echo -e "\t${yellowColour}[💾] User Id guardado.${endColour}"

echo -e "${grayColour}[🔄] Obteniendo Id de subscripción ... ${endColour}"
getSubId="https://api.cyclocity.fr/contracts/valence/accounts/$userId/subscriptions?periods=CURRENT&typeList=ST&typeList=LT&isLocked=false"
res=$(curl -X GET -s "$getSubId" -x "socks5://127.0.0.1:9050" -H "Authorization: Taknv1 $taknToken" -H "Identity: $accessToken" -H "Accept: application/vnd.subscription.v6+json" 2>&1 )
subId=$(echo $res | jq -r '.[0].periods[0].subscriptionId')
if [ -n $subId ] ; then echo -e "\t${greenColour}[👤] Id de Subscripción obtenido.${endColour}"; else echo -e "${redColour}[❌] Imposible obtener Id de Subscripción.${endColour}";exit 1; fi

echo -e "${grayColour}[🔄] Calculando número de bici ... ${endColour}"
res=$(curl -X GET -s "$calcBici" -x "socks5://127.0.0.1:9050" -H "Authorization: Taknv1 $taknToken" -H "Accept: application/vnd.bikes.v3+json" 2>&1 )
bici=$(echo $res | jq . | jq --arg sn "$stand" -r '.[] | select(.standNumber == ($sn | tonumber)) | .number')
if [ -n $bici ] ; then echo -e "\t${greenColour}[🚲] Número de bici obtenido.${endColour}"; else echo -e "${redColour}[❌] Imposible obtener número de bici de esa combinación estación - stand.${endColour}";exit 1; fi

echo -e "${grayColour}[🔄] Sacando bici ... ${endColour}"
sacarBici="https://api.cyclocity.fr/contracts/valence/accounts/$userId/subscriptions/$subId/trips"
biciJson="{\"stationNumber\":$station,\"standNumber\":$stand,\"bikeNumber\":$bici,\"typeFrom\":\"SMARTPHONE\"}"
res=$(curl -X POST -s "$sacarBici" -x "socks5://127.0.0.1:9050" -H "Authorization: Taknv1 $taknToken" -H "Identity: $accessToken" -H "Content-Type: application/vnd.trip.v5+json" -d "$biciJson" 2>&1 )
if echo "$res" | grep -q '"transactionState"'; then echo -e "\t${greenColour}[🏆] Bici sacada con éxito.${endColour}"; else echo -e "${redColour}[❌] Imposible sacar la bici.${endColour}";exit 1; fi