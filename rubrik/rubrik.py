from errbot import BotPlugin, re_botcmd, botcmd, re, arg_botcmd, ValidationException
from time import sleep
from itertools import chain
import json
import rubrik_cdm
import urllib3
import sys

class Rubrik(BotPlugin):

    CONFIG_TEMPLATE = {'NODE_IP': '<IP or DNS of Rubrik Cluster>',
                       'API_TOKEN': '<API token with administrative permissions>'}

    def get_configuration_template(self):
        return  {'NODE_IP': '<IP or DNS of Rubrik Cluster>',
                 'API_TOKEN': '<API token with administrative permissions>'} 

    urllib3.disable_warnings()

    # Function to Live Mount a VMware VM
    @arg_botcmd('--vm',dest='vm',type=str)
    @arg_botcmd('--date',dest='date',type=str,default='latest')
    @arg_botcmd('--time',dest='time',type=str,default='latest')
    @arg_botcmd('--host',dest='host',type=str,default='current')
    @arg_botcmd('--remove-network-devices',dest='removenetworkdevices',type=bool,default=False)
    @arg_botcmd('--power-on',dest='poweron',type=bool,default=True)
    def livemountvmwarevm(self,msg,vm,date,time,host,removenetworkdevices,poweron):
        yield ':thumbsup: 10-4 good buddy! I''ll proceed to live mount `'+vm+'` I''ll let you know when I''m done :point_down:'
        try:
            rubrik = rubrik_cdm.Connect(node_ip=self.config['NODE_IP'],api_token=self.config['API_TOKEN'])
            live_mount = rubrik.vsphere_live_mount(vm_name=vm,date=date,time=time,host=host,remove_network_devices=removenetworkdevices,power_on=poweron)

            yield ':hammer: Request for live mount of `'+vm+'` has been submitted! You can monitor the progress with the following API URI `'+live_mount['links'][0]['href']+'` That said, I''ll totally let you know when its done'
            progress = rubrik.job_status(url=live_mount['links'][0]['href'],wait_for_completion=True)
            yield ':fire: Looks like the live mount for `'+vm+'` has completed with a status of '+progress['status']

        except Exception as e:
            yield ':eyes: '+str(e)+' :eyes:'
        

    # Function to take on-demand snapshot
    @arg_botcmd('--vm', dest='vm', type=str)
    @arg_botcmd('--sla-domain', dest='sla_domain',type=str)
    def ondemandsnapshot(self,msg,vm,sla_domain):
        response = ':thumbsup: Gotchya - Take an on-demand snap of `'+vm+'`'
        if sla_domain is None:
            response = response + '. You didn''t pass a value for `--sla-domain` so I''ll just use the one currently assigned'
        else:
            response = response + ' using the `'+sla_domain+'` SLA Domain! Let me execute that!'
        
        yield response 
        rubrik = rubrik_cdm.Connect(node_ip=self.config['NODE_IP'],api_token=self.config['API_TOKEN'])
        try:
            if sla_domain is None:
                ondemandsnap = rubrik.on_demand_snapshot(object_name=vm,object_type='vmware')
            else:
                ondemandsnap = rubrik.on_demand_snapshot(object_name=vm,object_type='vmware',sla_name=sla_domain)

            yield ':boom: The on-demand snapshot has been submitted!  You can monitor querying the API URI `'+ondemandsnap[1]+'` if you want. Either way, I''ll let you know when it has completed'
            snapshot_status = rubrik.job_status(url=ondemandsnap[1],wait_for_completion=True)
            yield ':thumbsup: Looks like the on-demand snapshot for `'+vm+'` has completed with a status of '+snapshot_status['status']
        except Exception as e:
            yield ':x: :eyes: ' + str(e) + ' :eyes:'
            sys.exit(1)
    
    # Function to assign SLA to VMware VM
    @arg_botcmd('--vm', dest='vm', type=str)
    @arg_botcmd('--sla-domain', dest='sla_domain',type=str)
    def assignslavmware(self, msg, vm, sla_domain):

        yield ':thumbsup: Ok I''ll assign `' + vm + '` to the `' + sla_domain + '` SLA Domain. It may take a second - I''ll let you know down here when I''m done :point_down:'
        rubrik = rubrik_cdm.Connect(node_ip=self.config['NODE_IP'],api_token=self.config['API_TOKEN'])
        try:
            assign_sla = rubrik.assign_sla(vm,sla_domain,'vmware')
            if type(assign_sla) is dict:
                if assign_sla['status_code'] == 204:
                    yield ':boom: Success! `' + vm + '` is now a member of the `' + sla_domain + '` SLA Domain'
                else:
                    yield ':x: Uh Oh! Something bad happened! I recieved a status code of ' + assign_sla['status_code']
                    yield 'Full response from SDK is ' + assign_sla
            else:
                yield ':eyes: ' + assign_sla
        except Exception as e:
            yield ':x: :eyes: ' + str(e) + ' :eyes:'
            sys.exit(1)

    # Function to retrieve Rubrik Software version
    @botcmd
    def softwareversion(self, msg, args):
        rubrik = rubrik_cdm.Connect(node_ip=self.config['NODE_IP'],api_token=self.config['API_TOKEN'],enable_logging=False)
        cluster_version = rubrik.cluster_version()
        returnmessage = ':computer: Your Rubrik cluster is running software version %s' % cluster_version
        return returnmessage   # This string format is markdown.

