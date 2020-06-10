# MDRS
Minium Dealy Routes Selector

用于双出口路由器，以选择最优响应目的IP地址，加速网络响应与浏览速度。

Main Programme
MDRS.sh

主程序MDRS.sh，需要在文件头修改第二网关物理接口地址以及第二网关的接口地址。
可以根据需要修改部分参数。
程序会在获取系统连接表，查看当前访问远程地址状态，然后分别用第一网关和第二网关进行ping测试，结果做差且大于设定的值，如果第二接口的延迟小的会写入系统路由表，并存入临时数据库（文件），否则不做操作。
以此循环。



Restore Programme
Restore_routes.sh

恢复路由程序，程序前台运行使用ctrl+c来退出程序，如果是后台运行则使用kill，但由于写入了系统路由表需要运行本程序来清除，也可以不清除，待系统重启后写入的详细路由会消失。


适用于：

openwrt 系统，无论X86还是其他平台。
绝大部分Linux系统，基于linux shell命令，应该都支持。


运行方式：

赋予权限：
chmod +x mdrs.sh
前台运行：
./mdrs.sh
后台运行：
./mdrs.sh &
可自行添加至开机运行脚本exit之前。
