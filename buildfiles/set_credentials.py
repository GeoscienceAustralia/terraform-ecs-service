import os
import boto3

CONFIG_PATH = os.path.expanduser("~/.datacube.conf")

CONFIG_TEMPLATE = """\
[datacube]
db_hostname: {db_host}
db_port: {db_port}
db_database: {db_name}
db_username: {db_username}
db_password: {db_password}\
"""

SSM = boto3.client('ssm', 'ap-southeast-2')

SSM_PREFIX = os.environ.get('DB_SSM_PREFIX', 'odc_ecs_service.rds.user.')
SSM_DELIM = '.'
SSM_VALUES = ['db_host', 'db_port', 'db_name', 'db_username', 'db_password']


def get_ssm_parameters(names, with_decryption=True):

    params = {}
    response = SSM.get_parameters(Names=names, WithDecryption=with_decryption)

    for param in response['Parameters']:
        key = param['Name'].split(SSM_DELIM)[-1]

        params[key] = param['Value']

    return params


def write_to_file(outfile, template, params):
    with open(outfile, 'w+') as fd:
        fd.write(template.format(**params))


if __name__ == "__main__":
    param_keys = list(map(lambda k: SSM_PREFIX + k, SSM_VALUES))

    params = get_ssm_parameters(names=param_keys)

    write_to_file(CONFIG_PATH, CONFIG_TEMPLATE, params)
