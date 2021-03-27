#!/usr/bin/env python
# coding: utf-8

import pandas as pd
import json
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec

plt.rcParams["figure.figsize"] = [10,4]
font = {'size': 14}
plt.rc('font', **font)

def flatten_json(file):
    with open(file) as f:
        data = json.load(f)
    processed = {}
    for app, benchmarks in data.items():
        for name, info in benchmarks.items():
            processed[app + name] = info
    return pd.DataFrame.from_dict(processed).transpose()

bench_attrs = flatten_json('base_data.json')[['size', 'branches', 'specs', 'components']]
x = np.arange(len(bench_attrs['size'].values))

def attach_labels(df):
  conditions = [
    df['index'] == 'Synthetictest_0001_false',
    df['index'] == 'Synthetictest_0001_lvar',
    df['index'] == 'Synthetictest_0001_user exists',
    df['index'] == 'Synthetictest_0001_method chains',
    df['index'] == 'Synthetictest_0001_branching',
    df['index'] == 'Diasporatest_0001_pod#schedule_check_if_needed',
    df['index'] == 'Gitlabtest_0001_user#disable_two_factor!',
    df['index'] == 'Discoursetest_0001_clear_global_notice_if_needed',
    df['index'] == 'Synthetictest_0001_fold branches',
    df['index'] == 'Gitlabtest_0001_discussion#build',
    df['index'] == 'Diasporatest_0001_user#process_invite_acceptence',
    df['index'] == 'Gitlabtest_0001_issue#close',
    df['index'] == 'Discoursetest_0001_activate',
    df['index'] == 'Diasporatest_0001_user#confirm_email',
    df['index'] == 'Synthetictest_0001_overview example',
    df['index'] == 'Discoursetest_0001_check_site_contact_username',
    df['index'] == 'Gitlabtest_0001_issue#reopen',
    df['index'] == 'Diasporatest_0001_invitation_code#use!',
    df['index'] == 'Discoursetest_0001_unstage user'
  ]
  choices = [
    'S2',
    'S1',
    'S4',
    'S3',
    'S5',
    'A9',
    'A6',
    'A1',
    'S7',
    'A5',
    'A10',
    'A7',
    'A2',
    'A12',
    'S6',
    'A4',
    'A8',
    'A11',
    'A3'
  ]

  df['labels'] = np.select(conditions, choices)
  return df

def sanitize_df(df):
  if 'median_time' not in df:
    df['median_time'] = np.nan
  if 'time_siqr' not in df:
    df['time_siqr'] = np.nan
  return df

def table1():
  INPUTS = ['base_data.json', 'type_data.json', 'effects_data.json', 'both_data.json']
  dfs = map(flatten_json, INPUTS)
  dfs = map(sanitize_df, dfs)
  dfs = list(map(lambda df: df[['median_time', 'time_siqr']], dfs))
  dfs = list(map(lambda df: df.astype(np.float64), dfs))

  dfs[0] = dfs[0].rename(columns={'median_time': 'both_enabled', 'time_siqr': 'both_enabled_siqr'})
  dfs[1] = dfs[1].rename(columns={'median_time': 'type_disabled', 'time_siqr': 'type_disabled_siqr'})
  dfs[2] = dfs[2].rename(columns={'median_time': 'eff_disabled', 'time_siqr': 'eff_disabled_siqr'})
  dfs[3] = dfs[3].rename(columns={'median_time': 'both_disabled', 'time_siqr': 'both_disabled_siqr'})
  joined = dfs[0].join(dfs[1]).join(dfs[2]).join(dfs[3]).reset_index()  
  join = attach_labels(joined)
  final = joined.set_index('index').join(bench_attrs)
  final = final[['labels', 'specs', 'components', 'both_enabled', 'both_enabled_siqr', 'eff_disabled', 'type_disabled', 'both_disabled', 'size', 'branches']]
  final = final.rename(columns={
    'labels': 'ID',
    'specs': 'Specs',
    'components': 'Library Methods',
    'both_enabled': 'Time Median',
    'both_enabled_siqr': 'Time SIQR',
    'eff_disabled': 'Types Only',
    'type_disabled': 'Eff Only',
    'both_disabled': 'Neither',
    'size': 'Method Size',
    'branches': 'Branches'})
  final.to_csv('table1.csv')

def fig8():
  INPUTS = ['base_data.json', 'class_perf.json', 'min_perf.json']
  dfs = map(flatten_json, INPUTS)
  dfs = map(sanitize_df, dfs)
  dfs = list(map(lambda df: df[['median_time', 'time_siqr']], dfs))
  dfs = list(map(lambda df: df.astype(np.float64), dfs))

  dfs[0] = dfs[0].rename(columns={'median_time': 'precise_median_time', 'time_siqr': 'precise_time_siqr'})
  dfs[1] = dfs[1].rename(columns={'median_time': 'class_median_time', 'time_siqr': 'class_time_siqr'})
  dfs[2] = dfs[2].rename(columns={'median_time': 'imprecise_median_time', 'time_siqr': 'imprecise_time_siqr'})

  joined = dfs[0].join(dfs[1]).join(dfs[2]).reset_index()
  joined['precise_median_time'].fillna(300, inplace=True)
  joined['class_median_time'].fillna(300, inplace=True)
  joined['imprecise_median_time'].fillna(300, inplace=True)
  joined['precise_time_siqr'].fillna(0, inplace=True)
  joined['class_time_siqr'].fillna(0, inplace=True)
  joined['imprecise_time_siqr'].fillna(0, inplace=True)
  joined = joined.sort_values(by=['imprecise_median_time', 'class_median_time', 'precise_median_time']).reset_index(drop=True)
  joined = attach_labels(joined)

  precise_median_time = joined['precise_median_time'].values
  class_median_time = joined['class_median_time'].values
  imprecise_median_time = joined['imprecise_median_time'].values
  joined['x'] = x

  only_synth = joined[joined['index'].str.contains('Synthetic')]
  real_bench = joined[~joined['index'].str.contains('Synthetic')]

  err_synth_x = np.concatenate((only_synth['x'].values, only_synth['x'].values, only_synth['x'].values))
  err_synth_y = np.concatenate((only_synth['precise_median_time'].values, only_synth['class_median_time'].values, only_synth['imprecise_median_time'].values))
  err_synth_err = np.concatenate((only_synth['precise_time_siqr'].values, only_synth['class_time_siqr'].values, only_synth['imprecise_time_siqr'].values))

  err_real_x = np.concatenate((real_bench['x'].values, real_bench['x'].values, real_bench['x'].values))
  err_real_y = np.concatenate((real_bench['precise_median_time'].values, real_bench['class_median_time'].values, real_bench['imprecise_median_time'].values))
  err_real_err = np.concatenate((real_bench['precise_time_siqr'].values, real_bench['class_time_siqr'].values, real_bench['imprecise_time_siqr'].values))

  quanta = 0.15
  ylim  = [290, 300]
  ylim2 = [0, 90]
  ylimratio = (ylim[1]-ylim[0])/(ylim2[1]-ylim2[0]+ylim[1]-ylim[0])
  ylim2ratio = (ylim2[1]-ylim2[0])/(ylim2[1]-ylim2[0]+ylim[1]-ylim[0])
  gs = gridspec.GridSpec(2, 1, height_ratios=[ylimratio, ylim2ratio])
  fig = plt.figure()
  fig.set_size_inches(8,4)
  ax = fig.add_subplot(gs[0])
  ax2 = fig.add_subplot(gs[1])

  ax.bar(x - (2 * quanta), precise_median_time, 2 * quanta, label='Precise Effects')
  ax.bar(x, class_median_time, 2 * quanta, label='Class Effects')
  ax.bar(x + (2 * quanta), imprecise_median_time, 2 * quanta, label='Purity Effects')

  ax2.bar(x - (2 * quanta), precise_median_time, 2 * quanta, label='Precise Effects')
  ax2.bar(x, class_median_time, 2 * quanta, label='Class Effects')
  ax2.bar(x + (2 * quanta), imprecise_median_time, 2 * quanta, label='Purity Effects')

  ax.set_ylim(ylim[0], ylim[1])
  ax2.set_ylim(ylim2[0], ylim2[1])
  # hide the spines between ax and ax2
  ax.spines['bottom'].set_visible(False)
  ax2.spines['top'].set_visible(False)
  ax.xaxis.tick_top()
  ax.tick_params(labeltop=False)  # don't put tick labels at the top
  ax2.xaxis.tick_bottom()
  plt.subplots_adjust(hspace=0.005)

  gs.tight_layout(fig)

  d = .005  # how big to make the diagonal lines in axes coordinates
  # arguments to pass to plot, just so we don't keep repeating them
  kwargs = dict(transform=ax.transAxes, color='k', clip_on=False)
  ax.plot((-d, +d), (-d, +d), **kwargs)        # top-left diagonal
  ax.plot((1 - d, 1 + d), (-d, +d), **kwargs)  # top-right diagonal

  kwargs.update(transform=ax2.transAxes)  # switch to the bottom axes
  ax2.plot((-d, +d), (1 - d, 1 + d), **kwargs)  # bottom-left diagonal
  ax2.plot((1 - d, 1 + d), (1 - d, 1 + d), **kwargs)  # bottom-right diagonal

  plt.xticks(x, joined['labels'].tolist())
  plt.legend(loc='best')
  ax.margins(x=0.01, y=0.01)
  ax2.margins(x=0.01, y=0.01)
  plt.xlabel('Benchmarks')
  plt.ylabel('Time (s)')
  plt.savefig('fig8.pdf', bbox_inches='tight')

def flat_line(series):
    max_lt_300 = max(filter(lambda x: x < 300, series))
    return np.where(series == 300, max_lt_300, series)

def synth(df, key):
    t = df.sort_values(by=[key])
    t['x'] = x
    return t[t.index.str.contains('Synthetic')]

def real(df, key):
    t = df.sort_values(by=[key])
    t['x'] = x
    return t[~t.index.str.contains('Synthetic')]

def fig7():
  INPUTS = ['base_data.json', 'type_data.json', 'effects_data.json', 'both_data.json']
  dfs = map(flatten_json, INPUTS)
  dfs = map(sanitize_df, dfs)
  dfs = list(map(lambda df: df[['median_time']], dfs))
  dfs = list(map(lambda df: df.astype(np.float64), dfs))

  dfs[0] = dfs[0].rename(columns={'median_time': 'both_enabled'})
  dfs[1] = dfs[1].rename(columns={'median_time': 'type_disabled'})
  dfs[2] = dfs[2].rename(columns={'median_time': 'eff_disabled'})
  dfs[3] = dfs[3].rename(columns={'median_time': 'both_disabled'})
  joined = dfs[0].join(dfs[1]).join(dfs[2]).join(dfs[3])

  both_enabled_y = np.sort(joined['both_enabled'])
  type_disabled_y = np.sort(joined['type_disabled'])
  eff_disabled_y = np.sort(joined['eff_disabled'])
  both_disabled_y = np.sort(joined['both_disabled'])

  both_enabled_y = both_enabled_y[~np.isnan(both_enabled_y)]
  type_disabled_y = type_disabled_y[~np.isnan(type_disabled_y)]
  eff_disabled_y = eff_disabled_y[~np.isnan(eff_disabled_y)]
  both_disabled_y = both_disabled_y[~np.isnan(both_disabled_y)]

  marker_synth_x = np.concatenate((synth(joined, 'both_enabled')['x'].values,
                                  synth(joined, 'type_disabled')['x'].values,
                                  synth(joined, 'eff_disabled')['x'].values,
                                  synth(joined, 'both_disabled')['x'].values))
  marker_synth_y = np.concatenate((synth(joined, 'both_enabled')['both_enabled'].values,
                                  synth(joined, 'type_disabled')['type_disabled'].values,
                                  synth(joined, 'eff_disabled')['eff_disabled'].values,
                                  synth(joined, 'both_disabled')['both_disabled'].values))

  marker_real_x = np.concatenate((real(joined, 'both_enabled')['x'].values,
                                  real(joined, 'type_disabled')['x'].values,
                                  real(joined, 'eff_disabled')['x'].values,
                                  real(joined, 'both_disabled')['x'].values))
  marker_real_y = np.concatenate((real(joined, 'both_enabled')['both_enabled'].values,
                                  real(joined, 'type_disabled')['type_disabled'].values,
                                  real(joined, 'eff_disabled')['eff_disabled'].values,
                                  real(joined, 'both_disabled')['both_disabled'].values))

  fig, ax = plt.subplots(1, 1)
  fig.set_size_inches(8,4.5)
  ax.plot(both_enabled_y, np.arange(0, len(both_enabled_y)), label='TE Enabled')
  ax.plot(type_disabled_y, np.arange(0, len(type_disabled_y)), label='E Only')
  ax.plot(eff_disabled_y, np.arange(0, len(eff_disabled_y)), label='T Only')
  ax.plot(both_disabled_y, np.arange(0, len(both_disabled_y)), label='TE Disabled')
  ax.scatter(marker_synth_y, marker_synth_x, label='Synthetic', marker='o')
  ax.scatter(marker_real_y, marker_real_x, label='Apps', marker='X')
  ax.axvline(max(both_enabled_y), linestyle='--', color='black')

  ax.set_ylim(0, 18)
  ax.set_xlim(0, 300)
  plt.yticks(np.arange(0, 19, 3))
  plt.grid()
  plt.legend(loc='best')
  plt.margins(x=0.01, y=0.01)
  plt.ylabel('# of benchmarks')
  plt.xlabel('Time (s)')
  plt.autoscale()
  plt.savefig('fig7.pdf', bbox_inches='tight')

if __name__ == '__main__':
  print("Generating Table 1 in table1.csv")
  table1()
  print("Generating Figure 7 in fig7.pdf")
  fig7()
  print("Generating Figure 8 in fig8.pdf")
  fig8()
