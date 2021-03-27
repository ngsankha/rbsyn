from plumbum import local, FG, TF
from plumbum.cmd import bundle
import json
import numpy as np
from scipy.stats import iqr
import os
import argparse

parser = argparse.ArgumentParser(description='Run RbSyn benchmarks')
parser.add_argument('--times', '-t', dest='times', action='store',
                    default=11, help='number of times to run the benchmark')
parser.add_argument('--smallbench', dest='benchtype', action='store_const',
                    const='smallbench', default='bench',
                    help='use the small benchmark suite for data collection')

args = parser.parse_args()

RBSYN_PATH = '/rbsyn-pldi21'
MY_CWD = os.getcwd()
JSON_LOG_FILE = 'test_log.json'

def benchmark(**opts):
    local.cwd.chdir(RBSYN_PATH)
    bundle.with_env(**opts)['exec', 'rake', str(args.benchtype)] & TF(FG=True)

def collect(output_file, times, **opts):
    merged = None
    for i in range(times):
        benchmark(**opts)
        with open(RBSYN_PATH + '/' + JSON_LOG_FILE) as f:
            data = json.load(f)
            if merged is None:
                merged = data
                for app, benchmarks in data.items():
                    for name, info in benchmarks.items():
                        merged[app][name]['time'] = [merged[app][name]['time']]
            else:
                for app, benchmarks in data.items():
                    for name, info in benchmarks.items():
                        merged[app][name]['time'].append(data[app][name]['time'])

    for app, benchmarks in data.items():
        for name, info in benchmarks.items():
            merged[app][name]['median_time'] = np.median(merged[app][name]['time'])
            merged[app][name]['time_siqr'] = iqr(merged[app][name]['time']) / 2

    local.cwd.chdir(MY_CWD)
    with open(output_file, 'w') as out:
        json.dump(merged, out)

collect('base_data.json', int(args.times))
collect('type_data.json', 1, DISABLE_TYPES='1')
collect('effects_data.json', 1, DISABLE_EFFECTS='1')
collect('both_data.json', 1, DISABLE_TYPES='1', DISABLE_EFFECTS='1')
collect('class_perf.json', int(args.times), EFFECT_PREC='1')
collect('min_perf.json', int(args.times), EFFECT_PREC='2')
