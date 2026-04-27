{
  local clusterVariableQueryString = if $._config.showMultiCluster then '&var-%(clusterLabel)s={{ $labels.%(clusterLabel)s }}' % $._config else '',
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'syncthing',
        rules: if $._config.alerts.enabled then std.prune([
          if $._config.alerts.eventsDropped.enabled then {
            alert: 'SyncthingEventsDropped',
            expr: |||
              sum(
                increase(
                  syncthing_events_total{
                    %(syncthingSelector)s,
                    state="dropped"
                  }[5m]
                )
              ) by (%(clusterLabel)s, job, event)
              > 0
            ||| % $._config,
            labels: {
              severity: $._config.alerts.eventsDropped.severity,
            },
            'for': $._config.alerts.eventsDropped.interval,
            annotations: {
              summary: 'Syncthing events dropped.',
              description: 'The job {{ $labels.job }} has dropped events of type {{ $labels.event }} in the last minute.',
              dashboard_url: $._config.dashboardUrls['syncthing-overview'] + '?var-job={{ $labels.job }}' + clusterVariableQueryString,
            },
          },
          if $._config.alerts.folderOutOfSync.enabled then {
            alert: 'SyncthingFolderOutOfSync',
            expr: |||
              sum(
                syncthing_model_folder_summary{
                  %(syncthingSelector)s,
                  scope="need",
                  type="bytes"
                }
              ) by (%(clusterLabel)s, job, folder)
              > 0
            ||| % $._config,
            labels: {
              severity: $._config.alerts.folderOutOfSync.severity,
            },
            'for': $._config.alerts.folderOutOfSync.interval,
            annotations: {
              summary: 'Syncthing folder out of sync.',
              description: 'The folder {{ $labels.folder }} in job {{ $labels.job }} is out of sync for more than %(interval)s.' % $._config.alerts.folderOutOfSync,
              dashboard_url: $._config.dashboardUrls['syncthing-overview'] + '?var-job={{ $labels.job }}&var-folder={{ $labels.folder }}' + clusterVariableQueryString,
            },
          },
        ]) else [],
      },
    ],
  },
}
