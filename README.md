# up-ca-tpintegrador-PORTILLA-0120161

# 1. Firewall

## a. El firewall deberá cargar la configuración de iptables al inicio

Con las configuraciones de iptables hechas ejecuto el comando: 

    iptables-save > /etc/firewall.conf

Luego, edito el archivo /etc/network/if-up.d/iptables agregando las siguientes líneas:

    #!/bin/sh
    iptables-restore < /etc/firewall.conf

Luego le doy permisos de ejecución con el siguiente comando:

    chmod +x /etc/network/if-up.d/iptables
    
## b. Las políticas por defecto de las 3 cadenas de la tabla FILTER sea DROP

Ejecuto los siguientes comandos:

    iptables -P INPUT DROP
    iptables -P OUTPUT DROP
    iptables -P FORWARD DROP
    
## c. El tráfico desde/hacia la interfaz loopback sea posible

    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
## d. La única VM que pueda administrar el firewall vía ssh sea cliente-02

    iptables -A INPUT -i eth2 -p tcp --dport 22 -m state --state NEW,ESTABLISHED -s 192.168.20.2 -j ACCEPT
    iptables -A OUTPUT -o eth2 -p tcp --sport 22 -m state --state ESTABLISHED -d 192.168.20.2 -j ACCEPT
    
## e.	La única VM que pueda navegar por internet sea cliente-03

    iptables -t nat -A POSTROUTING -s 192.168.20.3 -d 0.0.0.0/0 -j MASQUERADE
    
## f.	La única VM de la red 192.168.20.0/24 que pueda ingresar al web server de la red .10.0 sea cliente-04

    iptables -A FORWARD -i eth2 -o eth1 -p tcp -m state --state NEW,ESTABLISHED -s 192.168.20.4 -d 192.168.10.3 -j ACCEPT
    iptables -A FORWARD -i eth1 -o eth2 -p tcp -m state --state ESTABLISHED  -s 192.168.10.3 -d 192.168.20.4 -j ACCEPT
    

# 2. Servidor Web

## a. Instalación de JDK

Me conecto con el programa WinSCP a la VM web-server y transfiero los archivos jdk-8u262.tar.gz, apache-tomcat-8.5.72.tar.gz, sample.war y poc-jsp-mysql-crud.war.
Descomprimo el jdk en la ruta /opt/ con el siguiente comando:

    tar -xvf jdk-8u262.tar.gz -C /opt/
    
Creo la variable de entorno JAVA_HOME editando el script bashrc y agrego las siguientes líneas:

    JAVA_HOME=/opt/jdk-8u262
    export PATH=$PATH:$JAVA_HOME/bin
       
## b. Instalación de Apache Tomcat y despliegue de la aplicación de ejemplo       
       
Descomprimo Tomcat en la ruta /opt/ con el siguiente comando:

    tar -xvf apache-tomcat-8.5.72.tar.gz -C /opt/
    
Muevo el archivo sample.war a la ruta /opt/apache-tomcat-8.5.72/webapps/

Inicio tomcat ejecutando el archivo startup.sh en la ruta /opt/apache-tomcat-8.5.72/bin/

Desde la VM cliente-dmz ingreso por browser a la dirección http://192.168.10.3:8080/sample para ver la aplicación funcionando

## Instalación de MYSQL y despliegue de aplicación Java con Mysql

En la consola de la VM de web-server ejecuto el siguiente comando:

    wget https://dev.mysql.com/get/mysql-apt-config_0.8.15-1_all.deb
    
Instalo el paquete con el siguiente comando:
    
    sudo dpkg -i mysql-apt-config_0.8.15-1_all.deb
    
Debido a que MySQL Server 8.0 no está disponible. Entro al submenú y elijo la versión 5.6.

Actualizo la lista de paquetes ejecutando el comando:

    apt update
    
Para instalar MYSQL ejecuto el siguiente comando:

    sudo apt install -y mysql-community-server
    
En la pantalla que aparece se debe ingresar la password del usuario root que se va a utilizar.

Para validar que el servicio mysql esté activo se puede ejecutar el comando:

    systemctl status mysql
    
Para iniciar sesión como usuario root ejecuto el siguiente comando e ingreso la contraseña:

    mysql -u root -p
    
Creo la base de datos userdb con el siguiente comando

    create database userdb;
    
Para desplegar la aplicación poc-jsp-mysql-crud.war muevo el archivo war a la ruta /opt/apache-tomcat-8.5.72/webapps/ e inicio Tomcat con el archivo `startup.sh`

Para ver la aplicación funcionando ingreso desde la VM cliente-dmz con un browser a la dirección http://192.168.10.3:8080/poc-jsp-mysql-crud/index.jsp


# 3. Servidor de archivos y 5. LVM

Creo el directorio disco_backups en la ruta /media/ y procedo con la configuración del disco sdb como volumen lógico

Ejecuto el comando:

    fdisk /dev/sdb
    
Elijo las opciones :

1. Opción n ( nueva partición )
2. Opción p ( partición primaria )
3. Opción 1 ( número de partición )
4. 5G (tamaño para este ejercicio)
5. Opción t ( tipo de disco)
6. Opción 8e ( Linux LVM)
7. Opción w ( escribir tabla de particiones)

Instalo LVM con el siguiente comando:

    apt install lvm2
    
Configuro el physical volume con el comando:
    pvcreate /dev/sdb1

Creo el volume group con el comando:

    vgcreate vg_backup /dev/sdb1
    
Creo el volumen lógico con el comando:

    lvcreate -L 1G -n lv_backup vg_backup
    
Configuro el nuevo volumen lógico

    mkfs -t ext4 /dev/mapper/vg_backup-lv_backup
    
Configuro el /etc/fstab con el UUID obtenido mediante el comando `blkid`, agregando la siguiente línea:

    UUID=84dae1fc-67de-4b4a-8b61-c76a7321097e /media/disco_backups ext4 defaults 0 0
    
## Configurar SSH para que por cada ejecución del rsync no pida la contraseña a la VM cliente-03

Ejecuto el siguiente comando:

    ssh-keygen
    
Cuando la pantalla pida la passphrase presionar la tecla Enter

Luego ejecuto el comando para copiar la public key al servidor remoto:

    ssh-copy-id jason@192.168.20.3
    
## Configuración del Rsync y Cron

Instalo Rsync con el comando:

    apt install rsync
    
Le doy permisos de ejecución al script `backup_home_cliente-03.sh` con el comando:

chmod +x backup_home_cliente-03.sh

Configuro Cron con el comando:

    crontab -e
    
Agrego la siguiente línea al final:

    0 0 * * * /home/jasonp/backup_home_cliente-03.sh

# 4. Servidor DHCP

En una terminal de la VM dhcp-server instalo dhcp con el comando:

    aptitude install isc-dhcp-server
    
Edito el archivo /etc/default/isc-dhcp-server dejando la siguiente línea al final:

    INTERFACES="eth0"

Edito el archivo /etc/dhcp/dhcpd.conf con la siguiente configuración:

    subnet 192.168.20.0 netmask 255.255.255.0 {
        range 192.168.20.101 192.168.20.110;
    }
    

    
    
    
    
    
    
    
    
    
    
