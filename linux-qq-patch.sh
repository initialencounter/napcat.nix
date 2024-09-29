cwd=$(pwd)
qq_path=$cwd/qq

mkdir -p $qq_path

curl -L -o linux-qq.deb https://dldir1.qq.com/qqfile/qq/QQNT/f60e8252/linuxqq_3.2.12-28327_amd64.deb
dpkg-deb -R linux-qq.deb $qq_path

echo -e "\e[32m解压deb中...\e[0m"
curl -L -o $qq_path/opt/QQ/NapCat.Shell.zip /https://github.com/NapNeko/NapCatQQ/releases/download/v2.6.18/NapCat.Shell.zip

## patch postinst
cat >> $cwd/qq/DEBIAN/postinst <<EOF

ln -sf '/opt/QQ/napcat' '/usr/bin/napcat'
napcat_path=\$HOME/napcat
unzip /opt/QQ/NapCat.Shell.zip -d \$napcat_path

echo "(async () => {await import(\"file://\$napcat_path/napcat.mjs\");})();" > /opt/QQ/resources/app/loadNapCat.js
mv \$napcat_path/qqnt.json /opt/QQ/resources/app/package.json
echo -e "NapCat安装完成\e[32m输入命令 napat \e[0m"
EOF

## start command
cat >> $cwd/qq/opt/QQ/napcat <<EOF
#!/bin/bash

rm -rf "/tmp/.X1-lock"
Xvfb :1 -screen 0 1080x760x16 +extension GLX +render > /dev/null 2>&1 &
echo -e "\e[32mXvfb 启动中...\e[0m"
sleep 2
export DISPLAY=:1
cd \$HOME/napcat
echo -e "\e[32mNapCat 启动中...\e[0m"
/opt/QQ/qq --no-sandbox \$@
EOF

chmod +x $cwd/qq/opt/QQ/napcat

cd $qq_path
echo -e "\e[32m更新md5sum中...\e[0m"
find . -type f -exec md5sum {} \; | sed 's| ./| |' > $qq_path/DEBIAN/md5sums

cd $cwd
echo -e "\e[32m打包deb中...\e[0m"
dpkg-deb -b $qq_path linux-qq-patch.deb