from errbot import BotPlugin, re_botcmd, botcmd, re, arg_botcmd
from time import sleep
from itertools import chain
import json
import rubrik_cdm
import urllib3

class Rubrik(BotPlugin):

    CONFIG_TEMPLATE = {'NODE_IP': '<IP or DNS of Rubrik Cluster>',
                       'API_TOKEN': '<API token with administrative permissions>'}

    def get_configuration_template(self):
        return  {'NODE_IP': '<IP or DNS of Rubrik Cluster>',
                 'API_TOKEN': '<API token with administrative permissions>'} 

    urllib3.disable_warnings()

    @arg_botcmd('--vm', dest='vm', type=str)
    @arg_botcmd('--sla-domain', dest='sla_domain',type=str)
    def rubrikassignsla(self, msg, vm, sla_domain):
        yield 'Ok I''ll assign ' + vm + ' to the ' + sla_domain + ' SLA Domain. Let''s rock!'
        rubrik = rubrik_cdm.Connect(node_ip=self.config['NODE_IP'],api_token=self.config['API_TOKEN'])
        assign_sla = rubrik.assign_sla(vm,sla_domain,'vmware')
       
        if type(assign_sla) is dict:
            if assign_sla['status_code'] == 204:
                yield 'Success! ' + vm + ' is now a member of the ' + sla_domain + ' SLA Domain'
            else:
                yield 'Uh Oh! Something bad happened! I recieved a status code of ' + assign_sla['status_code']
                yield 'Full response from SDK is ' + assign_sla
        else:
            yield assign_sla


    @botcmd
    def rubriksoftwareversion(self, msg, args):
        rubrik = rubrik_cdm.Connect(node_ip=self.config['NODE_IP'],api_token=self.config['API_TOKEN'],enable_logging=False)
        cluster_version = rubrik.cluster_version()
        returnmessage = 'Your Rubrik cluster is running software version %s' % cluster_version
        return returnmessage   # This string format is markdown.

