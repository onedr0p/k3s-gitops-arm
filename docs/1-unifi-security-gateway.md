# UniFi Security Gateway

We will need to create a new network for our k3s cluster so MetalLb can have an entire network.

- Goto Settings > Networks > + Create New Network
- Fill out Name, Purpose=`Corporate`, Network Group=`LAN`, VLAN=`42`, Gateway/Subnet=`192.168.42.1/27`, Check Enable IGMP snooping, Save

Take note my BGP CIDR for useable IPs that metalLb will use is `192.168.42.24/29`

Now SSH into your USG and run the following commands for your **worker nodes**

```bash
# Enable BGP
configure
set protocols bgp 64512 parameters router-id 192.168.42.1
set protocols bgp 64512 neighbor 192.168.42.24 remote-as 64512
set protocols bgp 64512 neighbor 192.168.42.25 remote-as 64512
set protocols bgp 64512 neighbor 192.168.42.26 remote-as 64512
commit
save
exit

# List the BGP neighbors
show ip bgp neighbors

# List any services deployed
show ip route bgp
show ip bgp

#
# Delete your rules
#
configure
delete protocols bgp 64512 parameters router-id 192.168.42.1
delete protocols bgp 64512 neighbor 192.168.42.24
delete protocols bgp 64512 neighbor 192.168.42.25
delete protocols bgp 64512 neighbor 192.168.42.26
commit
save
exit
```

Next is to set the ethernet ports your RPis are connected to to use VLAN 42, or connect to the WiFi network you created for that VLAN.

Additional Resources on MetalLb and USG:

- [Using MetalLB as Kubernetes load balancer with Ubiquiti EdgeRouter](https://medium.com/@ipuustin/using-metallb-as-kubernetes-load-balancer-with-ubiquiti-edgerouter-7ff680e9dca3)
- [Using MetalLB with the Unifi USG for in-home Kubernetes LoadBalancer Services](http://blog.cowger.us/2019/02/10/using-metallb-with-the-unifi-usg-for-in-home-kubernetes-loadbalancer-services.html)
