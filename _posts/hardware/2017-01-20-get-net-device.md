	1 #!/usr/bin/python
	2 __author__ = "Haibin"
	3
	6
	7 import re,sys,os,string,glob
	8 from optparse import OptionParser
	9
	10 usage = "usage: %prog [options] arg"
	11 parser = OptionParser(usage=usage)
	12 parser.add_option("-a", "--all", dest="allinfo", action="store_true",
	13                    help="show all network devices status of the platform")
	14 parser.add_option("-i", "--interface", dest="interfaceinfo", action="store", metavar="INTERFACE",
	15                    help="show the network devices status of specified interface")
	16 parser.add_option("-b", "--bdf", dest="bdfinfo", action="store", metavar="BDF",
	17                    help="show the network devices status of specified BDF")
	18 parser.add_option("-m", "--model", dest="modelinfo", action="store", metavar="MODEL",
	19                    help="show the network devices status of specified MODEL")
	20 parser.add_option("-d", "--avdevice", dest="availableinfo", action="store", metavar="AVAILABLE",
	21                    help="show the available devices on the platform, ONLY <PF, VF, NIC> available")
	22
	23 # for test
	24 parser.add_option("-w", "--wtdevice", dest="wantedinfo", action="store", metavar="WANTED",
	25                    help="show the wanted devices on the platform, ONLY <PF, VF, NIC> wanted")
	26 #
	27 parser.add_option("-v", "--verbose", dest="verbose", action="store_true", default = True,
	28            help="print all the messages, DEFAULT_VALUE=TRUE")
	29 parser.add_option("-q", "--quite", dest="verbose", action="store_false",
	30            help="ONLY print BDF")
	31 (options, args) = parser.parse_args()
	32
	33 class Net_Dev:
	34     def __init__(self,**args):
	35         self.driver=args['driver']
	36         self.bdf=args['bdf']
	37         self.state=args['state']
	38         self.interface=args['interface']
	39         self.vf_list=args['vf_list']
	40         self.device_model=args['device_model']
	41         self.device_type=args['device_type']
	42         self.parent=args['parent']
	43         self.mac=args['mac']
	44
	45 def parse_cmd(cmd):
	46     output=os.popen(cmd)
	47     return output.read()
	48
	49 def show_all():
	50         for k,v in net_list[bdf].__dict__.items():
	51                 print '\033[1;32;40m'+k+'\033[0m'+'='+str(v)
	52         print "\n"
	53
	54 def show_interface(para):
	55     if interface == para.lower():
	56         for k,v in net_list[bdf].__dict__.items():
	57             print '\033[1;32;40m'+k+'\033[0m'+'='+str(v)
	58         sys.exit(0)
	59 def show_bdf(para):
	60     if bdf == para:
	61         for k,v in net_list[bdf].__dict__.items():
	62                         print '\033[1;32;40m'+k+'\033[0m'+'='+str(v)
	63         sys.exit(0)
	64 def show_model(para, para1=None):
	65     if para.upper() in device_model and para1.upper() == None:
	66         for k,v in net_list[bdf].__dict__.items():
	67                         print '\033[1;32;40m'+k+'\033[0m'+'='+str(v)
	68         print "\n"
	69     elif para.upper() in device_model and para1.upper() == device_type and state == "Available":
	70         for k,v in net_list[bdf].__dict__.items():
	71                         print '\033[1;32;40m'+k+'\033[0m'+'='+str(v)
	72                 print "\n"
	73 def show_short_model(para, para1=None):
	74     if para.upper() in device_model and para1.upper() == None:
	75         for k,v in net_list[bdf].__dict__.items():
	76             if (k == "bdf"):
	77                                 print v
	78     elif para.upper() in device_model and para1.upper() == device_type and state == "Available":
	79         for k,v in net_list[bdf].__dict__.items():
	80                         if (k == "bdf"):
	81                                 print v
	82 def show_available(para):
	83     if (para.upper() == device_type and state == "Available"):
	84         for k,v in net_list[bdf].__dict__.items():
	85                 print '\033[1;32;40m'+k+'\033[0m'+'='+str(v)
	86         print "\n"
	87 def show_short_available(para):
	88     if (para.upper() == device_type and state == "Available"):
	89                 for k,v in net_list[bdf].__dict__.items():
	90                         if (k == "bdf"):
	91                                 print v
	92 def show_wanted(para):
	93     if (para.upper() == device_type):# and state == "Available"):
	94         for k,v in net_list[bdf].__dict__.items():
	95                 print '\033[1;32;40m'+k+'\033[0m'+'='+str(v)
	96         print "\n"
	97 def show_short_wanted(para):
	98     if (para.upper() == device_type):# and state == "Available"):
	99                 for k,v in net_list[bdf].__dict__.items():
	100                         if (k == "bdf"):
	101                                 print v
	102
	103
	104 output=parse_cmd("lspci | grep Eth")
	105 output1=parse_cmd("route -n")
	106 output2=parse_cmd("brctl show")
	107 net_list={}
	108 for line in output.strip().split('\n'):
	109     vf_list=[]
	110     driver=None
	111     bdf=None
	112     state="Available"
	113     interface=None
	114     device_model=None
	115     device_type=None
	116     parent=None
	117     mac=None
	118     line_list=line.split(' ')
	119     bdf=line_list[0]
	120     dir_path="/sys/bus/pci/devices/0000:" + bdf
	121     if os.path.exists(dir_path):
	122         pci_msg=parse_cmd("lspci -mm -s " + bdf)
	123         device_model=pci_msg.split(' "')[3].split('"')[0]
	124         if os.path.exists(dir_path + '/sriov_totalvfs'):
	125             device_type="PF"
	126             vf=glob.glob(dir_path + '/virtfn*')
	127             for ele in vf:
	128                 vf_list.append(os.readlink(ele).split('/0000:')[-1])
	129         elif os.path.exists(dir_path + '/physfn'):
	130             device_type="VF"
	131             parent=os.readlink(dir_path + '/physfn').split('/0000:')[-1]
	132             state=net_list[parent].state
	133         else:
	134             device_type="NIC"
	135         if os.path.exists(dir_path + '/driver'):
	136             driver=os.readlink(dir_path + '/driver').split('/')[-1]
	137             if (driver == "virtio-pci" or driver == "vfio-pci" or driver == "pci-stub" or driver == "pciback" or driver == "xen-platform-pci"):
	138                 state="USED"
	139             else:
	140                 if os.path.exists(dir_path + '/net'):
	141                     interface=os.listdir(dir_path + '/net')[0]
	142                     # check if the interface in bridge/route or if it's physically linked
	143                     if (interface in output2):
	144                         state="USED"
	145                     #elif (interface in output1 and device_type != "VF"):
	146                     #   state="USED"
	147                     elif ("NO-CARRIER" in parse_cmd("ip link show " + interface)):
	148                         state="UNLINK"
	149                     mac=open(dir_path + '/net/' + interface + '/address').read( ).strip()
	150
	151     net=Net_Dev(driver=driver,bdf=bdf,state=state,interface=interface,vf_list=vf_list,device_model=device_model,device_type=device_type,parent=parent,mac=mac)
	152     net_list.update({bdf:net})
	153
	154     if options.allinfo:
	155             show_all()
	156     elif options.interfaceinfo:
	157         if options.interfaceinfo.lower() in parse_cmd("ifconfig -a"):
	158             show_interface(options.interfaceinfo)
	159         else:
	160             print "No interfance found"
	161             sys.exit(1)
	162     elif options.bdfinfo:
	163         if options.bdfinfo in output: