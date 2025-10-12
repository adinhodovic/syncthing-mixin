local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local annotation = g.dashboard.annotation;

local variable = dashboard.variable;
local datasource = variable.datasource;
local query = variable.query;

{
  filters(config):: {
    local this = self,
    cluster: '%(clusterLabel)s="$cluster"' % config,
    job: 'job=~"$job"',
    folder: 'folder=~"$folder"',
    device: 'device=~"$device"',
    fileSystem: 'root=~"$file_system"',

    base: |||
      %(cluster)s,
      %(job)s
    ||| % this,

    default: |||
      %(cluster)s,
      %(job)s
    ||| % this,

    withFolder: |||
      %(default)s,
      %(folder)s
    ||| % this,

    withDevice: |||
      %(default)s,
      %(device)s
    ||| % this,

    withFileSystem: |||
      %(default)s,
      %(fileSystem)s
    ||| % this,
  },

  variables(config):: {
    local this = self,

    local defaultFilters = $.filters(config),

    datasource:
      datasource.new(
        'datasource',
        'prometheus',
      ) +
      datasource.generalOptions.withLabel('Data source') +
      {
        current: {
          selected: true,
          text: config.datasourceName,
          value: config.datasourceName,
        },
      },

    cluster:
      query.new(
        config.clusterLabel,
        'label_values(syncthing_events_total{}, cluster)',
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Cluster') +
      query.refresh.onLoad() +
      query.refresh.onTime() +
      (
        if config.showMultiCluster
        then query.generalOptions.showOnDashboard.withLabelAndValue()
        else query.generalOptions.showOnDashboard.withNothing()
      ),

    job:
      query.new(
        'job',
        'label_values(syncthing_events_total{%(cluster)s}, job)' % defaultFilters
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Job') +
      query.selectionOptions.withMulti(false) +
      query.selectionOptions.withIncludeAll(false) +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    folder:
      query.new(
        'folder',
        'label_values(syncthing_model_folder_summary{%(cluster)s, %(job)s}, folder)' % defaultFilters
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Folder') +
      query.selectionOptions.withMulti(true) +
      query.selectionOptions.withIncludeAll(true) +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    device:
      query.new(
        'device',
        'label_values(syncthing_protocol_sent_bytes_total{%(cluster)s, %(job)s}, device)' % defaultFilters
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Device') +
      query.selectionOptions.withMulti(true) +
      query.selectionOptions.withIncludeAll(true) +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    fileSystem:
      query.new(
        'file_system',
        'label_values(syncthing_fs_operations_total{%(cluster)s, %(job)s}, root)' % defaultFilters
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('File System') +
      query.selectionOptions.withMulti(true) +
      query.selectionOptions.withIncludeAll(true) +
      query.refresh.onLoad() +
      query.refresh.onTime(),
  },

  annotations(config, filters)::
    local customAnnotation =
      annotation.withName(config.annotation.name) +
      annotation.withIconColor(config.annotation.iconColor) +
      annotation.withEnable(true) +
      annotation.withHide(false) +
      annotation.datasource.withUid(config.annotation.datasource) +
      annotation.target.withType(config.annotation.type) +
      (
        if config.annotation.type == 'tags' then
          annotation.target.withMatchAny(true) +
          if std.length(config.annotation.tags) > 0 then
            annotation.target.withTags(config.annotation.tags)
          else {}
        else {}
      );

    std.prune([
      if config.annotation.enabled then customAnnotation,
    ]),

  dashboardLinks(config):: [
    dashboard.link.dashboards.new('Django', config.tags) +
    dashboard.link.link.options.withTargetBlank(true) +
    dashboard.link.link.options.withAsDropdown(true) +
    dashboard.link.link.options.withIncludeVars(true) +
    dashboard.link.link.options.withKeepTime(true),
  ],
}
