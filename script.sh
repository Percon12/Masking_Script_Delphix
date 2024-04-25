#!/bin/bash
#####   NOME:              StartMask
#####   VERSÃO:            1.0
#####   DESCRIÇÃO:         Script para realizar o Start no Mascaramento
#####   DATA DA CRIAÇÃO:           24/04/2024
#####   ESCRITO POR:       Ricardo Amaral / Felipe Andrade
#####   E-MAIL:            ricardo.amaral@tgvtec.com.br / felipe.andrade@tgvtec.com.br

IP_ENGINE_MASK='107.23.187.192'
NM_ENV='SQLSERVER2022'
#A Variavel JOB_NAME deve ser declarada com espaço e ' Exemplo JOB_NAME=('A' 'B')
JOB_NAME=('MSK_ADVENTURE_SALES' 'MSK_ADVENTURE_PERSON')
USR='Admin'
PWD='Admin-12'
LOG=./StartMask.log
login() {
	TOKEN=$(curl -X 'POST' 'http://'$IP_ENGINE_MASK'/masking/api/v5.1.31/login' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{"username": "'$USR'",  "password": "'$PWD'"}' | cut -d'"' -f4)
}

environmentid() {
	ID_ENV=$(curl -X 'GET' 'http://'$IP_ENGINE_MASK'/masking/api/v5.1.31/environments?' -H 'accept: application/json' -H 'Authorization:'$TOKEN | jq '.responseList[] | select(.environmentName == "'$NM_ENV'")' | jq .environmentId)
}

maskingjob() {
	MASKINGJOBID=$(curl -X 'GET' 'http://'$IP_ENGINE_MASK'/masking/api/v5.1.31/masking-jobs?environment_id='$ID_ENV -H 'accept: application/json' -H 'Authorization:'$TOKEN | jq '.responseList[] | select(.jobName == "'$ARRAY'")' | jq .maskingJobId)
}

execmsk() {
	EXECUTIONID=$(curl -X 'POST' 'http://'$IP_ENGINE_MASK'/masking/api/v5.1.31/executions' -H 'accept: application/json' -H 'Authorization:'$TOKEN -H 'Content-Type: application/json' -d '{ "jobId":'$MASKINGJOBID' }' | jq '.executionId')
}

mmjob() {
	#STATUSJOB=$(curl -X 'GET' 'http://'$IP_ENGINE_MASK'/masking/api/v5.1.31/monitor-task/'$EXECUTIONID'?monitorable_task=EXECUTIONS' -H 'accept: application/json' -H 'Authorization:'$TOKEN |jq '.progression[] | select(.event == "'$EVENT'")'| jq .status)
	STATUSJOB=$(curl -X 'GET' 'http://'$IP_ENGINE_MASK'/masking/api/v5.1.31/monitor-task/'$EXECUTIONID'?monitorable_task=EXECUTIONS' -H 'accept: application/json' -H 'Authorization:'$TOKEN)
	while true; do
		START=$(echo $STATUSJOB | jq '.progression[] | select(.event == "Initializing")' | jq .status)
		COLL_INF=$(echo $STATUSJOB | jq '.progression[] | select(.event == "Collecting Information")' | jq .status)
		END=$(echo $STATUSJOB | jq '.progression[] | select(.event == "Job Completed")' | jq .status)
		if [ $END == '"SUCCEEDED"' -o $END == '"NON_CONFORMANT"' ]; then
			echo 'Job '$ARRAY' Finalizado -' $(date +'%d/%m/%y %H:%M:%S') >>$LOG
			break
		elif [ $END == '"QUEUED"' ]; then
			echo 'Dormindo'
			sleep 2
			mmjob
		else
			echo 'Job '$ARRAY' Falhou -' $(date +'%d/%m/%y %H:%M:%S') >>$LOG
			exit 1
		fi
	done

}
start() {
	for ARRAY in "${JOB_NAME[@]}"; do
		LOG=./'StartMask_'$ARRAY'_'$(date +'%d%m%y').log
		echo 'Iniciando Login Na Engine de Mascaramento('$IP_ENGINE_MASK')- ' $(date +'%d/%m/%y %H:%M:%S') >>$LOG
		login
		if [ $(echo $TOKEN | sed 's/ //g') == 'Invalidusernameorpassword' ]; then
			echo $TOKEN '-' $(date +'%d/%m/%y %H:%M:%S') >>$LOG
		else
			echo 'Login Realizado com sucesso -' $(date +'%d/%m/%y %H:%M:%S') >>$LOG
			environmentid
			if [ -z $ID_ENV ]; then
				echo 'Environment '$NM_ENV' Não Encontrado -' $(date +'%d/%m/%y %H:%M:%S') >>$LOG
			else
				echo 'ID do Environment '$NM_ENV' - ' $ID_ENV ' -' $(date +'%d/%m/%y %H:%M:%S') >>$LOG
				maskingjob
				if [ -z $MASKINGJOBID ]; then
					echo 'Job de Mascaramento '$ARRAY' Não Encontrado -' $(date +'%d/%m/%y %H:%M:%S') >>$LOG
				else
					echo 'Job de Mascaramento' $MASKINGJOBID ' -' $(date +'%d/%m/%y %H:%M:%S') >>$LOG
					execmsk
					if [ -z $EXECUTIONID ]; then
						echo 'Falha na Execução do Job de Mascaramento -' $(date +'%d/%m/%y %H:%M:%S') >>$LOG

					else
						echo 'Job '$ARRAY ' Iniciado -' $(date +'%d/%m/%y %H:%M:%S') >>$LOG
						echo 'Iniciando Monitoramento do Job -' $(date +'%d/%m/%y %H:%M:%S') >>$LOG
						mmjob
						echo 'Finalizando o Monitoramento do Job -' $(date +'%d/%m/%y %H:%M:%S') >>$LOG
					fi
				fi
			fi
		fi
	done
}
jq --version
if [ $(echo $?) -eq 0 ]; then
	start
else
	echo 'Favor instalar o pacote JQ' $(date +'%d/%m/%y %H:%M:%S') >>$LOG
fi
