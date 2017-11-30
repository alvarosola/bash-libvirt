#!/bin/bash

#Primera parte
#Variable para indicar número minimo MB libres
MIN=20
bucle='start'

echo Cuando quieras puedes estresar la maquina mv1
#Recogemos la memoria RAM con el comando free
while [ $bucle != 'stop' ]; do
	FREE=`ssh mv1@192.168.100.59 free -m | grep Mem | awk '{print $7}'`
	if [ $FREE -lt $MIN ];
	then
#Sentencia para desmontar volumen
		echo Desmontando volumen...
		ssh mv1@192.168.100.59 sudo umount /dev/vdb
		echo Volumen desmontado.
#Sentencia para quitar el disco adicional de mv1
		echo Quitando volumen...
		virsh -c qemu:///system detach-disk mv1 /dev/mapper/vgsistema-discomv1
		echo Volumen quitado.
#Sentencia para redimensionar el volumen
		echo Redimensionando volumen...
		lvextend -L +10M /dev/vgsistema/discomv1
		echo Volumen redimensionado.
#Sentencia para añadir a mv2 el disco adicional
		echo Añadiendo volumen a mv2...
		virsh -c qemu:///system attach-disk mv2 /dev/mapper/vgsistema-discomv1 vdb
		echo Volumen añadido.
#Sentencia para montar el volumen
		echo Montando el volumen...
		ssh mv2@192.168.100.54 sudo mount /dev/vdb /var/www/html
		echo Volumen montado.
#Quitar regla de iptable para redireccionar el purto 80 a mv1
		echo Quitando regla de iptable...
		iptables -t nat -D PREROUTING 1
		echo Regla de iptable quitada.
#Añadir regla de iptable para redireccionar el puerto 80 a mv2
		echo Añadiendo regla iptble...
		iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.100.54:80
		iptables -I FORWARD -d 192.168.100.54/32 -p tcp --dport 80 -j ACCEPT
		echo Regla de iptable añadida
		bucle='stop'
	fi
done
#Segunda parte
echo Cuando quieras puedes estresar la maquina mv2
#Variable para indicar número minimo MB libres
MIN2=20
bucle2='start'
#Recogemos la memoria RAM con el comando free
while [ $bucle2 != 'stop' ]; do
        FREE2=`ssh mv2@192.168.100.54 free -m | grep Mem | awk '{print $7}'`
        if [ $FREE2 -lt $MIN2 ];
        then
#Redimensionando memoria RAM
                echo Ampliando memoria RAM...
                virsh setmem mv2 2G --live
                bucle2='stop'
        fi
done
echo Memoria RAM ampliada.

