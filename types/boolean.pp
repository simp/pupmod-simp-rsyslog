# Representation of boolean values that are translated to 'on' and 'off'
# in Rsyslog configuration
#
type Rsyslog::Boolean = Variant[Enum['on','off'],Boolean]
