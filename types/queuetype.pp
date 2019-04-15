# Rsyslog Queue Types
#
type Rsyslog::QueueType = Enum[
  'FixedArray',
  'LinkedList',
  'Direct',
  'Disk'
]
