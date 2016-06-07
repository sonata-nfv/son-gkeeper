from sqlalchemy import types
from sqlalchemy.dialects.mysql.base import MSBinary
import uuid_type


class UUID(types.TypeDecorator):
    impl = MSBinary
    def __init__(self):
        self.impl.length = 16
        types.TypeDecorator.__init__(self, length=self.impl.length)

    def process_bind_param(self,value,dialect=None):
        if value and isinstance(value, uuid_type.UUID):
            return value.bytes
        elif value and not isinstance(value, uuid_type.UUID):
            raise ValueError,'value %s is not a valid uuid.UUID' % value
        else:
            return None

    def process_result_value(self, value, dialect=None):
        if value:
            return uuid_type.UUID(bytes=value)
        else:
            return None

    def is_mutable(self):
        return False