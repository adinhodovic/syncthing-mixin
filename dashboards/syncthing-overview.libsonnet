local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local mixinUtils = import 'mixin-utils/utils.libsonnet';
local util = import 'util.libsonnet';

local dashboard = g.dashboard;
local row = g.panel.row;
local grid = g.util.grid;

{
  local dashboardName = 'syncthing-overview',
  grafanaDashboards+:: {
    ['%s.json' % dashboardName]:

      local defaultVariables = util.variables($._config);

      local variables = [
        defaultVariables.datasource,
        defaultVariables.cluster,
        defaultVariables.job,
        defaultVariables.folder,
        defaultVariables.device,
        defaultVariables.fileSystem,
      ];

      local defaultFilters = util.filters($._config);
      local queries = {

        folderCount: |||
          count(
            syncthing_model_folder_state{
              %(default)s
            }
          ) by (folder)
        ||| % defaultFilters,

        deviceCount: |||
          sum(
            count(
              syncthing_protocol_recv_bytes_total{
                %(default)s
              }
            ) by (device)
          )
        ||| % defaultFilters,

        eventsRate: |||
          sum(
            increase(
              syncthing_events_total{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        operationsRate: |||
          sum(
            increase(
              syncthing_fs_operations_total{
                %(default)s
              }[$__rate_interval]
            )
          )
        ||| % defaultFilters,

        folderStateSynced: |||
          count(
            syncthing_model_folder_state{
              %(default)s
            } == 0
          )
        ||| % defaultFilters,
        folderStateUnsynced: std.strReplace(queries.folderStateSynced, '== 0', '> 0'),

        folderBytesTotal: |||
          sum(
            syncthing_model_folder_summary{
              %(default)s,
              scope="global",
              type="bytes"
            }
          )
        ||| % defaultFilters,
        folderDirectoriesTotal: std.strReplace(queries.folderBytesTotal, 'bytes', 'directories'),
        folderFilesTotal: std.strReplace(queries.folderBytesTotal, 'bytes', 'files'),
        folderDeletedTotal: std.strReplace(queries.folderBytesTotal, 'bytes', 'deleted'),

        eventsByEvent: |||
          sum(
            increase(
              syncthing_events_total{
                %(default)s
              }[1h]
            )
          ) by (event)
          > 0
        ||| % defaultFilters,

        eventsCreatedRate: |||
          sum(
            increase(
              syncthing_events_total{
                %(default)s,
                state="created"
              }[$__rate_interval]
            )
          ) by (event)
        ||| % defaultFilters,
        eventsDeliveredRate: std.strReplace(queries.eventsCreatedRate, 'state="created"', 'state="delivered"'),
        eventsDroppedRate: std.strReplace(queries.eventsCreatedRate, 'state="created"', 'state="dropped"'),

        // Folder
        folderState: |||
          sum(
            syncthing_model_folder_state{
              %(withFolder)s
            }
          ) by (folder, state)
        ||| % defaultFilters,

        folderBytesNeededByFolderTotal: |||
          sum(
            syncthing_model_folder_summary{
              %(withFolder)s,
              scope="need",
              type="bytes"
            }
          ) by (folder)
        ||| % defaultFilters,

        folderBytesByFolderTotal: |||
          sum(
            syncthing_model_folder_summary{
              %(withFolder)s,
              scope="global",
              type="bytes"
            }
          ) by (folder)
        ||| % defaultFilters,
        folderDirectoriesByFolderTotal: std.strReplace(queries.folderBytesTotal, 'bytes', 'directories'),
        folderFilesByFolderTotal: std.strReplace(queries.folderBytesTotal, 'bytes', 'files'),
        folderDeletedByFolderTotal: std.strReplace(queries.folderBytesTotal, 'bytes', 'deleted'),

        folderPullsRate: |||
          sum(
            increase(
              syncthing_model_folder_pulls_total{
                %(withFolder)s
              }[$__rate_interval]
            )
          ) by (folder)
        ||| % defaultFilters,

        folderScansRate: |||
          sum(
            increase(
              syncthing_model_folder_scans_total{
                %(withFolder)s
              }[$__rate_interval]
            )
          ) by (folder)
        ||| % defaultFilters,

        scannerHashedBytesRate: |||
          sum(
            rate(
              syncthing_scanner_hashed_bytes_total{
                %(withFolder)s
              }[$__rate_interval]
            )
          ) by (folder)
        ||| % defaultFilters,

        scannerScansItemsRate: |||
          sum(
            increase(
              syncthing_scanner_scanned_items_total{
                %(withFolder)s
              }[$__rate_interval]
            )
          ) by (folder)
        ||| % defaultFilters,

        // Filesystem
        fsOperationsRate: |||
          sum(
            increase(
              syncthing_fs_operations_total{
                %(withFileSystem)s
              }[$__rate_interval]
            )
          ) by (root, operation)
          > 0
        ||| % defaultFilters,

        fsOperationsBytesRate: |||
          sum(
            increase(
              syncthing_fs_operation_bytes_total{
                %(withFileSystem)s
              }[$__rate_interval]
            )
          ) by (root, operation)
          > 0
        ||| % defaultFilters,

        fsOperationsSecondsRate: |||
          sum(
            increase(
              syncthing_fs_operation_seconds_total{
                %(withFileSystem)s
              }[$__rate_interval]
            )
          ) by (root, operation)
          > 0
        ||| % defaultFilters,

        // Network
        networkReceivedBytesRate: |||
          sum(
            label_replace(
              increase(
                syncthing_protocol_recv_bytes_total{
                  %(withDevice)s
                }[$__rate_interval]
              ),
              "device", "$1", "device", "^(.{1,15}).*"
            )
          ) by (device)
        ||| % defaultFilters,
        networkSentBytesRate: std.strReplace(queries.networkReceivedBytesRate, 'recv', 'sent'),

        networkReceivedMessagesRate: |||
          sum(
            label_replace(
              increase(
                syncthing_protocol_recv_messages_total{
                  %(withDevice)s
                }[$__rate_interval]
              ),
              "device", "$1", "device", "^(.{1,15}).*"
            )
          ) by (device)
        ||| % defaultFilters,
        networkSentMessagesRate: std.strReplace(queries.networkReceivedMessagesRate, 'recv', 'sent'),
      };

      local panels = {

        folderCountStat:
          mixinUtils.dashboards.statPanel(
            'Folders',
            'short',
            queries.folderCount,
            'The total number of folders being synchronized by Syncthing.',
          ),

        deviceCountStat:
          mixinUtils.dashboards.statPanel(
            'Devices',
            'short',
            queries.deviceCount,
            'The total number of devices connected to Syncthing.',
          ),

        eventsRateStat:
          mixinUtils.dashboards.statPanel(
            'Events',
            'short',
            queries.eventsRate,
            'The rate of events occurring in Syncthing, measured in events per second.',
          ),

        operationsRateStat:
          mixinUtils.dashboards.statPanel(
            'Filesystem Operations',
            'short',
            queries.operationsRate,
            'The rate of filesystem operations performed by Syncthing, measured in operations per second.',
          ),

        eventsByEventPieChart:
          mixinUtils.dashboards.pieChartPanel(
            'Events by Type [1h]',
            'short',
            queries.eventsByEvent,
            '{{ event }}',
            'The distribution of events in Syncthing, categorized by event type over the last hour.',
          ),

        folderByStatePieChart:
          mixinUtils.dashboards.pieChartPanel(
            'Folders by State',
            'bool',
            [
              {
                expr: queries.folderStateSynced,
                legend: 'Synced',
              },
              {
                expr: queries.folderStateUnsynced,
                legend: 'Unsynced',
              },
            ],
            'The distribution of folders being synchronized by Syncthing, categorized by state type.',
          ),

        folderBytesTotalTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Folder Total Bytes',
            'bytes',
            queries.folderBytesTotal,
            '{{ folder }}',
            description='The total number of bytes in each folder being synchronized by Syncthing.',
            stack='normal',
          ),

        folderDirectoriesTotalTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Folder Total Directories',
            'short',
            queries.folderDirectoriesTotal,
            '{{ folder }}',
            description='The total number of directories in each folder being synchronized by Syncthing.',
            stack='normal',
          ),

        folderFilesTotalTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Folder Total Files',
            'short',
            queries.folderFilesTotal,
            '{{ folder }}',
            description='The total number of files in each folder being synchronized by Syncthing.',
            stack='normal',
          ),

        folderDeletedTotalTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Folder Total Deleted Items',
            'short',
            queries.folderDeletedTotal,
            '{{ folder }}',
            description='The total number of deleted items in each folder being synchronized by Syncthing.',
            stack='normal',
          ),

        eventsCreatedRateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Events Created Rate',
            'short',
            queries.eventsCreatedRate,
            '{{ event }}',
            description='The rate of created events in Syncthing, categorized by event type and measured in events per second.',
            stack='normal',
          ),

        eventsDeliveredRateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Events Delivered Rate',
            'short',
            queries.eventsDeliveredRate,
            '{{ event }}',
            description='The rate of delivered events in Syncthing, categorized by event type and measured in events per second.',
            stack='normal',
          ),

        eventsDroppedRateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Events Dropped Rate',
            'short',
            queries.eventsDroppedRate,
            '{{ event }}',
            description='The rate of Dropped events in Syncthing, categorized by event type and measured in events per second.',
            stack='normal',
          ),

        // Folder
        folderStateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Folder State',
            'short',
            queries.folderState,
            '{{ folder }}',
            description='The current state of each folder being synchronized by Syncthing, categorized by state type.',
            stack='normal',
          ),

        folderBytesNeededByFolderTotalTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Needed Bytes by Folder',
            'bytes',
            queries.folderBytesNeededByFolderTotal,
            '{{ folder }}',
            description='The number of bytes needed to be synchronized in each folder by Syncthing, categorized by folder.',
            stack='normal',
          ),

        folderBytesByFolderTotalTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Total Bytes by Folder',
            'bytes',
            queries.folderBytesByFolderTotal,
            '{{ folder }}',
            description='The total number of bytes in each folder being synchronized by Syncthing, categorized by folder.',
            stack='normal',
          ),

        folderDirectoriesByFolderTotalTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Total Directories by Folder',
            'short',
            queries.folderDirectoriesByFolderTotal,
            '{{ folder }}',
            description='The total number of directories in each folder being synchronized by Syncthing, categorized by folder.',
            stack='normal',
          ),

        folderFilesByFolderTotalTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Total Files by Folder',
            'short',
            queries.folderFilesByFolderTotal,
            '{{ folder }}',
            description='The total number of files in each folder being synchronized by Syncthing, categorized by folder.',
            stack='normal',
          ),

        folderDeletedByFolderTotalTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Total Deleted Items by Folder',
            'short',
            queries.folderDeletedByFolderTotal,
            '{{ folder }}',
            description='The total number of deleted items in each folder being synchronized by Syncthing, categorized by folder.',
            stack='normal',
          ),

        folderPullsRateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Folder Pulls Rate',
            'short',
            queries.folderPullsRate,
            '{{ folder }}',
            description='The rate of pull operations for each folder, measured in pulls per second.',
            stack='normal',
          ),

        folderScansRateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Folder Scans Rate',
            'short',
            queries.folderScansRate,
            '{{ folder }}',
            description='The rate of scan operations for each folder, measured in scans per second.',
            stack='normal',
          ),

        scannerHashedBytesRateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Scanner Hashed Bytes Rate',
            'bytes',
            queries.scannerHashedBytesRate,
            '{{ folder }}',
            description='The rate of bytes hashed during scans by Syncthing, measured in bytes per second.',
            stack='normal',
          ),

        scannerScansItemsRateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Scanner Scanned Items Rate',
            'short',
            queries.scannerScansItemsRate,
            '{{ folder }}',
            description='The rate of items scanned by Syncthing, measured in items per second.',
            stack='normal',
          ),

        // Filesystem
        fsOperationsRateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Filesystem Operations Rate',
            'short',
            queries.fsOperationsRate,
            '{{ root }} - {{ operation }}',
            description='The rate of filesystem operations performed by Syncthing, categorized by operation type and root directory, measured in operations per second.',
            stack='normal',
          ),

        fsOperationsBytesRateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Filesystem Operations Bytes Rate',
            'bytes',
            queries.fsOperationsBytesRate,
            '{{ root }} - {{ operation }}',
            description='The rate of bytes processed during filesystem operations by Syncthing, categorized by operation type and root directory, measured in bytes per second.',
            stack='normal',
          ),

        fsOperationsSecondsRateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Filesystem Operations Seconds Rate',
            's',
            queries.fsOperationsSecondsRate,
            '{{ root }} - {{ operation }}',
            description='The rate of time spent on filesystem operations by Syncthing, categorized by operation type and root directory, measured in seconds per second.',
            stack='normal',
          ),

        // Network
        networkReceivedBytesRateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Network Received Bytes Rate',
            'bytes',
            queries.networkReceivedBytesRate,
            '{{ device }}',
            description='The rate of bytes received over the network by Syncthing, measured in bytes per second.',
            stack='normal',
          ),

        networkSentBytesRateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Network Sent Bytes Rate',
            'bytes',
            queries.networkSentBytesRate,
            '{{ device }}',
            description='The rate of bytes sent over the network by Syncthing, measured in bytes per second.',
            stack='normal',
          ),

        networkReceivedMessagesRateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Network Received Messages Rate',
            'short',
            queries.networkReceivedMessagesRate,
            '{{ device }}',
            description='The rate of messages received over the network by Syncthing, measured in messages per second.',
            stack='normal',
          ),

        networkSentMessagesRateTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Network Sent Messages Rate',
            'short',
            queries.networkSentMessagesRate,
            '{{ device }}',
            description='The rate of messages sent over the network by Syncthing, measured in messages per second.',
            stack='normal',
          ),
      };

      local rows =
        [
          row.new('Summary') +
          row.gridPos.withX(0) +
          row.gridPos.withY(0) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.folderCountStat,
            panels.deviceCountStat,
            panels.eventsRateStat,
            panels.operationsRateStat,
            panels.folderByStatePieChart,
            panels.eventsByEventPieChart,
          ],
          panelWidth=4,
          panelHeight=4,
          startY=1,
        ) +
        grid.wrapPanels(
          [
            panels.folderBytesTotalTimeSeries,
            panels.folderDirectoriesTotalTimeSeries,
            panels.folderFilesTotalTimeSeries,
            panels.folderDeletedTotalTimeSeries,
          ],
          panelWidth=12,
          panelHeight=4,
          startY=5,
        ) +
        grid.wrapPanels(
          [
            panels.eventsCreatedRateTimeSeries,
            panels.eventsDeliveredRateTimeSeries,
            panels.eventsDroppedRateTimeSeries,
          ],
          panelWidth=8,
          panelHeight=6,
          startY=14,
        ) +
        [
          row.new('Folders') +
          row.gridPos.withX(0) +
          row.gridPos.withY(20) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.folderStateTimeSeries,
            panels.folderBytesNeededByFolderTotalTimeSeries,
            panels.folderBytesByFolderTotalTimeSeries,
            panels.folderDirectoriesByFolderTotalTimeSeries,
            panels.folderFilesByFolderTotalTimeSeries,
            panels.folderDeletedByFolderTotalTimeSeries,
            panels.folderPullsRateTimeSeries,
            panels.folderScansRateTimeSeries,
            panels.scannerHashedBytesRateTimeSeries,
            panels.scannerScansItemsRateTimeSeries,
          ],
          panelWidth=12,
          panelHeight=6,
          startY=22,
        ) +
        [
          row.new('Filesystem') +
          row.gridPos.withX(0) +
          row.gridPos.withY(51) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.fsOperationsRateTimeSeries,
          ],
          panelWidth=24,
          panelHeight=6,
          startY=52,
        ) +
        grid.wrapPanels(
          [
            panels.fsOperationsBytesRateTimeSeries,
            panels.fsOperationsSecondsRateTimeSeries,
          ],
          panelWidth=12,
          panelHeight=6,
          startY=58,
        ) +
        [
          row.new('Network') +
          row.gridPos.withX(0) +
          row.gridPos.withY(64) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
        ] +
        grid.wrapPanels(
          [
            panels.networkSentBytesRateTimeSeries,
            panels.networkSentMessagesRateTimeSeries,
            panels.networkReceivedBytesRateTimeSeries,
            panels.networkReceivedMessagesRateTimeSeries,
          ],
          panelWidth=12,
          panelHeight=6,
          startY=65,
        );

      mixinUtils.dashboards.bypassDashboardValidation +
      dashboard.new(
        'Syncthing / Overview',
      ) +
      dashboard.withDescription('A dashboard that monitors Syncthing. %s' % mixinUtils.dashboards.dashboardDescriptionLink('syncthing-mixin', 'https://github.com/adinhodovic/syncthing-mixin')) +
      dashboard.withUid($._config.dashboardIds[dashboardName]) +
      dashboard.withTags($._config.tags) +
      dashboard.withTimezone('utc') +
      dashboard.withEditable(false) +
      dashboard.time.withFrom('now-6h') +
      dashboard.time.withTo('now') +
      dashboard.withVariables(variables) +
      dashboard.withLinks(
        mixinUtils.dashboards.dashboardLinks($._config)
      ) +
      dashboard.withPanels(
        rows
      ) +
      dashboard.withAnnotations(
        mixinUtils.dashboards.annotations($._config, defaultFilters)
      ),
  },
}
